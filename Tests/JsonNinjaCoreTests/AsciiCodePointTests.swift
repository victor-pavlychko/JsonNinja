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

#if DEBUG

import XCTest
@testable import JsonNinja

final class AsciiCodePointTests: XCTestCase {
    func testAsciiCodePoints() {
        XCTAssertEqual(Character(UnicodeScalar(UInt8.backspace)), "\u{08}")
        XCTAssertEqual(Character(UnicodeScalar(UInt8.horizontalTab)), "\t")
        XCTAssertEqual(Character(UnicodeScalar(UInt8.lineFeed)), "\n")
        XCTAssertEqual(Character(UnicodeScalar(UInt8.formFeed)), "\u{0c}")
        XCTAssertEqual(Character(UnicodeScalar(UInt8.carrigeReturn)), "\r")

        XCTAssertEqual(Character(UnicodeScalar(UInt8.space)), " ")
        XCTAssertEqual(Character(UnicodeScalar(UInt8.doubleQuotes)), "\"")
        XCTAssertEqual(Character(UnicodeScalar(UInt8.plus)), "+")
        XCTAssertEqual(Character(UnicodeScalar(UInt8.comma)), ",")
        XCTAssertEqual(Character(UnicodeScalar(UInt8.hyphen)), "-")
        XCTAssertEqual(Character(UnicodeScalar(UInt8.period)), ".")
        XCTAssertEqual(Character(UnicodeScalar(UInt8.slash)), "/")

        XCTAssertEqual(Character(UnicodeScalar(UInt8.digitZero)), "0")
        XCTAssertEqual(Character(UnicodeScalar(UInt8.digitOne)), "1")
        XCTAssertEqual(Character(UnicodeScalar(UInt8.digitNine)), "9")

        XCTAssertEqual(Character(UnicodeScalar(UInt8.colon)), ":")

        XCTAssertEqual(Character(UnicodeScalar(UInt8.uppercaseA)), "A")
        XCTAssertEqual(Character(UnicodeScalar(UInt8.uppercaseE)), "E")
        XCTAssertEqual(Character(UnicodeScalar(UInt8.uppercaseF)), "F")

        XCTAssertEqual(Character(UnicodeScalar(UInt8.openingBracket)), "[")
        XCTAssertEqual(Character(UnicodeScalar(UInt8.backslash)), "\\")
        XCTAssertEqual(Character(UnicodeScalar(UInt8.closingBracket)), "]")

        XCTAssertEqual(Character(UnicodeScalar(UInt8.lowercaseA)), "a")
        XCTAssertEqual(Character(UnicodeScalar(UInt8.lowercaseB)), "b")
        XCTAssertEqual(Character(UnicodeScalar(UInt8.lowercaseE)), "e")
        XCTAssertEqual(Character(UnicodeScalar(UInt8.lowercaseF)), "f")
        XCTAssertEqual(Character(UnicodeScalar(UInt8.lowercaseL)), "l")
        XCTAssertEqual(Character(UnicodeScalar(UInt8.lowercaseN)), "n")
        XCTAssertEqual(Character(UnicodeScalar(UInt8.lowercaseR)), "r")
        XCTAssertEqual(Character(UnicodeScalar(UInt8.lowercaseS)), "s")
        XCTAssertEqual(Character(UnicodeScalar(UInt8.lowercaseT)), "t")
        XCTAssertEqual(Character(UnicodeScalar(UInt8.lowercaseU)), "u")

        XCTAssertEqual(Character(UnicodeScalar(UInt8.openingBrace)), "{")
        XCTAssertEqual(Character(UnicodeScalar(UInt8.closingBrace)), "}")
    }
}

#endif
