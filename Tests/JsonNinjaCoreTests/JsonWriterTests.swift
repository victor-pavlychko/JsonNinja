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

final class JsonWriterTests: XCTestCase {
    func testEmptyObject() throws {
        let string = makeJsonData { writer in
            writer.writeObjectBegin()
            writer.writeObjectEnd()
        }

        XCTAssertEqual(string, "{}")
    }

    func testEmptyArray() throws {
        let string = makeJsonData { writer in
            writer.writeArrayBegin()
            writer.writeArrayEnd()
        }

        XCTAssertEqual(string, "[]")
    }

    func testDoubleLessThanOne() {
        //test serialize values less than 1 with maxFractionDigits = 15
        //expected : input to be serialized
        let params  = [
            ("0.1", 0.1),
            ("0.2", 0.2),
            ("0.3", 0.3),
            ("0.4", 0.4),
            ("0.5", 0.5),
            ("0.6", 0.6),
            ("0.7", 0.7),
            ("0.8", 0.8),
            ("0.9", 0.9),
            ("0.23456789012345", 0.23456789012345),

            ("-0.1", -0.1),
            ("-0.2", -0.2),
            ("-0.3", -0.3),
            ("-0.4", -0.4),
            ("-0.5", -0.5),
            ("-0.6", -0.6),
            ("-0.7", -0.7),
            ("-0.8", -0.8),
            ("-0.9", -0.9),
            ("-0.23456789012345", -0.23456789012345),
        ]

        for param in params {
            let string = makeJsonData { writer in
                writer.writeObject { writer in
                    writer.writeNumber(param.1, name: param.0)
                }
            }

            XCTAssertEqual(string, "{\"\(param.0)\":\(param.1)}", "serialized value should  have a decimal places and leading zero")
        }
    }

    func testDoubleGraterThanOne() {
        //test serialize values grater than 1 with maxFractionDigits = 15
        let paramsBove1 = [
            ("1.1", 1.1),
            ("1.2", 1.2),
            ("1.23456789012345", 1.23456789012345),
            ("-1.1", -1.1),
            ("-1.2", -1.2),
            ("-1.23456789012345", -1.23456789012345),
        ]

        for param in paramsBove1 {
            let string = makeJsonData { writer in
                writer.writeObject { writer in
                    writer.writeNumber(param.1, name: param.0)
                }
            }

            XCTAssertEqual(string, "{\"\(param.0)\":\(param.1)}", "serialized Double should  have a decimal places and leading value")
        }
    }

    func testWholeNumbersWithDoubleAsInput() {
        //test serialize values for whole integer where the input is in Double format
        let paramsWholeNumbers = [
            ("-1", -1.0),
            ("0", 0.0),
            ("1", 1.0),
        ]

        for param in paramsWholeNumbers {
            let string = makeJsonData { writer in
                writer.writeObject { writer in
                    writer.writeNumber(param.1, name: param.0)
                }
            }

            XCTAssertEqual(string, "{\"\(param.0)\":\(NSString(string:param.0).intValue)}", "expect that serialized value should not contain trailing zero or decimal as they are whole numbers ")
        }
    }

    func testWholeNumbersWithIntInput() {
        for i  in -10 ..< 10 {
            let string = makeJsonData { writer in
                writer.writeObject { writer in
                    writer.writeNumber(i, name: "\(i)")
                }
            }

            XCTAssertEqual(string, "{\"\(i)\":\(i)}", "expect that serialized value should not contain trailing zero or decimal as they are whole numbers ")
        }
    }

    func testNull() {
        do {
            let string = makeJsonData { writer in
                writer.writeArray { writer in
                    writer.writeNull()
                }
            }

            XCTAssertEqual(string, "[null]")
        }

        do {
            let string = makeJsonData { writer in
                writer.writeObject { writer in
                    writer.writeNull(name: "a")
                }
            }

            XCTAssertEqual(string, "{\"a\":null}")
        }

        do {
            let string = makeJsonData { writer in
                writer.writeArray { writer in
                    for _ in 0 ..< 3 {
                        writer.writeNull()
                    }
                }
            }

            XCTAssertEqual(string, "[null,null,null]")
        }

        do {
            let string = makeJsonData { writer in
                writer.writeArray { writer in
                    writer.writeObject { writer in
                        writer.writeNull(name: "a")
                    }
                    writer.writeObject { writer in
                        writer.writeNull(name: "b")
                    }
                    writer.writeObject { writer in
                        writer.writeNull(name: "c")
                    }
                }
            }

            XCTAssertEqual(string, "[{\"a\":null},{\"b\":null},{\"c\":null}]")
        }
    }

