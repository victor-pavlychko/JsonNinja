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

@frozen public struct JsonSourcePointer {
    @usableFromInline
    internal let baseAddress: UnsafePointer<UInt8>

    @usableFromInline
    internal let count: Int

    public init(baseAddress: UnsafePointer<UInt8>, count: Int) {
        self.baseAddress = baseAddress
        self.count = count
    }

    public init(buffer: UnsafeBufferPointer<UInt8>) {
        self.init(baseAddress: buffer.baseAddress!, count: buffer.count)
    }

    public init(buffer: UnsafeRawBufferPointer) {
        self.init(buffer: buffer.bindMemory(to: UInt8.self))
    }
}

extension JsonSourcePointer: JsonSource {
    @frozen public struct Cursor: Equatable, CustomStringConvertible {
        @usableFromInline
        internal var offset: Int

        @usableFromInline
        internal init() {
            self.offset = 0
        }

        public var debugOffset: Int {
            return offset
        }

        public var description: String {
            return "<JsonSourcePointer.Cursor@\(offset)>"
        }
    }

    @_transparent
    public func start() -> Cursor {
        return Cursor()
    }

    @_transparent
    public func isEnd(_ cursor: Cursor) -> Bool {
        return cursor.offset == count
    }

    @_transparent
    public func advance(_ cursor: inout Cursor) {
        cursor.offset += 1
    }

    @_transparent
    public func asciiCodePoint(at cursor: Cursor) throws -> UInt8 {
        if cursor.offset < count {
            return baseAddress[cursor.offset]
        } else {
            throw JsonError.unexpectedEndOfStream
        }
    }

    @_transparent
    public func uncheckedAsciiCodePoint(at cursor: Cursor) -> UInt8 {
        return baseAddress[cursor.offset]
    }

    @_transparent
    public func uncheckedUnicodeString(from: Cursor, to: Cursor) throws -> String {
        if let result = String(data: Data(bytes: baseAddress.advanced(by: from.offset), count: to.offset - from.offset), encoding: .utf8) {
            return result
        } else {
            throw JsonError.unicodeError
        }
    }
}
