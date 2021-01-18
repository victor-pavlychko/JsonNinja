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

@frozen public struct JsonSourceWrapper {
    private let owner: AnyObject

    @usableFromInline
    internal let base: JsonSourcePointer

    public init(owner: AnyObject, base: JsonSourcePointer) {
        self.owner = owner
        self.base = base
    }
}

extension JsonSourceWrapper {
    public init(data: NSData) {
        self.init(owner: data, base: JsonSourcePointer(baseAddress: data.bytes.assumingMemoryBound(to: UInt8.self), count: data.count))
    }
}

extension JsonSourceWrapper {
    public init(contentsOf url: URL) throws {
        try self.init(data: NSData(contentsOf: url, options: [.mappedIfSafe]))
    }
}

extension JsonSourceWrapper {
    public init(string: String) throws {
        if let data = string.data(using: .utf8) {
            self.init(data: data as NSData)
        } else {
            throw JsonError.unicodeError
        }
    }
}

extension JsonSourceWrapper: JsonSource {
    public typealias Cursor = JsonSourcePointer.Cursor

    @_transparent
    public func start() -> Cursor {
        return base.start()
    }

    @_transparent
    public func isEnd(_ cursor: Cursor) -> Bool {
        return base.isEnd(cursor)
    }

    @_transparent
    public func advance(_ cursor: inout Cursor) {
        return base.advance(&cursor)
    }

    @_transparent
    public func asciiCodePoint(at cursor: Cursor) throws -> UInt8 {
        return try base.asciiCodePoint(at: cursor)
    }

    @_transparent
    public func uncheckedAsciiCodePoint(at cursor: Cursor) -> UInt8 {
        return base.uncheckedAsciiCodePoint(at: cursor)
    }

    @_transparent
    public func uncheckedUnicodeString(from: Cursor, to: Cursor) throws -> String {
        return try base.uncheckedUnicodeString(from: from, to: to)
    }
}
