/**
 The result of a content filter request.
 */
public enum Safety: Int, Hashable {
    /// This means that the text has been evaluated as safe.
    case safe = 0
    
    /// This means that the text could be talking about a sensitive topic, something political, religious, or talking about a protected class such as race or nationality.
    case sensitive = 1
    
    /// This means that the text contains profane language, prejudiced or hateful language, something that could be NSFW, or text that portrays certain groups/people in a harmful manner.
    case unsafe = 2
}

extension Safety: Comparable {
    private static func minimum(_ lhs: Self, _ rhs: Self) -> Self {
        switch (lhs, rhs) {
        case (.safe, _), (_, .safe):
            return .safe
        case (.sensitive, _), (_, .sensitive):
            return .sensitive
        case (.unsafe, _), (_, .unsafe):
            return .unsafe
        }
    }
    
    public static func < (lhs: Safety, rhs: Safety) -> Bool {
        return (lhs != rhs) && (lhs == Self.minimum(lhs, rhs))
    }
}

extension Safety: CustomStringConvertible {
    public var description: String {
        switch self {
        case .safe:
            return "Safe"
        case .sensitive:
            return "Sensitive"
        case .unsafe:
            return "Unsafe"
        }
    }
}

extension Safety: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self.init(rawValue: value)!
    }
}
