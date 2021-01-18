// JsonNinja -- fast streaming JSON parser for Swift
//
// Copyright (c) 2021 Victor Pavlychko
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation

public enum JsonError: Error {
    case unexpectedSymbol
    case unexpectedEndOfStream
    case badEscapeSequence
    case badUnicodeEscapeSequence
    case unicodeError
}

extension JsonError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unexpectedSymbol:
            return "JSON Error: unexpected symbol"
        case .unexpectedEndOfStream:
            return "JSON Error: unexpected end of stream"
        case .badEscapeSequence:
            return "JSON Error: malformed escape sequence"
        case .badUnicodeEscapeSequence:
            return "JSON Error: malformed Unicode escape sequence"
        case .unicodeError:
            return "JSON Error: Unicode error"
        }
    }
}
