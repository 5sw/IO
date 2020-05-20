

import Foundation

public struct FileHandle: Source, Sink {
    let handle: Int32

    public static let stdin = FileHandle(handle: STDIN_FILENO)
    public static let stdout = FileHandle(handle: STDOUT_FILENO)
    public static let stderr = FileHandle(handle: STDERR_FILENO)

    public init(handle: Int32) {
        self.handle = handle
    }

    public init(url: URL, flag: Int32 = O_RDONLY, mode: mode_t = 0o666) throws {
        guard url.isFileURL else {
            throw IOError.invalidURL
        }

        handle = try url.withUnsafeFileSystemRepresentation { ptr in
            guard let ptr = ptr else {
                throw IOError.invalidURL
            }

            let handle = open(ptr, flag, mode)
            guard handle > 0 else {
                throw IOError.errno
            }

            return handle
        }
    }

    public func close() {
        _ = sys_close(handle)
    }

    public func write(buffer: UnsafeRawBufferPointer) throws -> Int {
        guard let base = buffer.baseAddress, buffer.count > 0 else {
            return 0
        }

        let result = sys_write(handle, base, buffer.count)
        guard result >= 0 else {
            throw IOError.errno
        }

        return result
    }

    public func read(buffer: UnsafeMutableRawBufferPointer) throws -> Int {
        guard let base = buffer.baseAddress, buffer.count > 0 else {
            return 0
        }

        let result = sys_read(handle, base, buffer.count)
        guard result >= 0 else {
            throw IOError.errno
        }

        return result
    }

    public func stat() throws -> stat {
        var result = IO.stat()
        guard sys_stat(handle, &result) == 0 else {
            throw IOError.errno
        }

        return result
    }

    public var isTTY: Bool {
        return isatty(handle) == 1
    }
}
