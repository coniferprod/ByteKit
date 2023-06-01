public struct ByteKit {
    public private(set) var name = "ByteKit"

    public init() {
    }
}

public enum ParseError: Error {
    case invalidFormat
    case badLength
}
