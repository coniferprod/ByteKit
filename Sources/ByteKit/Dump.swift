import Foundation

public struct HexDumpConfiguration {
    public var bytesPerLine: Int { 16 }
    public var uppercased: Bool { true }
    
    /// Flags to control the inclusion of hex dump features.
    public struct IncludeOptions: OptionSet {
        public let rawValue: Byte

        /// Include the byte offset in the dump.
        public static let offset = IncludeOptions(rawValue: 1)
        
        /// Include printable characters at the end of the dump row.
        public static let printableCharacters = IncludeOptions(rawValue: 1 << 1)
        
        /// Insert a gap between the two halves of a dump line.
        public static let midLineGap = IncludeOptions(rawValue: 1 << 2)
        
        public init(rawValue: Byte) {
            self.rawValue = rawValue
        }
    }
    
    /// What features to include in the dump. See `IncludeOptions`.
    public var includeOptions: IncludeOptions
    
    /// Standard hex dump configuration.
    public static let standard = HexDumpConfiguration(includeOptions: [.offset, .printableCharacters, .midLineGap])
    
    /// Simple hex dump configuration.
    public static let simple = HexDumpConfiguration(includeOptions: [])
}

/// Source dump configuration parameters.
public struct SourceDumpConfiguration {
    /// How many bytes per line.
    public var bytesPerLine: Int { 16 }
    
    /// Are hex digits uppercased or not.
    public var uppercased: Bool { false }
    
    /// How many spaces to indent each data row.
    public var indent: Int { 4 }

    /// Name of the variable in the generated source code.
    public var variableName: String { "data" }
    
    /// Type of the variable in the generated source code.
    public var typeName: String { "[UInt8]"}
    
    /// Standard source dump configuration.
    public static let standard = SourceDumpConfiguration()
}

extension ByteArray {
    /// Returns a string containing a hex dump of this byte array.
    /// The dump can be configured with the `configuration` parameter.
    public func hexDump(configuration: HexDumpConfiguration = HexDumpConfiguration.standard) -> String {
        var lines = [String]()

        let chunks = self.chunked(into: Int(configuration.bytesPerLine))
        var offset = 0
        let hexModifier = configuration.uppercased ? "X" : "x"
        let midChunkIndex = configuration.bytesPerLine / 2
        for chunk in chunks {
            var line = ""
            var printableCharacters = ""

            if configuration.includeOptions.contains(.offset) {
                line += String(format: "%08\(hexModifier)", offset)
                line += ": "
            }
        
            for (index, byte) in chunk.enumerated() {
                line += String(format: "%02\(hexModifier)", byte)
                line += " "
                
                if index + 1 == midChunkIndex {
                    if configuration.includeOptions.contains(.midLineGap) {
                        line += " "
                    }
                }
                
                let ch = Character(Unicode.Scalar(byte))
                printableCharacters += ch.isPrintable ? String(ch) : "."
            }

            if configuration.includeOptions.contains(.printableCharacters) {
                // Insert spaces for each unused byte slot in the chunk
                var bytesLeft = configuration.bytesPerLine - chunk.count
                while bytesLeft >= 0 {
                    line += "   "  // this is for the byte, to replace "XX "
                    printableCharacters += " "  // handle characters too, even if we don't use them
                    bytesLeft -= 1
                }

                line += " "
                line += printableCharacters
            }
            
            lines.append(line.trimmingCharacters(in: .whitespaces))
            offset += configuration.bytesPerLine
        }
        
        return lines.joined(separator: "\n")
    }

    /// Returns a Swift source code representation of this byte array.
    /// The format of the dump is controlled by the `configuration` parameter.
    public func sourceDump(configuration: SourceDumpConfiguration = .standard) -> String {
        var lines = [String]()
        
        lines.append("let \(configuration.variableName): \(configuration.typeName) = [")

        let chunks = self.chunked(into: configuration.bytesPerLine)
        let hexModifier = configuration.uppercased ? "X" : "x"
        for chunk in chunks {
            var line = String(repeating: " ", count: configuration.indent)
            for byte in chunk {
                line.append("0x\(String(format: "%02\(hexModifier)", byte)), ")
            }
            lines.append(line)
        }

        lines.append("]")
        
        return lines.joined(separator: "\n")
    }
}

extension Array {
    /// Splits this array into chunks of `size` elements or less.
    public func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

extension Character {
    /// Returns `true` if this character is a printable ASCII character,
    /// `false` otherwise.
    public var isPrintable: Bool {
        if let v = self.asciiValue {
            if v >= 0x20 && v < 0x7f {
                return true
            }
        }
        return false
    }
}
