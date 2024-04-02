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
