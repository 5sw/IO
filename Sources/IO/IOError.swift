import Darwin

public enum IOError: Error {
    case POSIXError(POSIXErrorCode)
    case unknownError
    case invalidURL

    static var errno: IOError {
        if let err = POSIXErrorCode(rawValue: Darwin.errno) {
            return .POSIXError(err)
        } else {
            return .unknownError
        }
    }
}
