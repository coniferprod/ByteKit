import Foundation

/// Convenience type alias for an array of bytes.
public typealias ByteArray = [Byte]

/// Order of nybbles in a nybblified byte: low nybble or high nybble first.
public enum NybbleOrder {
    case lowFirst
    case highFirst
}

// MARK: - Nybble-related extensions to `ByteArray`.

extension ByteArray {
    /// Returns a nybblified version of this byte array. The nybble order is determined by `order`.
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
    
    /// Returns a denybblified version of this byte array, or `nil` if the length of the array is odd.
    public func denybblified(order: NybbleOrder = .highFirst) -> ByteArray? {
        guard self.count % 2 == 0 else {
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
