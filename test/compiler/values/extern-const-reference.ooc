
// Test for https://github.com/fasterthanlime/rock/pull/897

use sam-assert

include ./constnum

SIG1: extern const Int

foo: func <T> (t: T) -> String {
    match t {
        case i: Int =>
            "matched!" 
        case =>
            "error"
    }
}

describe("should know that extern const are not referencable", ||
   expect("matched!", foo(SIG1))
)
