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
import XCTest
import JsonNinja

// Test suite ported from swift-corelibs-foundation
// https://github.com/apple/swift-corelibs-foundation/blob/main/Tests/Foundation/Tests/TestJSONSerialization.swift

final class JsonReaderTests: XCTestCase {
    func testEmptyObject() throws {
        let subject = "{}"
        let reader = try JsonReader(string: subject)
        var cursor = reader.startReading()
        XCTAssertEqual(try reader.peekValue(at: cursor), .object)
        XCTAssertEqual(try reader.nextObjectProperty(at: &cursor), false)
        XCTAssertTrue(reader.isEnd(cursor))
    }

    func testMultiStringObject() throws {
        let subject = "{ \"hello\": \"world\", \"swift\": \"rocks\" }"
        let reader = try JsonReader(string: subject)
        var cursor = reader.startReading()
        XCTAssertEqual(try reader.peekValue(at: cursor), .object)
        XCTAssertEqual(try reader.nextObjectProperty(at: &cursor), true)
        XCTAssertEqual(try reader.readObjectPropertyName(at: &cursor), "hello")
        XCTAssertEqual(try reader.readString(at: &cursor), "world")
        XCTAssertEqual(try reader.nextObjectProperty(at: &cursor), true)
        XCTAssertEqual(try reader.readObjectPropertyName(at: &cursor), "swift")
        XCTAssertEqual(try reader.readString(at: &cursor), "rocks")
        XCTAssertEqual(try reader.nextObjectProperty(at: &cursor), false)
        XCTAssertTrue(reader.isEnd(cursor))
    }

    func testStringWithSpacesAtStart() throws {
        let subject = "{\"title\" : \" hello world!!\" }"
        let reader = try JsonReader(string: subject)
        var cursor = reader.startReading()
        XCTAssertEqual(try reader.peekValue(at: cursor), .object)
        XCTAssertEqual(try reader.nextObjectProperty(at: &cursor), true)
        XCTAssertEqual(try reader.readObjectPropertyName(at: &cursor), "title")
        XCTAssertEqual(try reader.readString(at: &cursor), " hello world!!")
        XCTAssertEqual(try reader.nextObjectProperty(at: &cursor), false)
        XCTAssertTrue(reader.isEnd(cursor))
    }

    func testEmptyArray() throws {
        let subject = "[]"
        let reader = try JsonReader(string: subject)
        var cursor = reader.startReading()
        XCTAssertEqual(try reader.peekValue(at: cursor), .array)
        XCTAssertEqual(try reader.nextArrayElement(at: &cursor), false)
        XCTAssertTrue(reader.isEnd(cursor))
    }

    func testMultiStringArray() throws {
        let subject = "[\"hello\", \"swift⚡️\"]"
        let reader = try JsonReader(string: subject)
        var cursor = reader.startReading()
        XCTAssertEqual(try reader.peekValue(at: cursor), .array)
        XCTAssertEqual(try reader.nextArrayElement(at: &cursor), true)
        XCTAssertEqual(try reader.readString(at: &cursor), "hello")
        XCTAssertEqual(try reader.nextArrayElement(at: &cursor), true)
        XCTAssertEqual(try reader.readString(at: &cursor), "swift⚡️")
        XCTAssertEqual(try reader.nextArrayElement(at: &cursor), false)
        XCTAssertTrue(reader.isEnd(cursor))
    }

    func testUnicodeString() throws {
        /// Ģ has the same LSB as quotation mark " (U+0022) so test guarding against this case
        let subject = "[\"unicode\", \"Ģ\", \"😢\"]"
        let reader = try JsonReader(string: subject)
        var cursor = reader.startReading()
        XCTAssertEqual(try reader.peekValue(at: cursor), .array)
        XCTAssertEqual(try reader.nextArrayElement(at: &cursor), true)
        XCTAssertEqual(try reader.readString(at: &cursor), "unicode")
        XCTAssertEqual(try reader.nextArrayElement(at: &cursor), true)
        XCTAssertEqual(try reader.readString(at: &cursor), "Ģ")
        XCTAssertEqual(try reader.nextArrayElement(at: &cursor), true)
        XCTAssertEqual(try reader.readString(at: &cursor), "😢")
        XCTAssertEqual(try reader.nextArrayElement(at: &cursor), false)
        XCTAssertTrue(reader.isEnd(cursor))
    }

