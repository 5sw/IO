protocol Sink {
    func write(buffer: UnsafeRawBufferPointer) throws -> Int
}
