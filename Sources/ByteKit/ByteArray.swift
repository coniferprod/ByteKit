import Foundation

/// Convenience type alias for an array of bytes.
public typealias ByteArray = [Byte]

/// Order of nybbles in a nybblified byte: 
/// low nybble or high nybble first.
public enum NybbleOrder {
    case lowFirst
    case highFirst
}

// MARK: - Nybble-related extensions to `ByteArray`.

extension ByteArray {
    /// Returns a nybblified version of this byte array. 
    /// The nybble order is determined by `order`.
    public func nybblified(order: NybbleOrder = .highFirst) -> ByteArray {
        var result = ByteArray()
        self.forEach { b in
            let n = b.nybbles
            if order == .highFirst {
                result.append(n.high)
                result.append(n.low)
            }
            else {
                result.append(n.low)
                result.append(n.high)
            }
        }
        return result
    }
    
    /// Returns a denybblified version of this byte array, 
    /// or `nil` if the length of the array is odd.
    public func denybblified(order: NybbleOrder = .highFirst) -> ByteArray? {
        guard 
            self.count % 2 == 0
        else {
            return nil
        }
        
        var result = ByteArray()
        
        var index = 0
        var offset = 0
        let count = self.count / 2
        while index < count {
            result.append(order == .highFirst ?
                Byte(nybbles: (high: self[offset], low: self[offset + 1])) :
                Byte(nybbles: (high: self[offset + 1], low: self[offset])))
            index += 1
            offset += 2
        }

        return result
    }
}

extension Data {
    /// Returns the contents of this `Data` object as a byte array.
    public var bytes: ByteArray {
        var byteArray = ByteArray(repeating: 0, count: self.count)
        self.copyBytes(to: &byteArray, count: self.count)
        return byteArray
    }
}

extension String {
    /// Splits the string into parts of size `length`.
    public func split(by length: Int) -> [String] {
        guard 
            length > 0
        else {
            return []
        }
        
        var start: Index!
        var end = self.startIndex
        return (0...self.count / length).map { _ in
            start = end
            end = self.index(start, offsetBy: length, limitedBy: self.endIndex) ?? self.endIndex
            return String(self[start..<end])
        }
    }

    /// Returns `true` if the string contains whitespace,
    /// `false` otherwise.
    public var containsWhitespace: Bool {
        return self.rangeOfCharacter(from: .whitespacesAndNewlines) != nil
    }
}

extension ByteArray {
    /// Parse a hex string into a byte array. After stripping whitespace, 
    /// the string must be empty or have an even number of hex digits.
    /// These are converted into bytes and appended to the resulting byte array.
    public static func parse(from: String) -> Result<ByteArray, ParseError> {
        // If the string is initially empty, just return an empty array:
        guard 
            from.count != 0
        else {
            return .success(ByteArray())
        }

        var hexStrings = [String]()
        if from.containsWhitespace {
            hexStrings = from.components(separatedBy: .whitespaces)
                .filter { $0.count != 0 }
        }
        else {
            hexStrings = from.split(by: 2).filter { $0.count != 0 }
        }
        
        var result = ByteArray()
        
        for hs in hexStrings {
            if hs.count != 2 {
                return .failure(.badLength)
            }
                        
            if let b = Byte(hs, radix: 16) {
                result.append(b)
            }
            else {
                return .failure(.invalidFormat)
            }
        }
        
        return .success(result)
    }
}

// MARK: - ByteArray utilities

extension ByteArray {
    /// Combines this byte array with `other`, alternating the elements from both,
    /// starting with this one. Note that if this array and `other` have different lengths,
    /// the result will be the same length as the shorter one (because of `zip`).
    public func interleave(with other: ByteArray) -> ByteArray {
        return zip(self, other).flatMap({ [$0, $1] })
    }
    
    /// Deinterleaves the contents of this byte array into two separate arrays.
    /// If the array has an odd number of elements, the second array will be
    /// shorter than the first.
    public func deinterleave() -> (ByteArray, ByteArray) {
        var first = ByteArray()
        var second = ByteArray()
        
        for (index, element) in self.enumerated() {
            if index % 2 == 0 {
                first.append(element)
            }
            else {
                second.append(element)
            }
        }
        
        return (first, second)
    }
}

// MARK: - ByteArray unpacking

/// Values used by the BytArray's `unpack` method when interpreting
/// the content.
public enum Value: Equatable {
    case boolean(Bool)
    case byte(Byte)
    case character(Character)
    case shortInteger(Int16)
    case unsignedShortInteger(UInt16)
    case integer(Int32)
    case unsignedInteger(UInt32)
    case longInteger(Int64)
    case unsignedLongInteger(UInt64)
}

func doInt16(_ b1: Byte, _ b2: Byte) -> Int16 {
    (Int16(b1) << 8) | Int16(b2)
}

func doUInt16(_ b1: Byte, _ b2: Byte) -> UInt16 {
    (UInt16(b1) << 8) | UInt16(b2)
}

func doUInt32(_ b1: Byte, _ b2: Byte, _ b3: Byte, _ b4: Byte) -> UInt32 {
    (UInt32(b1) << 24) | (UInt32(b2) << 16) | (UInt32(b3) << 8) | UInt32(b4)
}

func doInt32(_ b1: Byte, _ b2: Byte, _ b3: Byte, _ b4: Byte) -> Int32 {
    (Int32(b1) << 24) | (Int32(b2) << 16) | (Int32(b3) << 8) | Int32(b4)
}

// TODO: doUInt64 and doInt64 functions

extension ByteArray {
    /// Unpacks the contents of this `ByteArray` into values according to the format.
    /// Loosely emulates Python's `struct`module, but is less comprehensive.
    public func unpack(format: String) -> Result<[Value], ParseError> {
        guard
            format.count != 0
        else {
            return .failure(.invalidFormat)
        }
        
        var values = [Value]()
        var offset = 0
        var byte1: Byte
        var byte2: Byte
        var byte3: Byte
        var byte4: Byte
        
        for character in format {
            var value: Value
            switch character {
            case " ":
                continue
            case "?":
                byte1 = self[offset]
                value = .boolean(byte1 != 0 ? true : false)
                offset += 1
            case "b":
                value = .byte(self[offset])
                offset += 1
            case "c":
                value = .character(Character(Unicode.Scalar(self[offset])))
                offset += 1
            case "h":
                byte1 = self[offset]
                byte2 = self[offset + 1]
                value = .shortInteger(doInt16(byte1, byte2))
                offset += 2
            case "H":
                byte1 = self[offset]
                byte2 = self[offset + 1]
                value = .unsignedShortInteger(doUInt16(byte1, byte2))
                offset += 2
            case "I":
                byte1 = self[offset]
                byte2 = self[offset + 1]
                byte3 = self[offset + 2]
                byte4 = self[offset + 3]
                value = .unsignedInteger(doUInt32(byte1, byte2, byte3, byte4))
                offset += 4
            case "i":
                byte1 = self[offset]
                byte2 = self[offset + 1]
                byte3 = self[offset + 2]
                byte4 = self[offset + 3]
                value = .integer(doInt32(byte1, byte2, byte3, byte4))
                offset += 4
            default:
                return .failure(.invalidFormat)
            }
            
            values.append(value)
        }
        
        return .success(values)
    }
}