    func testValues() throws {
        let subject = "[true, false, \"hello\", null, {}, []]"
        let reader = try JsonReader(string: subject)
        var cursor = reader.startReading()
        XCTAssertEqual(try reader.peekValue(at: cursor), .array)
        XCTAssertEqual(try reader.nextArrayElement(at: &cursor), true)
        XCTAssertEqual(try reader.readValue(at: &cursor), true)
        XCTAssertEqual(try reader.nextArrayElement(at: &cursor), true)
        XCTAssertEqual(try reader.readValue(at: &cursor), false)
        XCTAssertEqual(try reader.nextArrayElement(at: &cursor), true)
        XCTAssertEqual(try reader.readValue(at: &cursor), "hello")
        XCTAssertEqual(try reader.nextArrayElement(at: &cursor), true)
        XCTAssertEqual(try reader.readValue(at: &cursor), nil)
        XCTAssertEqual(try reader.nextArrayElement(at: &cursor), true)
        XCTAssertEqual(try reader.peekValue(at: cursor), .object)
        XCTAssertEqual(try reader.nextObjectProperty(at: &cursor), false)
        XCTAssertEqual(try reader.nextArrayElement(at: &cursor), true)
        XCTAssertEqual(try reader.peekValue(at: cursor), .array)
        XCTAssertEqual(try reader.nextArrayElement(at: &cursor), false)
        XCTAssertEqual(try reader.nextArrayElement(at: &cursor), false)
        XCTAssertTrue(reader.isEnd(cursor))
    }

    func testNumbers() throws {
        let subject = "[1, -1, 1.3, -1.3, 1e3, 1E-3, 10, -12.34e56, 12.34e-56, 12.34e+6, 0.002, 0.0043e+4]"
        let reader = try JsonReader(string: subject)
        var cursor = reader.startReading()
        XCTAssertEqual(try reader.peekValue(at: cursor), .array)
        XCTAssertEqual(try reader.nextArrayElement(at: &cursor), true)
        XCTAssertEqual(try reader.readValue(at: &cursor), 1)
        XCTAssertEqual(try reader.nextArrayElement(at: &cursor), true)
        XCTAssertEqual(try reader.readValue(at: &cursor), -1)
        XCTAssertEqual(try reader.nextArrayElement(at: &cursor), true)
        XCTAssertEqual(try reader.readValue(at: &cursor), 1.3)
        XCTAssertEqual(try reader.nextArrayElement(at: &cursor), true)
        XCTAssertEqual(try reader.readValue(at: &cursor), -1.3)
        XCTAssertEqual(try reader.nextArrayElement(at: &cursor), true)
        XCTAssertEqual(try reader.readValue(at: &cursor), 1000)
        XCTAssertEqual(try reader.nextArrayElement(at: &cursor), true)
        XCTAssertEqual(try reader.readValue(at: &cursor), 0.001)
        XCTAssertEqual(try reader.nextArrayElement(at: &cursor), true)
        XCTAssertEqual(try reader.readValue(at: &cursor), 10)
        XCTAssertEqual(try reader.nextArrayElement(at: &cursor), true)
        XCTAssertEqual(try reader.readValue(at: &cursor), -12.34e56)
        XCTAssertEqual(try reader.nextArrayElement(at: &cursor), true)
        XCTAssertEqual(try reader.readValue(at: &cursor), 12.34e-56)
        XCTAssertEqual(try reader.nextArrayElement(at: &cursor), true)
        XCTAssertEqual(try reader.readValue(at: &cursor), 12.34e6)
        XCTAssertEqual(try reader.nextArrayElement(at: &cursor), true)
        XCTAssertEqual(try reader.readValue(at: &cursor), 2e-3)
        XCTAssertEqual(try reader.nextArrayElement(at: &cursor), true)
        XCTAssertEqual(try reader.readValue(at: &cursor), 43)
        XCTAssertEqual(try reader.nextArrayElement(at: &cursor), false)
        XCTAssertTrue(reader.isEnd(cursor))
    }