    func testComplexObject() {
        do {
            let string = makeJsonData { writer in
                writer.writeObject { writer in
                    writer.writeNumber(4, name: "a")
                }
            }

            XCTAssertEqual(string, "{\"a\":4}")
        }

        do {
            let string = makeJsonData { writer in
                writer.writeArray { writer in
                    for i in 1 ... 4 {
                        writer.writeNumber(i)
                    }
                }
            }

            XCTAssertEqual(string, "[1,2,3,4]")
        }

        do {
            let string = makeJsonData { writer in
                writer.writeObject { writer in
                    writer.writeArray(name: "a") { writer in
                        writer.writeNumber(1)
                        writer.writeNumber(2)
                    }
                }
            }

            XCTAssertEqual(string, "{\"a\":[1,2]}")
        }

        do {
            let string = makeJsonData { writer in
                writer.writeArray { writer in
                    writer.writeString("a")
                    writer.writeString("b")
                    writer.writeString("c")
                }
            }

            XCTAssertEqual(string, "[\"a\",\"b\",\"c\"]")
        }

        do {
            let string = makeJsonData { writer in
                writer.writeArray { writer in
                    writer.writeObject { writer in
                        writer.writeNumber(1, name: "a")
                    }
                    writer.writeObject { writer in
                        writer.writeNumber(2, name: "b")
                    }
                }
            }

            XCTAssertEqual(string, "[{\"a\":1},{\"b\":2}]")
        }

        do {
            let string = makeJsonData { writer in
                writer.writeArray { writer in
                    writer.writeObject { writer in
                        writer.writeNull(name: "a")
                    }
                    writer.writeObject { writer in
                        writer.writeNull(name: "b")
                    }
                }
            }

            XCTAssertEqual(string, "[{\"a\":null},{\"b\":null}]")
        }
    }

    func testNestedArray() {
        do {
            let string = makeJsonData { writer in
                writer.writeArray { writer in
                    writer.writeString("a")
                }
            }

            XCTAssertEqual(string, "[\"a\"]")
        }

        do {
            let string = makeJsonData { writer in
                writer.writeArray { writer in
                    writer.writeArray { writer in
                        writer.writeString("b")
                    }
                }
            }

            XCTAssertEqual(string, "[[\"b\"]]")
        }

        do {
            let string = makeJsonData { writer in
                writer.writeArray { writer in
                    writer.writeArray { writer in
                        writer.writeArray { writer in
                            writer.writeString("c")
                        }
                    }
                }
            }

            XCTAssertEqual(string, "[[[\"c\"]]]")
        }

        do {
            let string = makeJsonData { writer in
                writer.writeArray { writer in
                    writer.writeArray { writer in
                        writer.writeArray { writer in
                            writer.writeArray { writer in
                                writer.writeString("d")
                            }
                        }
                    }
                }
            }

            XCTAssertEqual(string, "[[[[\"d\"]]]]")
        }
    }

    func testNestedDictionary() {
        do {
            let string = makeJsonData { writer in
                writer.writeObject { writer in
                    writer.writeNumber(1, name: "a")
                }
            }

            XCTAssertEqual(string, "{\"a\":1}")
        }

        do {
            let string = makeJsonData { writer in
                writer.writeObject { writer in
                    writer.writeObject(name: "a") { writer in
                        writer.writeNumber(1, name: "b")
                    }
                }
            }

            XCTAssertEqual(string, "{\"a\":{\"b\":1}}")
        }

        do {
            let string = makeJsonData { writer in
                writer.writeObject { writer in
                    writer.writeObject(name: "a") { writer in
                        writer.writeObject(name: "b") { writer in
                            writer.writeNumber(1, name: "c")
                        }
                    }
                }
            }

            XCTAssertEqual(string, "{\"a\":{\"b\":{\"c\":1}}}")
        }

        do {
            let string = makeJsonData { writer in
                writer.writeObject { writer in
                    writer.writeObject(name: "a") { writer in
                        writer.writeObject(name: "b") { writer in
                            writer.writeObject(name: "c") { writer in
                                writer.writeNumber(1, name: "d")
                            }
                        }
                    }
                }
            }

            XCTAssertEqual(string, "{\"a\":{\"b\":{\"c\":{\"d\":1}}}}")
        }

        do {
            let string = makeJsonData { writer in
                writer.writeObject { writer in
                    writer.writeObject(name: "a") { writer in
                        writer.writeObject(name: "b") { writer in
                            writer.writeArray(name: "c") { writer in
                                writer.writeNumber(1)
                                writer.writeNull()
                            }
                        }
                    }
                }
            }

            XCTAssertEqual(string, "{\"a\":{\"b\":{\"c\":[1,null]}}}")
        }
    }

