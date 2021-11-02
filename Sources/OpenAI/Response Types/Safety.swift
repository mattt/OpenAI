/**
 The result of contentFilter request.
 */
import Foundation

public enum Safety: Int, Comparable {
    /// This means that the text has been evaluated as safe.
    case safe = 0
    
    /// This means that the text could be talking about a sensitive topic, something political, religious, or talking about a protected class such as race or nationality.
    case sensitive = 1
    
    /// This means that the text contains profane language, prejudiced or hateful language, something that could be NSFW, or text that portrays certain groups/people in a harmful manner.
    case unsafe = 2
    
    /// This means that the completion request return an unknown token and has failed.
    case failure = 3
}

extension Safety: Equatable { }

extension Safety: Comparable { }

extension Safety: Hashable { }

extension Safety: CustomStringConvertible {
    public var description: String {
        switch self {
        case .safe:
            return "Safe"
        case .sensitive:
            return "Sensitive"
        case .unsafe:
            return "Unsafe"
        case .failure:
            return "Unexpected result"
        }
    }
}

extension Safety: ExpressibleByIntegerLiteral {
    init(integerLiteral value: Int) {
        self.init(rawValue: value)!
    }
}
