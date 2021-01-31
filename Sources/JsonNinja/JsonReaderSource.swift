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

@usableFromInline
@frozen internal struct JsonReaderSource {
    private let owner: AnyObject
    private let baseAddress: UnsafePointer<UInt8>
    private let count: Int

    internal init(owner: AnyObject, baseAddress: UnsafePointer<UInt8>, count: Int) {
        self.owner = owner
        self.baseAddress = baseAddress
        self.count = count
    }
}

extension JsonReaderSource {
    @_transparent
    internal func start() -> JsonCursor {
        return JsonCursor(offset: 0)
    }

    @_transparent
    internal func isEnd(_ cursor: JsonCursor) -> Bool {
        return cursor.offset == count
    }

    @_transparent
    internal func advance(_ cursor: inout JsonCursor) {
        cursor.offset += 1
    }

    @_transparent
    internal func asciiCodePoint(at cursor: JsonCursor) throws -> UInt8 {
        if cursor.offset < count {
            return baseAddress[cursor.offset]
        } else {
            throw JsonError.unexpectedEndOfStream
        }
    }

    @_transparent
    internal func uncheckedAsciiCodePoint(at cursor: JsonCursor) -> UInt8 {
        return baseAddress[cursor.offset]
    }

    @_transparent
    internal func uncheckedUnicodeString(from: JsonCursor, to: JsonCursor) throws -> String {
        if let result = String(data: Data(bytes: baseAddress.advanced(by: from.offset), count: to.offset - from.offset), encoding: .utf8) {
            return result
        } else {
            throw JsonError.unicodeError
        }
    }
}
