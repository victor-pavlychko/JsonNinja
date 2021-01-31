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

extension JsonWriter {
    public mutating func writeArray(_ writeContents: (ArrayWriter) throws -> Void) rethrows {
        writeArrayBegin()

        try withUnsafeMutablePointer(to: &self) {
            try writeContents(ArrayWriter(owner: $0))
        }

        writeArrayEnd()
    }

    @frozen public struct ArrayWriter {
        internal let owner: UnsafeMutablePointer<JsonWriter>

        internal init(owner: UnsafeMutablePointer<JsonWriter>) {
            self.owner = owner
        }

        public func writeElement(_ writeContents: (inout JsonWriter) throws -> Void) rethrows {
            owner.pointee.writeArrayElement()
            try writeContents(&owner.pointee)
        }

        public func writeString(_ value: String) {
            writeElement { writer in
                writer.writeString(value)
            }
        }

        public func writeNumber<Number>(_ value: Number) where Number: BinaryInteger & LosslessStringConvertible {
            writeElement { writer in
                writer.writeNumber(value)
            }
        }

        public func writeNumber<Number>(_ value: Number) where Number: BinaryFloatingPoint & LosslessStringConvertible {
            writeElement { writer in
                writer.writeNumber(value)
            }
        }

        public func writeArray(_ writeContents: (ArrayWriter) throws -> Void) rethrows {
            try writeElement { writer in
                try writer.writeArray(writeContents)
            }
        }

        public func writeObject(_ writeContents: (ObjectWriter) throws -> Void) rethrows {
            try writeElement { writer in
                try writer.writeObject(writeContents)
            }
        }

        public func writeBool(_ value: Bool) {
            writeElement { writer in
                writer.writeBool(value)
            }
        }

        public func writeNull() {
            writeElement { writer in
                writer.writeNull()
            }
        }
    }
}

extension JsonWriter {
    public mutating func writeObject(_ writeContents: (ObjectWriter) throws -> Void) rethrows {
        writeObjectBegin()

        try withUnsafeMutablePointer(to: &self) {
            try writeContents(ObjectWriter(owner: $0))
        }
        writeObjectEnd()
    }

    @frozen public struct ObjectWriter {
        internal let owner: UnsafeMutablePointer<JsonWriter>

        internal init(owner: UnsafeMutablePointer<JsonWriter>) {
            self.owner = owner
        }

        public func writeProperty(name: String, writeContents: (inout JsonWriter) throws -> Void) rethrows {
            owner.pointee.writeObjectProperty(name: name)
            try writeContents(&owner.pointee)
        }

        public func writeString(_ value: String, name: String) {
            writeProperty(name: name) { writer in
                writer.writeString(value)
            }
        }

        public func writeNumber<Number>(_ value: Number, name: String) where Number: BinaryInteger & LosslessStringConvertible {
            writeProperty(name: name) { writer in
                writer.writeNumber(value)
            }
        }

        public func writeNumber<Number>(_ value: Number, name: String) where Number: BinaryFloatingPoint & LosslessStringConvertible {
            writeProperty(name: name) { writer in
                writer.writeNumber(value)
            }
        }

        public func writeArray(name: String, writeContents: (ArrayWriter) throws -> Void) rethrows {
            try writeProperty(name: name) { writer in
                try writer.writeArray(writeContents)
            }
        }

        public func writeObject(name: String, writeContents: (ObjectWriter) throws -> Void) rethrows {
            try writeProperty(name: name) { writer in
                try writer.writeObject(writeContents)
            }
        }

        public func writeBool(_ value: Bool, name: String) {
            writeProperty(name: name) { writer in
                writer.writeBool(value)
            }
        }

        public func writeNull(name: String) {
            writeProperty(name: name) { writer in
                writer.writeNull()
            }
        }
    }
}
