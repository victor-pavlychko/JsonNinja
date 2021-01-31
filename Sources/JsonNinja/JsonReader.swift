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

@frozen public struct JsonReader {
    private let source: JsonReaderSource
}

extension JsonReader {
    public static var defaultDepthLimit = 1024
}

extension JsonReader {
    public init(data: NSData) {
        self.init(source: JsonReaderSource(owner: data, baseAddress: data.bytes.assumingMemoryBound(to: UInt8.self), count: data.count))
    }

    public init(data: Data) {
        self.init(data: data as NSData)
    }

    public init(contentsOf url: URL) throws {
        try self.init(data: NSData(contentsOf: url, options: [.mappedIfSafe]))
    }

    public init(string: String) throws {
        if let data = string.data(using: .utf8) {
            self.init(data: data as NSData)
        } else {
            throw JsonError.unicodeError
        }
    }
}

extension JsonReader {
    public func startReading() -> JsonCursor {
        var cursor = source.start()
        skipWhiteSpace(at: &cursor)
        return cursor
    }

    public func isEnd(_ cursor: JsonCursor) -> Bool {
        return source.isEnd(cursor)
    }

    public func nextValue(at cursor: inout JsonCursor) -> Bool {
        skipWhiteSpace(at: &cursor)
        return !source.isEnd(cursor)
    }
}

extension JsonReader {
    public func peekValue(at cursor: JsonCursor) throws -> JsonValue.Kind {
        switch try source.asciiCodePoint(at: cursor) {
        case .doubleQuotes:
            return .string

        case .hyphen,
             .digitZero ... .digitNine:
            return .number

        case .openingBrace:
            return .object

        case .openingBracket:
            return .array

        case .lowercaseT, .lowercaseF:
            return .bool

        case .lowercaseN:
            return .null

        default:
            throw JsonError.unexpectedSymbol
        }
    }

    public func skipValue(at cursor: inout JsonCursor, depthLimit: Int = defaultDepthLimit) throws {
        enum State {
            case object
            case array
        }

        var stack: [State] = []

        while true {
            switch try source.asciiCodePoint(at: cursor) {
            case .doubleQuotes:
                try skipString(at: &cursor)

            case .hyphen,
                 .digitZero ... .digitNine:
                try skipNumber(at: &cursor)

            case .openingBrace:
                stack.append(.object)

            case .openingBracket:
                stack.append(.array)

            case .lowercaseT:
                try skipTrue(at: &cursor)

            case .lowercaseF:
                try skipFalse(at: &cursor)

            case .lowercaseN:
                try skipNull(at: &cursor)

            default:
                throw JsonError.unexpectedSymbol
            }

            guard stack.count <= depthLimit else {
                throw JsonError.depthLimitReached
            }

            unwind: while true {
                switch stack.last {
                case .some(.object):
                    if try nextObjectProperty(at: &cursor) {
                        try skipObjectPropertyName(at: &cursor)
                        break unwind
                    } else {
                        stack.removeLast()
                    }

                case .some(.array):
                    if try nextArrayElement(at: &cursor) {
                        break unwind
                    } else {
                        stack.removeLast()
                    }

                case .none:
                    return
                }
            }
        }
    }

    public func readValue(at cursor: inout JsonCursor) throws -> JsonValue {
        switch try peekValue(at: cursor) {
        case .string:
            return try .string(readString(at: &cursor))

        case .number:
            return try .number(readNumber(at: &cursor))

        case .object:
            return .object(cursor)

        case .array:
            return .array(cursor)

        case .bool:
            return try .bool(readBool(at: &cursor))

        case .null:
            try skipNull(at: &cursor)
            return .null
        }
    }
}

