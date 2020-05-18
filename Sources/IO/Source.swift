public protocol Source {
    func read(buffer: UnsafeMutableRawBufferPointer) throws -> Int
}

public protocol BufferedSource: Source {
    @discardableResult
    func read<T>(_ closure: (UnsafeRawBufferPointer, inout Int) throws -> T) throws -> T
}

extension BufferedSource {
    func read(buffer: UnsafeMutableRawBufferPointer) throws -> Int {
        guard let base = buffer.baseAddress, buffer.count > 0  else { return 0 }

        return try read { source, copied in
            copied = min(source.count, buffer.count)
            base.copyMemory(from: source.baseAddress!, byteCount: copied)
            return copied
        }
    }
}
