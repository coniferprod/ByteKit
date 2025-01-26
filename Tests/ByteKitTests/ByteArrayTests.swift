import XCTest
@testable import ByteKit

final class ByteArrayTests: XCTestCase {
    func test_nybblified_highFirst() {
        let ba = ByteArray([0xa4, 0xb5, 0xc6])
        XCTAssertEqual(ba.nybblified(), ByteArray([0x0a, 0x04, 0x0b, 0x05, 0x0c, 0x06]))
    }
    
    func test_nybblified_lowFirst() {
        let ba = ByteArray([0xa4, 0xb5, 0xc6])
        XCTAssertEqual(ba.nybblified(order: .lowFirst), ByteArray([0x04, 0x0a, 0x05, 0x0b, 0x06, 0x0c]))
    }
    
    func test_denybblified_notEven() {
        let ba = ByteArray([0x0a, 0x04, 0x0b, 0x05, 0x0c])  // byte count is odd
        XCTAssertNil(ba.denybblified())  // should return nil
    }
    
    func test_denybblified_highFirst() {
        let ba = ByteArray([0x0a, 0x04, 0x0b, 0x05, 0x0c, 0x06])
        XCTAssertEqual(ba.denybblified(), ByteArray([0xa4, 0xb5, 0xc6]))
    }
    
    func test_denybblified_lowFirst() {
        let ba = ByteArray([0x0a, 0x04, 0x0b, 0x05, 0x0c, 0x06])
        XCTAssertEqual(ba.denybblified(order: .lowFirst), ByteArray([0x4a, 0x5b, 0x6c]))
    }
    
    func test_denybblified_empty() {
        let ba = ByteArray()
        XCTAssertEqual(ba.denybblified()!.count, ba.count)
    }
    
    func test_parseFromHexString_empty() {
        switch ByteArray.parse(from: "") {
        case .success(let ba):
            XCTAssertEqual(ba, ByteArray())
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
    
    func test_parseFromHexString_withWhitespace() {
        let hexString = "  12 34 56   78 9A AB BC  CD DE EF   F0 "
        switch ByteArray.parse(from: hexString) {
        case .success(let ba):
            XCTAssertEqual(ba, [0x12, 0x34, 0x56, 0x78, 0x9a, 0xab, 0xbc, 0xcd, 0xde, 0xef, 0xf0])
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
    
    func test_parseFromHexString_noWhitespace() {
        let hexString = "123456789AABBCCDDEEFF0"
        switch ByteArray.parse(from: hexString) {
        case .success(let ba):
            XCTAssertEqual(ba, [0x12, 0x34, 0x56, 0x78, 0x9a, 0xab, 0xbc, 0xcd, 0xde, 0xef, 0xf0])
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
    
    func test_interleave() {
        let first: ByteArray = [0x01, 0x02, 0x03]
        let second: ByteArray = [0x04, 0x05, 0x06]
        let result = first.interleave(with: second)
        XCTAssertEqual(result, [0x01, 0x04, 0x02, 0x05, 0x03, 0x06])
    }
    
    func test_deinterleave() {
        let ba: ByteArray = [0x01, 0x04, 0x02, 0x05, 0x03, 0x06]
        let (first, second) = ba.deinterleave()
        XCTAssertEqual(first, [0x01, 0x02, 0x03])
        XCTAssertEqual(second, [0x04, 0x05, 0x06])
    }
    
    func test_deinterleave_odd() {
        let ba: ByteArray = [0x01, 0x04, 0x02, 0x05, 0x03]
        let (first, second) = ba.deinterleave()
        XCTAssertEqual(first, [0x01, 0x02, 0x03])
        XCTAssertEqual(second, [0x04, 0x05])
    }
    
    func test_doInt16_Positive() {
        let b1: Byte = 0x12
        let b2: Byte = 0x34
        XCTAssertEqual(doInt16(b1, b2), 0x1234)
    }

    func test_doInt16_Negative() {
        let b1: Byte = 0x89
        let b2: Byte = 0xAB
        XCTAssertEqual(doInt16(b1, b2), -0x7655)
    }
    
    func test_doUInt16() {
        let b1: Byte = 0x12
        let b2: Byte = 0x34
        XCTAssertEqual(doUInt16(b1, b2), 0x1234)
    }
    
    func test_unpack() {
        let data: ByteArray = [0x12, 0x34, 0x41, 0x42, 0x89, 0xAB, 0xCA, 0xFE, 0xBA, 0xBE, 0x01, 0xCA, 0xFE, 0xBA, 0xBE]
        let format = "Hc bhI?i"  // UInt16, Character, ignorable space, Byte, Int16 (negative), UInt32, Bool, Int32
        switch data.unpack(format: format) {
        case .success(let values):
            XCTAssertEqual(values,
                           [.unsignedShortInteger(0x1234),
                            .character("A"),
                            .byte(0x42),
                            .shortInteger(-0x7655),
                            .unsignedInteger(0xCAFEBABE),
                            .boolean(true),
                            .integer(-0x35014542)])
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
    
    func test_unpack_invalidFormat() {
        let data: ByteArray = [0x12, 0x34]
        let format = "xH"  // bad, UInt16
        let result = data.unpack(format: format)
        XCTAssertEqual(result, .failure(.invalidFormat))
    }
}
