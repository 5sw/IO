import Compression
import IO

struct CompressionError: Error {}

public struct Algorithm: RawRepresentable {
    public let rawValue: compression_algorithm

    public init(rawValue: compression_algorithm) {
        self.rawValue = rawValue
    }

    public static let zlib = Algorithm(rawValue: COMPRESSION_ZLIB)
}

public enum Operation {
    case compress
    case decompress
}

extension Operation: RawRepresentable {
    public var rawValue: compression_stream_operation {
        switch self {
        case .compress:
            return COMPRESSION_STREAM_ENCODE

        case .decompress:
            return COMPRESSION_STREAM_DECODE
        }
    }

    public init?(rawValue: compression_stream_operation) {
        switch (rawValue) {
        case COMPRESSION_STREAM_ENCODE: self = .compress
        case COMPRESSION_STREAM_DECODE: self = .decompress
        default: return nil
        }
    }
}

@available(OSX 10.11, *)
public class CompressionSource<Source: BufferedSource >: IO.Source {
    let source: Source
    var compression: compression_stream

    var atEnd = false

    deinit {
        compression_stream_destroy(&compression)
    }

    public init(source: Source, operation: Operation, algorithm: Algorithm) throws {
        self.source = source

        compression = compression_stream(dst_ptr: UnsafeMutablePointer(bitPattern: -1)!, dst_size: 0, src_ptr: UnsafeMutablePointer(bitPattern: -1)!, src_size: 0, state: nil)

        guard compression_stream_init(&compression, operation.rawValue, algorithm.rawValue) == COMPRESSION_STATUS_OK else {
            throw CompressionError()
        }
    }

    public func read(buffer: UnsafeMutableRawBufferPointer) throws -> Int {
        guard !atEnd else { return 0 }

        return try source.read { sourceBuffer, sourceUsed in
            compression.src_ptr = sourceBuffer.baseAddress!.assumingMemoryBound(to: UInt8.self)
            compression.src_size = sourceBuffer.count
            let inputStart = compression.src_ptr

            compression.dst_ptr = buffer.baseAddress!.assumingMemoryBound(to: UInt8.self)
            compression.dst_size = buffer.count
            let outputStart = compression.dst_ptr

            let flags: UInt32 = 0
            let status = compression_stream_process(&compression, Int32(bitPattern: flags))
            guard status != COMPRESSION_STATUS_ERROR else {
                throw CompressionError()
            }

            atEnd = status == COMPRESSION_STATUS_END
            sourceUsed = compression.src_ptr - inputStart

            return compression.dst_ptr - outputStart
        }
    }
}