extension JsonReader {
    public func skipString(at cursor: inout JsonCursor) throws {
        try skipCodePoint(.doubleQuotes, at: &cursor)

        while true {
            switch try source.asciiCodePoint(at: cursor) {
            case .backslash:
                source.advance(&cursor)

                switch try source.asciiCodePoint(at: cursor) {
                case .doubleQuotes,
                     .backslash,
                     .slash,
                     .lowercaseB,
                     .lowercaseF,
                     .lowercaseN,
                     .lowercaseR,
                     .lowercaseT:
                    source.advance(&cursor)

                case .lowercaseU:
                    source.advance(&cursor)

                    for _ in 0 ..< 4 {
                        switch try source.asciiCodePoint(at: cursor) {
                        case .digitZero ... .digitNine,
                             .lowercaseA ... .lowercaseF,
                             .uppercaseA ... .uppercaseF:
                            source.advance(&cursor)

                        default:
                            throw JsonError.badUnicodeEscapeSequence
                        }
                    }

                default:
                    throw JsonError.badEscapeSequence
                }

            case.doubleQuotes:
                source.advance(&cursor)
                return

            case 0 ..< 0x20:
                throw JsonError.unescapedControlCharacter

            default:
                source.advance(&cursor)
            }
        }
    }

    public func readString(at cursor: inout JsonCursor) throws -> String {
        try skipCodePoint(.doubleQuotes, at: &cursor)

        var result = ""
        var chunk = cursor

        while true {
            switch try source.asciiCodePoint(at: cursor) {
            case .backslash:
                if cursor != chunk {
                    result += try source.uncheckedUnicodeString(from: chunk, to: cursor)
                }

                source.advance(&cursor)
                result += try readEscapeSequence(at: &cursor)

                chunk = cursor

            case.doubleQuotes:
                if cursor != chunk {
                    result += try source.uncheckedUnicodeString(from: chunk, to: cursor)
                }

                source.advance(&cursor)
                return result

            case 0 ..< 0x20:
                throw JsonError.unescapedControlCharacter

            default:
                source.advance(&cursor)
            }
        }
    }

    private func readEscapeSequence(at cursor: inout JsonCursor) throws -> String {
        switch try source.asciiCodePoint(at: cursor) {
        case .doubleQuotes:
            source.advance(&cursor)
            return "\""

        case .backslash:
            source.advance(&cursor)
            return "\\"

        case .slash:
            source.advance(&cursor)
            return "/"

        case .lowercaseB:
            source.advance(&cursor)
            return "\u{08}"

        case .lowercaseF:
            source.advance(&cursor)
            return "\u{0c}"

        case .lowercaseN:
            source.advance(&cursor)
            return "\n"

        case .lowercaseR:
            source.advance(&cursor)
            return "\r"

        case .lowercaseT:
            source.advance(&cursor)
            return "\t"

        case .lowercaseU:
            source.advance(&cursor)
            switch try readUnicodeCodeUnit(at: &cursor) {
            case let leadSurrogate where UTF16.isLeadSurrogate(leadSurrogate):
                try skipCodePoint(.backslash, at: &cursor)
                try skipCodePoint(.lowercaseU, at: &cursor)
                let trailSurrogate = try readUnicodeCodeUnit(at: &cursor)
                return String(UTF16.decode(UTF16.EncodedScalar([leadSurrogate, trailSurrogate])))

            case let trailSurrogate where UTF16.isTrailSurrogate(trailSurrogate):
                throw JsonError.badUnicodeEscapeSequence

            case let codeUnit:
                return String(UnicodeScalar(codeUnit)!)
            }

        default:
            throw JsonError.badEscapeSequence
        }
    }

    @_transparent
    private func readUnicodeCodeUnit(at cursor: inout JsonCursor) throws -> UInt16 {
        var result: UInt16 = 0
        result = try (result << 4) | readUnicodeHexDigit(at: &cursor)
        result = try (result << 4) | readUnicodeHexDigit(at: &cursor)
        result = try (result << 4) | readUnicodeHexDigit(at: &cursor)
        result = try (result << 4) | readUnicodeHexDigit(at: &cursor)
        return result
    }