    func testSimpleEscapeSequences() throws {
        let subject = "[\"\\\"\", \"\\\\\", \"\\/\", \"\\b\", \"\\f\", \"\\n\", \"\\r\", \"\\t\"]"
        let reader = try JsonReader(string: subject)
        var cursor = reader.startReading()
        XCTAssertEqual(try reader.peekValue(at: cursor), .array)
        XCTAssertEqual(try reader.nextArrayElement(at: &cursor), true)
        XCTAssertEqual(try reader.readString(at: &cursor), "\"")
        XCTAssertEqual(try reader.nextArrayElement(at: &cursor), true)
        XCTAssertEqual(try reader.readString(at: &cursor), "\\")
        XCTAssertEqual(try reader.nextArrayElement(at: &cursor), true)
        XCTAssertEqual(try reader.readString(at: &cursor), "/")
        XCTAssertEqual(try reader.nextArrayElement(at: &cursor), true)
        XCTAssertEqual(try reader.readString(at: &cursor), "\u{08}")
        XCTAssertEqual(try reader.nextArrayElement(at: &cursor), true)
        XCTAssertEqual(try reader.readString(at: &cursor), "\u{0C}")
        XCTAssertEqual(try reader.nextArrayElement(at: &cursor), true)
        XCTAssertEqual(try reader.readString(at: &cursor), "\u{0A}")
        XCTAssertEqual(try reader.nextArrayElement(at: &cursor), true)
        XCTAssertEqual(try reader.readString(at: &cursor), "\u{0D}")
        XCTAssertEqual(try reader.nextArrayElement(at: &cursor), true)
        XCTAssertEqual(try reader.readString(at: &cursor), "\u{09}")
        XCTAssertEqual(try reader.nextArrayElement(at: &cursor), false)
        XCTAssertTrue(reader.isEnd(cursor))
    }

    func testUnicodeEscapeSequence() throws {
        let subject = "[\"\\u2728\"]"
        let reader = try JsonReader(string: subject)
        var cursor = reader.startReading()
        XCTAssertEqual(try reader.peekValue(at: cursor), .array)
        XCTAssertEqual(try reader.nextArrayElement(at: &cursor), true)
        XCTAssertEqual(try reader.readString(at: &cursor), "✨")
        XCTAssertEqual(try reader.nextArrayElement(at: &cursor), false)
        XCTAssertTrue(reader.isEnd(cursor))
    }

    func testUnicodeSurrogatePairEscapeSequence() throws {
        let subject = "[\"\\uD834\\udd1E\"]"
        let reader = try JsonReader(string: subject)
        var cursor = reader.startReading()
        XCTAssertEqual(try reader.peekValue(at: cursor), .array)
        XCTAssertEqual(try reader.nextArrayElement(at: &cursor), true)
        XCTAssertEqual(try reader.readString(at: &cursor), "\u{1D11E}")
        XCTAssertEqual(try reader.nextArrayElement(at: &cursor), false)
        XCTAssertTrue(reader.isEnd(cursor))
    }

    func testAllowFragments() throws {
        let subject = "3"
        let reader = try JsonReader(string: subject)
        var cursor = reader.startReading()
        XCTAssertEqual(try reader.readValue(at: &cursor), 3)
        XCTAssertTrue(reader.isEnd(cursor))
    }

    func testUnterminatedObjectString() throws {
        let subject = "{\"}"
        let reader = try JsonReader(string: subject)
        var cursor = reader.startReading()
        XCTAssertThrowsError(try reader.skipValue(at: &cursor)) {
            XCTAssertEqual($0 as? JsonError, JsonError.unexpectedEndOfStream)
        }
        XCTAssertTrue(reader.isEnd(cursor))
    }

    func testMissingObjectKey() throws {
        let subject = "{3}"
        let reader = try JsonReader(string: subject)
        var cursor = reader.startReading()
        XCTAssertThrowsError(try reader.skipValue(at: &cursor)) {
            XCTAssertEqual($0 as? JsonError, JsonError.unexpectedSymbol)
        }
    }

