/**
 The result of a contentFilter request.
 */
public enum Safety: Int {
    
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

extension Safety: Comparable {
    private static func minimum(_ lhs: Self, _ rhs: Self) -> Self {
        switch (lhs, rhs) {
        case (.safe, _), (_, .safe):
            return .safe
        case (.sensitive, _), (_, .sensitive):
            return .sensitive
        case (.unsafe, _), (_, .unsafe):
            return .unsafe
        case (.failure, _), (_, .failure):
            return .failure
        }
    }
    
    public static func < (lhs: Safety, rhs: Safety) -> Bool {
        return (lhs != rhs) && (lhs == Self.minimum(lhs, rhs))
    }
}

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
    public init(integerLiteral value: Int) {
        self.init(rawValue: value)!
    }
}
