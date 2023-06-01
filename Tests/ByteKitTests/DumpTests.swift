import XCTest
@testable import ByteKit

final class DumpTests: XCTestCase {
    func test_simpleHexDump() throws {
        let data: ByteArray = [0x1A, 0xBC, 0xDE, 0xF0]
        XCTAssertEqual(data.hexDump(configuration: .simple), "1A BC DE F0")
    }
    
    func test_standardHexDump() throws {
        let data: ByteArray = [
            0x01, 0x12, 0x23, 0x34, 0x45, 0x56, 0x67, 0x78,
            0x89, 0x9a, 0xab, 0xbc, 0xcd, 0xde, 0xef
        ]
        
        let result = data.hexDump(configuration: .standard)
        
        let expected = "00000000: 01 12 23 34 45 56 67 78  89 9A AB BC CD DE EF        ..#4EVgx......."
        
        XCTAssertEqual(result, expected)
    }
    
    func test_standardSourceDump() throws {
        let data: ByteArray = [
            0x01, 0x12, 0x23, 0x34, 0x45, 0x56, 0x67, 0x78,
            0x89, 0x9a, 0xab, 0xbc, 0xcd, 0xde, 0xef
        ]
        
        let result = data.sourceDump(configuration: .standard)
        
        let expected = """
let data: [UInt8] = [
    0x01, 0x12, 0x23, 0x34, 0x45, 0x56, 0x67, 0x78, 0x89, 0x9a, 0xab, 0xbc, 0xcd, 0xde, 0xef, 
]
"""
        XCTAssertEqual(result, expected)
    }
}