    func testUnexpectedEndOfFile() throws {
        let subject = "{"
        let reader = try JsonReader(string: subject)
        var cursor = reader.startReading()
        XCTAssertThrowsError(try reader.skipValue(at: &cursor)) {
            XCTAssertEqual($0 as? JsonError, JsonError.unexpectedEndOfStream)
        }
    }

    func testInvalidValueInObject() throws {
        let subject = "{\"error\":}"
        let reader = try JsonReader(string: subject)
        var cursor = reader.startReading()
        XCTAssertThrowsError(try reader.skipValue(at: &cursor)) {
            XCTAssertEqual($0 as? JsonError, JsonError.unexpectedSymbol)
        }
    }

    func testInvalidValueIncorrectSeparatorInObject() throws {
        let subject = "{\"missing\";}"
        let reader = try JsonReader(string: subject)
        var cursor = reader.startReading()
        XCTAssertThrowsError(try reader.skipValue(at: &cursor)) {
            XCTAssertEqual($0 as? JsonError, JsonError.unexpectedSymbol)
        }
    }

    func testInvalidValueInArray() throws {
        let subject = "[,"
        let reader = try JsonReader(string: subject)
        var cursor = reader.startReading()
        XCTAssertThrowsError(try reader.skipValue(at: &cursor)) {
            XCTAssertEqual($0 as? JsonError, JsonError.unexpectedSymbol)
        }
    }

    func testBadlyFormedArray() throws {
        let subject = "[2b4]"
        let reader = try JsonReader(string: subject)
        var cursor = reader.startReading()
        XCTAssertThrowsError(try reader.skipValue(at: &cursor)) {
            XCTAssertEqual($0 as? JsonError, JsonError.unexpectedSymbol)
        }
    }

    func testInvalidEscapeSequence() throws {
        let subject = "[\"\\e\"]"
        let reader = try JsonReader(string: subject)
        var cursor = reader.startReading()
        XCTAssertThrowsError(try reader.skipValue(at: &cursor)) {
            XCTAssertEqual($0 as? JsonError, JsonError.badEscapeSequence)
        }
    }

    func testUnicodeMissingLeadingSurrogate() throws {
        let subject = "\"\\uDFF3\""
        let reader = try JsonReader(string: subject)
        var cursor = reader.startReading()
        XCTAssertThrowsError(_ = try reader.readString(at: &cursor)) {
            XCTAssertEqual($0 as? JsonError, JsonError.badUnicodeEscapeSequence)
        }
    }

    func testUnicodeMissingTrailingSurrogate() throws {
        let subject = "\"\\uD834\""
        let reader = try JsonReader(string: subject)
        var cursor = reader.startReading()
        XCTAssertThrowsError(_ = try reader.readString(at: &cursor)) {
            XCTAssertEqual($0 as? JsonError, JsonError.unexpectedSymbol)
        }
    }

    func testReadingOffTheEndOfBuffers() throws {
        var data = "12345679".data(using: .utf8)!
        try data.withUnsafeMutableBytes { bytes in
            let slice = Data(bytesNoCopy: bytes.baseAddress!, count: 1, deallocator: .none)
            let reader = JsonReader(data: slice)
            var cursor = reader.startReading()
            XCTAssertEqual(try reader.readNumber(at: &cursor), 1)
        }
    }

    func testBailOnDeepValidStructure() throws {
        let repetition = 8000
        let subject = String(repeating: "[", count: repetition) +  String(repeating: "]", count: repetition)
        let reader = try JsonReader(string: subject)
        var cursor = reader.startReading()
        XCTAssertThrowsError(try reader.skipValue(at: &cursor)) {
            XCTAssertEqual($0 as? JsonError, JsonError.depthLimitReached)
        }
    }

    func testBailOnDeepInvalidStructure() throws {
        let repetition = 8000
        let subject = String(repeating: "[", count: repetition) +  String(repeating: "]", count: repetition)
        let reader = try JsonReader(string: subject)
        var cursor = reader.startReading()
        XCTAssertThrowsError(try reader.skipValue(at: &cursor)) {
            XCTAssertEqual($0 as? JsonError, JsonError.depthLimitReached)
        }
    }
}
