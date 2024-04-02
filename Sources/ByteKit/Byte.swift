import Foundation

/// Convenience type alias for a byte.
public typealias Byte = UInt8

/// Convenience type alias for a named tuple representing the nybbles of a byte.
public typealias Nybbles = (high: Byte, low: Byte)

/// Enumerated type for bit values.
/// Raw values are automatically assigned starting from zero.
/// The type of the raw value is `Byte` for convenience.
public enum Bit: Byte {
    case zero
    case one
}

/// Convenience type alias for an array of bits.
public typealias BitArray = [Bit]

// MARK: - Bit-related extensions to Byte

extension Byte {
    /// Returns `true` if the bit at `position` is set, `false` otherwise.
    public func isBitSet(_ position: Int) -> Bool {
        assert((0...7).contains(position), "Bit position must be between 0 and 7")
        return (self & (1 << position)) != 0
    }
    
    /// Sets the bit at `position`.
    public mutating func setBit(_ position: Int) {
        assert((0...7).contains(position), "Bit position must be between 0 and 7")
        self |= 1 << position
    }

    /// Clears the bit at `position`.
    public mutating func clearBit(_ position: Int) {
        assert((0...7).contains(position), "Bit position must be between 0 and 7")
        self &= ~(1 << position)
    }
    
    /// Replaces the bits in `range` of this byte with with `value`.
    public mutating func replaceBits(_ range: ClosedRange<Int>, with value: Byte) {
        var allBits = self.toBitArray()  // always has eight bits
        let valueBitString = String(value, radix: 2)  // convert to find minimum length
        let valueBits = value.toBitArray().dropLast(valueBitString.count)  // drop trailing zero bytes
        allBits.replaceSubrange(range, with: valueBits)  // replace the bit field
        self = allBits.toByte()
    }
    
    /// Returns the value of the bit field of `length` bits from the `start` position.
    /// If the bit field would extend beyond eight bits, returns only the rest of the bits up to eight.
    /// For example, `extractBits(start: 3, length: 2)` would return the value of bits 3 and 4.
    public func extractBits(start: Int, length: Int) -> Byte {
        assert((0...7).contains(start), "Bit field start must be between 0 and 7")
        assert((0...7).contains(length), "Bit field length must be between 0 and 7")
        
        let end = Swift.min(start + length - 1, 7)
        
        // Convert the byte into a bit string of exactly 8 characters 
        // (pad to zero from left as necessary)
        let allBits = self.toBitArray()
        let fieldBits = allBits[start...end]

        let byte = Byte(bits: BitArray(fieldBits))
        return byte
    }
    
    /// Gets a binary representation of this byte.
    /// If `padded` is `true`, the string is padded from 
    /// left with zeros, up to eight digits.
    public func toBinaryString(padded: Bool = true) -> String {
        let result = String(self, radix: 2)
        if padded {
            let pad = String(repeating: Character("0"), count: (8 - result.count))
            return pad + result
        }
        return result
    }
    
    /// Gets a hexadecimal representation of this byte.
    /// Uses at least two hex digits, padded with zeros 
    /// from left if more.
    public func toHexString(digits: Int = 2, uppercase: Bool = false) -> String {
        assert(digits >= 2, "Must use two or more hex digits")
        return String(format: "%0\(digits)x", self)
    }
}

// MARK: - Nybble-related extensions to Byte

extension Byte {
    /// Returns the high nybble (top four bits) of this byte.
    public var highNybble: Byte {
        return (self & 0xf0) >> 4
    }
    
    /// Returns the low nybble (bottom foor bits) of this byte.
    public var lowNybble: Byte {
        return self & 0x0f
    }
    
    /// Returns the high and low nybbles of this byte as a named tuple.
    public var nybbles: Nybbles {
        return (high: self.highNybble, low: self.lowNybble)
    }
    
    /// Initializes a byte from two nybbles.
    public init(nybbles: Nybbles) {
        self = (nybbles.high << 4) | (nybbles.low)
    }
}

// MARK: - Bit and BitArray extensions

extension Bit: CustomStringConvertible {
    /// Returns a string representation of this bit.
    public var description: String {
        switch self {
        case .one:
            return "1"
        case .zero:
            return "0"
        }
    }
}

extension BitArray {
    /// Converts the bits in this array to a byte.
    public func toByte() -> Byte {
        // Ensure that there are exactly eight bytes
        // in the array before converting:
        
        var bits: BitArray
        if self.count > 8 {
            bits = BitArray(self.prefix(8))
        }
        else if self.count < 8 {
            bits = self
            while bits.count < 8 {
                bits.append(.zero)
            }
        }
        else {
            bits = self
        }
        
        var value: Byte = 0x00  // start with all bits zero
        
        // Take only the first eight bits, in case there are more.
        for (position, bit) in bits.enumerated() {
            if bit == .one {
                value.setBit(position)
            }
        }
        
        return value
    }
}

extension Byte {
    /// Converts this byte into a `BitArray`, 
    /// with exactly eight Bit objects,
    /// bit #0 first and bit #7 last.
    public func toBitArray() -> BitArray {
        var allBits = BitArray(repeating: .zero, count: 8)
        for i in 0..<8 {
            if self.isBitSet(i) {
                allBits[i] = .one
            }
        }
        return allBits
    }
    
    /// Initializes a byte from an array of bits.
    public init(bits: BitArray) {
        self = bits.toByte()
    }
}
