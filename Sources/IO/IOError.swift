import Foundation

public enum IOError: Error {
    case POSIXError(POSIXErrorCode)
    case unknownError
    case invalidURL

    static var errno: IOError {
        if let err = POSIXErrorCode(rawValue: sys_errno) {
            return .POSIXError(err)
        } else {
            return .unknownError
        }
    }
}