    func testNumber() {
        do {
            let string = makeJsonData { writer in
                writer.writeArray { writer in
                    writer.writeNumber(1)
                    writer.writeNumber(1.1)
                    writer.writeNumber(0)
                    writer.writeNumber(-2)
                }
            }

            XCTAssertEqual(string, "[1,1.1,0,-2]")
        }

        do {
            let string = makeJsonData { writer in
                writer.writeArray { writer in
                    writer.writeBool(false)
                    writer.writeBool(true)
                }
            }

            XCTAssertEqual(string, "[false,true]")
        }
    }

    func testIntMax() {
        let string = makeJsonData { writer in
            writer.writeArray { writer in
                writer.writeNumber(Int.max)
            }
        }

        XCTAssertEqual(string, "[\(Int.max)]")
    }

    func testIntMin() {
        let string = makeJsonData { writer in
            writer.writeArray { writer in
                writer.writeNumber(Int.min)
            }
        }

        XCTAssertEqual(string, "[\(Int.min)]")
    }

    func testUIntMax() {
        let string = makeJsonData { writer in
            writer.writeArray { writer in
                writer.writeNumber(UInt.max)
            }
        }

        XCTAssertEqual(string, "[\(UInt.max)]")
    }

    func testUIntMin() {
        let string = makeJsonData { writer in
            writer.writeArray { writer in
                writer.writeNumber(UInt.min)
            }
        }

        XCTAssertEqual(string, "[\(UInt.min)]")
    }

    func test8BitSizes() {
        do {
            let string = makeJsonData { writer in
                writer.writeArray { writer in
                    writer.writeNumber(Int8.min)
                    writer.writeNumber(Int8(-1))
                    writer.writeNumber(Int8(0))
                    writer.writeNumber(Int8(1))
                    writer.writeNumber(Int8.max)
                }
            }

            XCTAssertEqual(string, "[-128,-1,0,1,127]")
        }

        do {
            let string = makeJsonData { writer in
                writer.writeArray { writer in
                    writer.writeNumber(UInt8.min)
                    writer.writeNumber(UInt8(0))
                    writer.writeNumber(UInt8(1))
                    writer.writeNumber(UInt8.max)
                }
            }

            XCTAssertEqual(string, "[0,0,1,255]")
        }
    }

    func test16BitSizes() {
        do {
            let string = makeJsonData { writer in
                writer.writeArray { writer in
                    writer.writeNumber(Int16.min)
                    writer.writeNumber(Int16(-1))
                    writer.writeNumber(Int16(0))
                    writer.writeNumber(Int16(1))
                    writer.writeNumber(Int16.max)
                }
            }

            XCTAssertEqual(string, "[-32768,-1,0,1,32767]")
        }

        do {
            let string = makeJsonData { writer in
                writer.writeArray { writer in
                    writer.writeNumber(UInt16.min)
                    writer.writeNumber(UInt16(0))
                    writer.writeNumber(UInt16(1))
                    writer.writeNumber(UInt16.max)
                }
            }

            XCTAssertEqual(string, "[0,0,1,65535]")
        }
    }

    func test32BitSizes() {
        do {
            let string = makeJsonData { writer in
                writer.writeArray { writer in
                    writer.writeNumber(Int32.min)
                    writer.writeNumber(Int32(-1))
                    writer.writeNumber(Int32(0))
                    writer.writeNumber(Int32(1))
                    writer.writeNumber(Int32.max)
                }
            }

            XCTAssertEqual(string, "[-2147483648,-1,0,1,2147483647]")
        }

        do {
            let string = makeJsonData { writer in
                writer.writeArray { writer in
                    writer.writeNumber(UInt32.min)
                    writer.writeNumber(UInt32(0))
                    writer.writeNumber(UInt32(1))
                    writer.writeNumber(UInt32.max)
                }
            }

            XCTAssertEqual(string, "[0,0,1,4294967295]")
        }
    }

