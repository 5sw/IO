import Darwin
import Foundation

struct FileHandle: Source, Sink {
    let handle: Int32

    static let stdin = FileHandle(handle: STDIN_FILENO)
    static let stdout = FileHandle(handle: STDOUT_FILENO)
    static let stderr = FileHandle(handle: STDERR_FILENO)

    init(handle: Int32) {
        self.handle = handle
    }

    init(url: URL, flag: Int32 = O_RDONLY) throws {
        guard url.isFileURL else {
            throw IOError.invalidURL
        }

        handle = try url.withUnsafeFileSystemRepresentation { ptr in
            guard let ptr = ptr else {
                throw IOError.invalidURL
            }

            let handle = open(ptr, flag)
            guard handle > 0 else {
                throw IOError.errno
            }

            return handle
        }
    }

    func close() {
        Darwin.close(handle)
    }

    func write(buffer: UnsafeRawBufferPointer) throws -> Int {
        guard let base = buffer.baseAddress, buffer.count > 0 else {
            return 0
        }

        let result = Darwin.write(handle, base, buffer.count)
        guard result >= 0 else {
            throw IOError.errno
        }

        return result
    }

    func read(buffer: UnsafeMutableRawBufferPointer) throws -> Int {
        guard let base = buffer.baseAddress, buffer.count > 0 else {
            return 0
        }

        let result = Darwin.read(handle, base, buffer.count)
        guard result >= 0 else {
            throw IOError.errno
        }

        return result
    }

    func stat() throws -> stat {
        var result = Darwin.stat()
        guard Darwin.fstat(handle, &result) == 0 else {
            throw IOError.errno
        }

        return result
    }

    var isTTY: Bool {
        return isatty(handle) == 1
    }
}
