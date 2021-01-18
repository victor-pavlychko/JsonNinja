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

public protocol AsciiCodePoint: BinaryInteger { }

extension UInt8: AsciiCodePoint { }

extension AsciiCodePoint {
    @_transparent internal static var backspace: Self { 0x08 }
    @_transparent internal static var horizontalTab: Self { 0x09 }
    @_transparent internal static var lineFeed: Self { 0x0A }
    @_transparent internal static var formFeed: Self { 0x0C }
    @_transparent internal static var carrigeReturn: Self { 0x0D }

    @_transparent internal static var space: Self { 0x20 }
    @_transparent internal static var doubleQuotes: Self { 0x22 }
    @_transparent internal static var plus: Self { 0x2B }
    @_transparent internal static var comma: Self { 0x2C }
    @_transparent internal static var hyphen: Self { 0x2D }
    @_transparent internal static var period: Self { 0x2E }
    @_transparent internal static var slash: Self { 0x2F }

    @_transparent internal static var digitZero: Self { 0x30 }
    @_transparent internal static var digitOne: Self { 0x31 }
    @_transparent internal static var digitNine: Self { 0x39 }

    @_transparent internal static var colon: Self { 0x3A }

    @_transparent internal static var uppercaseA: Self { 0x41 }
    @_transparent internal static var uppercaseE: Self { 0x45 }
    @_transparent internal static var uppercaseF: Self { 0x46 }

    @_transparent internal static var openingBracket: Self { 0x5B }
    @_transparent internal static var backslash: Self { 0x5C }
    @_transparent internal static var closingBracket: Self { 0x5D }

    @_transparent internal static var lowercaseA: Self { 0x61 }
    @_transparent internal static var lowercaseB: Self { 0x62 }
    @_transparent internal static var lowercaseE: Self { 0x65 }
    @_transparent internal static var lowercaseF: Self { 0x66 }
    @_transparent internal static var lowercaseL: Self { 0x6C }
    @_transparent internal static var lowercaseN: Self { 0x6E }
    @_transparent internal static var lowercaseR: Self { 0x72 }
    @_transparent internal static var lowercaseS: Self { 0x73 }
    @_transparent internal static var lowercaseT: Self { 0x74 }
    @_transparent internal static var lowercaseU: Self { 0x75 }

    @_transparent internal static var openingBrace: Self { 0x7B }
    @_transparent internal static var closingBrace: Self { 0x7D }
}
