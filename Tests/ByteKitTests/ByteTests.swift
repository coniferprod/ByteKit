import XCTest
@testable import ByteKit

final class ByteTests: XCTestCase {
    func test_highNybble() {
        let b: Byte = 0xa4
        XCTAssertEqual(b.highNybble, 0x0a)
    }

    func test_lowNybble() {
        let b: Byte = 0xa4
        XCTAssertEqual(b.lowNybble, 0x04)
    }

    func test_nybblesFromByte() {
        let b: Byte = 0xa4
        let nybbles = b.nybbles
        XCTAssertEqual(nybbles.high, 0x0a)
        XCTAssertEqual(nybbles.low, 0x04)
    }
    
    func test_initFromNybbles() {
        let nybbles: Nybbles = (high: 0x0a, low: 0x04)
        let b = Byte(nybbles: nybbles)
        XCTAssertEqual(b, 0xa4)
    }
        
    func test_byteFromBitArray() {
        let ba: BitArray = [.zero, .zero, .one, .one, .one, .zero, .zero, .zero]
        let b = ba.toByte()
        XCTAssertEqual(b, 0b00011100)
    }
    
    func test_bitArrayFromByte() {
        let b: Byte = 0b00011100
        let bs = b.toBitArray()
        XCTAssertEqual(bs, [.zero, .zero, .one, .one, .one, .zero, .zero, .zero])
    }
    
    func test_replaceBits() {
        var b: Byte = 0b0101_0110
        b.replaceBits(2...5, with: 0b1010)
        XCTAssertEqual(b, 0b0110_1010)
    }
}
