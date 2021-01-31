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

public struct JsonWriter {
    private var sink = JsonWriterSink()
    private var isFirstEntry = false

    public init() { }
}

extension JsonWriter {
    public static var defaultBufferSize = 1024
}

extension JsonWriter {
    public mutating func finish() -> [UInt8] {
        sink.flush()
        return sink.buffer
    }
}

extension JsonWriter {
    public mutating func writeString(_ value: String) {
        sink.write(.doubleQuotes)

        if value.isContiguousUTF8 || value.count < Self.defaultBufferSize {
            var value = value
            value.withUTF8 {
                writeEscaped($0)
            }
        } else {
            for byte in value.utf8 {
                writeEscaped(byte)
            }
        }

        sink.write(.doubleQuotes)
    }

    private mutating func writeEscaped(_ bytes: UnsafeBufferPointer<UInt8>) {
        var chunk = 0

        for index in 0 ..< bytes.count {
            switch bytes[index] {
            case .doubleQuotes,
                 .backslash,
                 0 ..< 0x20:
                if index != chunk {
                    sink.write(bytes.subBuffer(chunk ..< index))
                }

                writeEscaped(bytes[index])

                chunk = index + 1

            default:
                break
            }
        }

        if chunk != bytes.count {
            sink.write(bytes.subBuffer(chunk ..< bytes.count))
        }
    }

    private mutating func writeEscaped(_ byte: UInt8) {
        switch byte {
        case .doubleQuotes:
            sink.write(.backslash)
            sink.write(.doubleQuotes)

        case .backslash:
            sink.write(.backslash)
            sink.write(.backslash)

        case .backspace:
            sink.write(.backslash)
            sink.write(.lowercaseB)

        case .formFeed:
            sink.write(.backslash)
            sink.write(.lowercaseF)

        case .lineFeed:
            sink.write(.backslash)
            sink.write(.lowercaseN)

        case .carrigeReturn:
            sink.write(.backslash)
            sink.write(.lowercaseR)

        case .horizontalTab:
            sink.write(.backslash)
            sink.write(.lowercaseT)

        case 0 ..< 0x20:
            sink.write(.backslash)
            sink.write(.lowercaseU)
            sink.write(.digitZero)
            sink.write(.digitZero)
            writeHexDigit((byte >> 4) & 0xf)
            writeHexDigit((byte >> 0) & 0xf)

        default:
            sink.write(byte)
        }
    }

    @_transparent
    private mutating func writeHexDigit(_ digit: UInt8) {
        switch digit {
        case 0x0 ... 0x9:
            sink.write(.digitZero + digit)
        case 0xa ... 0xf:
            sink.write(.lowercaseA + digit - 0xa)
        default:
            preconditionFailure()
        }
    }
}

extension JsonWriter {
    public mutating func writeNumber(_ value: Int) {
        var string = value.description
        string.withUTF8 {
            sink.write($0)
        }
    }

    public mutating func writeNumber(_ value: UInt) {
        var string = value.description
        string.withUTF8 {
            sink.write($0)
        }
    }

    public mutating func writeNumber(_ value: Double) {
        var string = value.description
        string.withUTF8 {
            sink.write($0)
        }
    }
}

extension JsonWriter {
    public mutating func writeArray(_ writeContents: (inout JsonWriter) throws -> Void) rethrows {
        writeArrayBegin()
        try writeContents(&self)
        writeArrayEnd()
    }

    public mutating func writeArrayBegin() {
        sink.write(.openingBracket)
        isFirstEntry = true
    }

    public mutating func writeArrayElement() {
        if isFirstEntry {
            isFirstEntry = false
        } else {
            sink.write(.comma)
        }
    }

    public mutating func writeArrayEnd() {
        sink.write(.closingBracket)
    }
}

extension JsonWriter {
    public mutating func writeObject(_ writeContents: (inout JsonWriter) throws -> Void) rethrows {
        writeObjectBegin()
        try writeContents(&self)
        writeObjectEnd()
    }

    public mutating func writeObjectBegin() {
        sink.write(.openingBrace)
        isFirstEntry = true
    }

    public mutating func writeObjectProperty(name: String) {
        if isFirstEntry {
            isFirstEntry = false
        } else {
            sink.write(.comma)
        }

        writeString(name)
        sink.write(.colon)
    }

    public mutating func writeObjectEnd() {
        sink.write(.closingBrace)
    }
}

extension JsonWriter {
    public mutating func writeBool(_ value: Bool) {
        switch value {
        case true:
            sink.write(.lowercaseT)
            sink.write(.lowercaseR)
            sink.write(.lowercaseU)
            sink.write(.lowercaseE)

        case false:
            sink.write(.lowercaseF)
            sink.write(.lowercaseA)
            sink.write(.lowercaseL)
            sink.write(.lowercaseS)
            sink.write(.lowercaseE)
        }
    }
}

extension JsonWriter {
    public mutating func writeNull() {
        sink.write(.lowercaseN)
        sink.write(.lowercaseU)
        sink.write(.lowercaseL)
        sink.write(.lowercaseL)
    }
}
