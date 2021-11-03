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
    /// Returns whether the a safety level is less than another.
    ///
    /// Safety values have the inverse ordering of their raw integer values.
    /// That is, `.unsafe < .sensitive` and `.sensitive < .safe`.
    public static func < (lhs: Safety, rhs: Safety) -> Bool {
        return lhs.rawValue > rhs.rawValue
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
