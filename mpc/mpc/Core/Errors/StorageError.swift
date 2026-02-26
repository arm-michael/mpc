import Foundation

/// Errors related to local storage operations.
enum StorageError: LocalizedError, Equatable {
    case insufficientSpace(available: Int64, required: Int64)
    case writeFailure(path: String, underlying: String)
    case readFailure(path: String)
    case indexCorrupted

    var errorDescription: String? {
        switch self {
        case .insufficientSpace:
            return "Not enough storage space. Free up space and try again."
        case .writeFailure:
            return "Could not save the sample. Please try again."
        case .readFailure:
            return "Could not read the sample file."
        case .indexCorrupted:
            return "Sample index is corrupted. Your samples may need to be re-assigned."
        }
    }
}