    @_transparent
    private func readUnicodeHexDigit(at cursor: inout JsonCursor) throws -> UInt16 {
        let digit = try source.asciiCodePoint(at: cursor)

        switch digit {
        case .digitZero ... .digitNine:
            source.advance(&cursor)
            return UInt16(digit - .digitZero)

        case .lowercaseA ... .lowercaseF:
            source.advance(&cursor)
            return UInt16(digit - .lowercaseA + 10)

        case .uppercaseA ... .uppercaseF:
            source.advance(&cursor)
            return UInt16(digit - .uppercaseA + 10)

        default:
            throw JsonError.badUnicodeEscapeSequence
        }
    }
}

extension JsonReader {
    public func skipNumber(at cursor: inout JsonCursor) throws {
        switch try source.asciiCodePoint(at: cursor) {
        case .hyphen:
            source.advance(&cursor)

        default:
            break
        }

        switch try source.asciiCodePoint(at: cursor) {
        case .digitZero:
            source.advance(&cursor)

        case .digitOne ... .digitNine:
            source.advance(&cursor)

            loop: while true {
                if source.isEnd(cursor) {
                    return
                }

                switch try source.asciiCodePoint(at: cursor) {
                case .digitZero ... .digitNine:
                    source.advance(&cursor)

                default:
                    break loop
                }
            }

        default:
            throw JsonError.unexpectedSymbol
        }

        if source.isEnd(cursor) {
            return
        }

        switch try source.asciiCodePoint(at: cursor) {
        case .period:
            source.advance(&cursor)

            switch try source.asciiCodePoint(at: cursor) {
            case .digitZero ... .digitNine:
                source.advance(&cursor)

            default:
                throw JsonError.unexpectedSymbol
            }

            loop: while true {
                if source.isEnd(cursor) {
                    return
                }

                switch try source.asciiCodePoint(at: cursor) {
                case .digitZero ... .digitNine:
                    source.advance(&cursor)

                default:
                    break loop
                }
            }

        default:
            break
        }

        if source.isEnd(cursor) {
            return
        }

        switch try source.asciiCodePoint(at: cursor) {
        case .lowercaseE, .uppercaseE:
            source.advance(&cursor)

            switch try source.asciiCodePoint(at: cursor) {
            case .plus, .hyphen:
                source.advance(&cursor)

            default:
                break
            }

            switch try source.asciiCodePoint(at: cursor) {
            case .digitZero ... .digitNine:
                source.advance(&cursor)

            default:
                throw JsonError.unexpectedSymbol
            }

            loop: while true {
                if source.isEnd(cursor) {
                    return
                }

                switch try source.asciiCodePoint(at: cursor) {
                case .digitZero ... .digitNine:
                    source.advance(&cursor)

                default:
                    break loop
                }
            }

        default:
            break
        }
    }

    public func readNumber(at cursor: inout JsonCursor) throws -> Double {
        let start = cursor
        try skipNumber(at: &cursor)

        if let result = try Double(source.uncheckedUnicodeString(from: start, to: cursor)) {
            return result
        } else {
            throw JsonError.badEscapeSequence
        }
    }
}

extension JsonReader {
    public func skipObject(at cursor: inout JsonCursor, depthLimit: Int = defaultDepthLimit) throws {
        while try nextObjectProperty(at: &cursor) {
            try skipObjectPropertyName(at: &cursor)
            try skipValue(at: &cursor, depthLimit: depthLimit)
        }
    }

    public func nextObjectProperty(at cursor: inout JsonCursor) throws -> Bool {
        switch try source.asciiCodePoint(at: cursor) {
        case .openingBrace:
            source.advance(&cursor)
            skipWhiteSpace(at: &cursor)

            switch try source.asciiCodePoint(at: cursor) {
            case .closingBrace:
                source.advance(&cursor)
                return false

            default:
                return true
            }

        default:
            skipWhiteSpace(at: &cursor)

            switch try source.asciiCodePoint(at: cursor) {
            case .comma:
                source.advance(&cursor)
                skipWhiteSpace(at: &cursor)
                return true

            case .closingBrace:
                source.advance(&cursor)
                return false

            default:
                throw JsonError.unexpectedSymbol
            }
        }
    }

