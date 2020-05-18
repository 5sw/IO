import Compression
import IO

struct CompressionError: Error {}

@available(OSX 10.11, *)
class ZlibReader2<Source: BufferedSource >: IO.Source {
    let source: Source
    var compression: compression_stream

    var atEnd = false

    deinit {
        compression_stream_destroy(&compression)
    }

    init(source: Source) throws {
        self.source = source

        compression = compression_stream(dst_ptr: UnsafeMutablePointer(bitPattern: 1)!, dst_size: 0, src_ptr: UnsafeMutablePointer(bitPattern: 1)!, src_size: 0, state: nil)

        guard compression_stream_init(&compression, COMPRESSION_STREAM_DECODE, COMPRESSION_ZLIB) == COMPRESSION_STATUS_OK else {
            throw CompressionError()
        }
    }

    func read(buffer: UnsafeMutableRawBufferPointer) throws -> Int {
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