    func test64BitSizes() {
        do {
            let string = makeJsonData { writer in
                writer.writeArray { writer in
                    writer.writeNumber(Int64.min)
                    writer.writeNumber(Int64(-1))
                    writer.writeNumber(Int64(0))
                    writer.writeNumber(Int64(1))
                    writer.writeNumber(Int64.max)
                }
            }

            XCTAssertEqual(string, "[-9223372036854775808,-1,0,1,9223372036854775807]")
        }

        do {
            let string = makeJsonData { writer in
                writer.writeArray { writer in
                    writer.writeNumber(UInt64.min)
                    writer.writeNumber(UInt64(0))
                    writer.writeNumber(UInt64(1))
                    writer.writeNumber(UInt64.max)
                }
            }

            XCTAssertEqual(string, "[0,0,1,18446744073709551615]")
        }
    }

    func testFloat() {
        do {
            let string = makeJsonData { writer in
                writer.writeArray { writer in
                    writer.writeNumber(-Float.leastNonzeroMagnitude)
                    writer.writeNumber(Float.leastNonzeroMagnitude)
                }
            }

            XCTAssertEqual(string, "[-1e-45,1e-45]")
        }

        do {
            let string = makeJsonData { writer in
                writer.writeArray { writer in
                    writer.writeNumber(-Float.greatestFiniteMagnitude)
                }
            }

            XCTAssertEqual(string, "[-3.4028235e+38]")
        }

        do {
            let string = makeJsonData { writer in
                writer.writeArray { writer in
                    writer.writeNumber(Float.greatestFiniteMagnitude)
                }
            }

            XCTAssertEqual(string, "[3.4028235e+38]")
        }

        do {
            let string = makeJsonData { writer in
                writer.writeArray { writer in
                    writer.writeNumber(Float(-1))
                    writer.writeNumber(Float.leastNonzeroMagnitude)
                    writer.writeNumber(Float(1))
                }
            }

            XCTAssertEqual(string, "[-1,1e-45,1]")
        }
    }

    func testDouble() {
        do {
            let string = makeJsonData { writer in
                writer.writeArray { writer in
                    writer.writeNumber(-Double.leastNonzeroMagnitude)
                    writer.writeNumber(Double.leastNonzeroMagnitude)
                }
            }

            XCTAssertEqual(string, "[-5e-324,5e-324]")
        }

        do {
            let string = makeJsonData { writer in
                writer.writeArray { writer in
                    writer.writeNumber(-Double.leastNormalMagnitude)
                    writer.writeNumber(Double.leastNormalMagnitude)
                }
            }

            XCTAssertEqual(string, "[-2.2250738585072014e-308,2.2250738585072014e-308]")
        }

        do {
            let string = makeJsonData { writer in
                writer.writeArray { writer in
                    writer.writeNumber(-Double.greatestFiniteMagnitude)
                }
            }

            XCTAssertEqual(string, "[-1.7976931348623157e+308]")
        }

        do {
            let string = makeJsonData { writer in
                writer.writeArray { writer in
                    writer.writeNumber(Double.greatestFiniteMagnitude)
                }
            }

            XCTAssertEqual(string, "[1.7976931348623157e+308]")
        }

        do {
            let string = makeJsonData { writer in
                writer.writeArray { writer in
                    writer.writeNumber(Double(-1))
                    writer.writeNumber(Double(1))
                }
            }

            XCTAssertEqual(string, "[-1,1]")
        }

//        // Test round-tripping Double values
//        let value1 = 7.7087009966199993
//        let value2 = 7.7087009966200002
//        let dict1 = ["value": value1]
//        let dict2 = ["value": value2]
//        var jsonData1: Data?
//        var jsonData2: Data?
//        XCTAssertNoThrow(jsonData1 = try JSONSerialization.data(withJSONObject: dict1))
//        XCTAssertNoThrow(jsonData2 = try JSONSerialization.data(withJSONObject: dict2))
//        var jsonString1: String?
//        var jsonString2: String?
//        XCTAssertNoThrow(jsonString1 = try String(decoding: XCTUnwrap(jsonData1), as: UTF8.self))
//        XCTAssertNoThrow(jsonString2 = try String(decoding: XCTUnwrap(jsonData2), as: UTF8.self))
//
//        XCTAssertEqual(jsonString1, "{\"value\":7.708700996619999}")
//        XCTAssertEqual(jsonString2, "{\"value\":7.70870099662}")
//        var decodedDict1: [String : Double]?
//        var decodedDict2: [String : Double]?
//        XCTAssertNoThrow(decodedDict1 = try JSONSerialization.jsonObject(with: XCTUnwrap(jsonData1)) as? [String : Double])
//        XCTAssertNoThrow(decodedDict2 = try JSONSerialization.jsonObject(with: XCTUnwrap(jsonData2)) as? [String : Double])
//        XCTAssertEqual(decodedDict1?["value"], value1)
//        XCTAssertEqual(decodedDict2?["value"], value2)
    }

