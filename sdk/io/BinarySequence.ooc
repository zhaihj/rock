import io/[Reader, Writer]
import text/Buffer

Endianness: enum {
    little
    big
}

reverseBytes: func <T> (value: T) -> T {
    array := value& as Octet*
    size := T size
    reversed: T
    reversedArray := reversed& as Octet*
    for(i in 0..size) {
        reversedArray[size - i - 1] = array[i]
    }
    reversed
}

PackingError: class extends Exception {
    init: super func
}

BinarySequenceWriter: class {
    writer: Writer
    endianness := ENDIANNESS

    init: func (=writer) {
    }

    _pushByte: func (byte: Octet) {
        writer write(byte as Char) // TODO?
    }

    pushValue: func <T> (value: T) {
        size := T size
        if(endianness != ENDIANNESS) {
            // System is little, seq is big?
            // System is big, seq is little?
            // Reverse.
            value = reverseBytes(value)
        }
        array := value& as Octet*
        for(i in 0..size) {
            _pushByte(array[i])
        }
    }

    s8: func (value: Int8) { pushValue(value) }
    s16: func (value: Int16) { pushValue(value) }
    s32: func (value: Int32) { pushValue(value) }
    s64: func (value: Int64) { pushValue(value) }
    u8: func (value: UInt8) { pushValue(value) }
    u16: func (value: UInt16) { pushValue(value) }
    u32: func (value: UInt32) { pushValue(value) }
    u64: func (value: UInt64) { pushValue(value) }
    
    pad: func (bytes: SizeT) { for(_ in 0..bytes) s8(0) }

    /** push it, null-terminated. */
    cString: func (value: String) {
        for(chr in value) {
            u8(chr as UInt8)
        }
        s8(0)
    }

    pascalString: func (value: String, lengthBytes: SizeT) {
        length := value length()
        match (lengthBytes) { 
            case 1 => u8(length)
            case 2 => u16(length)
            case 3 => u32(length)
            case 4 => u64(length)
        }
        for(chr in value) {
            u8(chr as UInt8)
        }
    }
}

BinarySequenceReader: class {
    reader: Reader
    endianness := ENDIANNESS

    init: func (=reader) {
    }

    pullValue: func <T> (T: Class) -> T {
        size := T size
        value: T
        array := value& as Octet*
        // pull the bytes.
        for(i in 0..size) {
            array[i] = reader read()
        }
        if(endianness != ENDIANNESS) {
            // Seq is big, system is endian?
            // System is endian, seq is big?
            // Reverse.
            value = reverseBytes(value)
        }
        value
    }

    s8: func -> Int8 { pullValue(Int8) }
    s16: func -> Int16 { pullValue(Int16) }
    s32: func -> Int32 { pullValue(Int32) }
    s64: func -> Int64 { pullValue(Int64) }
    u8: func -> UInt8 { pullValue(UInt8) }
    u16: func -> UInt16 { pullValue(UInt16) }
    u32: func -> UInt32 { pullValue(UInt32) }
    u64: func -> UInt64 { pullValue(UInt64) }
    skip: func (bytes: UInt32) {
        for(_ in 0..bytes)
            reader read()
    }

    /** pull it, null-terminated */
    cString: func -> String {
        buffer := Buffer new()
        while(true) {
            value := u8()
            if(value == 0)
                break
            buffer append(value as Char)
        }
        buffer toString()
    }

    pascalString: func (lengthBytes: SizeT) -> String {
        length := match (lengthBytes) {
            case 1 => u8()
            case 2 => u16()
            case 3 => u32()
            case 4 => u64()
        }
        s := String new(length)
        for(i in 0..length) {
            s[i] = u8() as Char
        }
        s
    }
}

// calculate endianness
ENDIANNESS: static Endianness
_i := 0x10f as UInt16
// On big endian, this looks like: [ 0x01 | 0x0f ]
// On little endian, this looks like: [ 0x0f | 0x01 ]
ENDIANNESS := (_i& as UInt8*)[0] == 0x0f ? Endianness little : Endianness big