    public func skipObjectPropertyName(at cursor: inout JsonCursor) throws {
        try skipString(at: &cursor)
        skipWhiteSpace(at: &cursor)
        try skipCodePoint(.colon, at: &cursor)
        skipWhiteSpace(at: &cursor)
    }

    public func readObjectPropertyName(at cursor: inout JsonCursor) throws -> String {
        let result = try readString(at: &cursor)
        skipWhiteSpace(at: &cursor)
        try skipCodePoint(.colon, at: &cursor)
        skipWhiteSpace(at: &cursor)
        return result
    }
}

extension JsonReader {
    public func skipArray(at cursor: inout JsonCursor, depthLimit: Int = defaultDepthLimit) throws {
        while try nextArrayElement(at: &cursor) {
            try skipValue(at: &cursor, depthLimit: depthLimit)
        }
    }

    public func nextArrayElement(at cursor: inout JsonCursor) throws -> Bool {
        switch try source.asciiCodePoint(at: cursor) {
        case .openingBracket:
            source.advance(&cursor)
            skipWhiteSpace(at: &cursor)

            switch try source.asciiCodePoint(at: cursor) {
            case .closingBracket:
                source.advance(&cursor)
                return false

            default:
                return true
            }

        default:
            skipWhiteSpace(at: &cursor)

            switch try source.asciiCodePoint(at: cursor) {
            case .comma:
                source.advance(&cursor)
                skipWhiteSpace(at: &cursor)
                return true

            case .closingBracket:
                source.advance(&cursor)
                return false

            default:
                throw JsonError.unexpectedSymbol
            }
        }
    }
}

extension JsonReader {
    public func skipTrue(at cursor: inout JsonCursor) throws {
        try skipCodePoint(.lowercaseT, at: &cursor)
        try skipCodePoint(.lowercaseR, at: &cursor)
        try skipCodePoint(.lowercaseU, at: &cursor)
        try skipCodePoint(.lowercaseE, at: &cursor)
    }

    public func skipFalse(at cursor: inout JsonCursor) throws {
        try skipCodePoint(.lowercaseF, at: &cursor)
        try skipCodePoint(.lowercaseA, at: &cursor)
        try skipCodePoint(.lowercaseL, at: &cursor)
        try skipCodePoint(.lowercaseS, at: &cursor)
        try skipCodePoint(.lowercaseE, at: &cursor)
    }

    public func readBool(at cursor: inout JsonCursor) throws -> Bool {
        switch try source.asciiCodePoint(at: cursor) {
        case .lowercaseT:
            try skipTrue(at: &cursor)
            return true

        case .lowercaseF:
            try skipFalse(at: &cursor)
            return false

        default:
            throw JsonError.unexpectedSymbol
        }
    }
}

extension JsonReader {
    public func skipNull(at cursor: inout JsonCursor) throws {
        try skipCodePoint(.lowercaseN, at: &cursor)
        try skipCodePoint(.lowercaseU, at: &cursor)
        try skipCodePoint(.lowercaseL, at: &cursor)
        try skipCodePoint(.lowercaseL, at: &cursor)
    }
}

extension JsonReader {
    private func skipWhiteSpace(at cursor: inout JsonCursor) {
        while true {
            if source.isEnd(cursor) {
                return
            }

            switch source.uncheckedAsciiCodePoint(at: cursor) {
            case .space,
                 .lineFeed,
                 .carrigeReturn,
                 .horizontalTab:
                source.advance(&cursor)

            default:
                return
            }
        }
    }

    @_transparent
    private func skipCodePoint(_ codePoint: UInt8, at cursor: inout JsonCursor) throws {
        if try source.asciiCodePoint(at: cursor) == codePoint {
            source.advance(&cursor)
        } else {
            throw JsonError.unexpectedSymbol
        }
    }
}