    func testStringEscaping() {
        do {
            let string = makeJsonData { writer in
                writer.writeArray { writer in
                    writer.writeString("foo")
                }
            }

            XCTAssertEqual(string, "[\"foo\"]")
        }

        do {
            let string = makeJsonData { writer in
                writer.writeArray { writer in
                    writer.writeString("a\0")
                }
            }

            XCTAssertEqual(string, "[\"a\\u0000\"]")
        }

        do {
            let string = makeJsonData { writer in
                writer.writeArray { writer in
                    writer.writeString("b\\")
                }
            }

            XCTAssertEqual(string, "[\"b\\\\\"]")
        }

        do {
            let string = makeJsonData { writer in
                writer.writeArray { writer in
                    writer.writeString("c\t")
                }
            }

            XCTAssertEqual(string, "[\"c\\t\"]")
        }

        do {
            let string = makeJsonData { writer in
                writer.writeArray { writer in
                    writer.writeString("d\n")
                }
            }

            XCTAssertEqual(string, "[\"d\\n\"]")
        }

        do {
            let string = makeJsonData { writer in
                writer.writeArray { writer in
                    writer.writeString("e\r")
                }
            }

            XCTAssertEqual(string, "[\"e\\r\"]")
        }

        do {
            let string = makeJsonData { writer in
                writer.writeArray { writer in
                    writer.writeString("f\"")
                }
            }

            XCTAssertEqual(string, "[\"f\\\"\"]")
        }

        do {
            let string = makeJsonData { writer in
                writer.writeArray { writer in
                    writer.writeString("g\'")
                }
            }

            XCTAssertEqual(string, "[\"g\'\"]")
        }

        do {
            let string = makeJsonData { writer in
                writer.writeArray { writer in
                    writer.writeString("h\u{7}")
                }
            }

            XCTAssertEqual(string, "[\"h\\u0007\"]")
        }

        do {
            let string = makeJsonData { writer in
                writer.writeArray { writer in
                    writer.writeString("i\u{1f}")
                }
            }

            XCTAssertEqual(string, "[\"i\\u001f\"]")
        }

        do {
            let string = makeJsonData { writer in
                writer.writeArray { writer in
                    writer.writeString("j/")
                }
            }

            XCTAssertEqual(string, "[\"j/\"]")
        }
    }

    func testFragments() {
        do {
            let string = makeJsonData { writer in
                writer.writeNumber(2)
            }

            XCTAssertEqual(string, "2")
        }

        do {
            let string = makeJsonData { writer in
                writer.writeBool(false)
            }

            XCTAssertEqual(string, "false")
        }

        do {
            let string = makeJsonData { writer in
                writer.writeBool(true)
            }

            XCTAssertEqual(string, "true")
        }

        do {
            let string = makeJsonData { writer in
                writer.writeNumber(1.0)
            }

            XCTAssertEqual(string, "1")
        }

        do {
            let string = makeJsonData { writer in
                writer.writeString("test")
            }

            XCTAssertEqual(string, "\"test\"")
        }

        do {
            let string = makeJsonData { writer in
                writer.writeNull()
            }

            XCTAssertEqual(string, "null")
        }
    }

    private func makeJsonData(writeContent: (inout JsonWriter) throws -> Void) rethrows -> String {
        var writer = JsonWriter()
        try writeContent(&writer)
        let result = writer.finish()
        return String(decoding: result, as: UTF8.self)
    }

}
