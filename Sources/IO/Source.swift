public protocol Source {
    func read(buffer: UnsafeMutableRawBufferPointer) throws -> Int
}

public protocol BufferedSource: Source {
    @discardableResult
    func read<T>(_ closure: (UnsafeRawBufferPointer, inout Int) throws -> T) throws -> T
}

public extension BufferedSource {
    func read(buffer: UnsafeMutableRawBufferPointer) throws -> Int {
        guard let base = buffer.baseAddress, buffer.count > 0  else { return 0 }

        return try read { source, copied in
            copied = min(source.count, buffer.count)
            base.copyMemory(from: source.baseAddress!, byteCount: copied)
            return copied
        }
    }

    func copyAll<Destination: Sink>(to sink: Destination) throws -> Int {
        var totalWritten = 0

        while try read({ buffer, written -> Bool in
            guard buffer.count > 0 else {
                return false
            }

            written = try sink.write(buffer: buffer)
            totalWritten += written
            
            return true
        }) {}

        return totalWritten
    }

    func peekByte() throws -> UInt8? {
        return try read { buffer, _ in
            guard buffer.count > 0 else {
                return nil
            }

            return buffer.load(as: UInt8.self)
        }
    }

    func read<T: FixedWidthInteger>(as: T.Type) throws -> T? {
        return try read { buf, actual in
            guard buf.count >= MemoryLayout<T>.size else {
                return nil
            }

            var result = T()
            actual = withUnsafeMutableBytes(of: &result) { dest in
                buf.copyBytes(to: dest)
            }
            return result
        }
    }
}
