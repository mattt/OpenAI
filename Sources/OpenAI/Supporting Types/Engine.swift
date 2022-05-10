import Foundation

/**
 Engines describe and provide access to the various models available in the API.

 OpenAI’s API provides access to several different engines - Ada, Babbage, Curie and Davinci.

 While Davinci is generally the most capable engine,
 the other engines can perform certain tasks extremely well and in some cases significantly faster.
 The other engines have cost advantages.
 For example, Curie can perform many of the same tasks as Davinci,
 but faster and for 1/10th the cost.
 We encourage developers to experiment with using the other models
 and try to find the one that’s the most efficient for your application.

 https://beta.openai.com/docs/engines
 */
public struct Engine: Hashable, Identifiable, Codable {
    /**
     A unique identifier for the engine.

     This enumeration provides cases for the
     `ada`, `babbage`, `curie`, and `davinci` engines.
     You can add convenience APIs for other engines
     by defining computed type properties in an extension.

     ```swift
     extension Engine.ID {
       static var babbageSearchQuery: Self = "babbage-search-query"
     }
     ```
    */
    public enum ID: Hashable {
        /**
         Ada is usually the fastest model and can perform tasks like parsing text, address correction
         and certain kinds of classification tasks that don’t require too much nuance.
         Ada’s performance can often be improved by providing more context.

         Good at: Parsing text, simple classification, address correction, keywords

         - Note: Any task performed by a faster model like Ada
                 can be performed by a more powerful model like Curie or Davinci
         */
        case ada

        /**
         Babbage can perform straightforward tasks like simple classification.
         It’s also quite capable when it comes to Semantic Search ranking
         how well documents match up with search queries.

         Good at: Moderate classification, semantic search classification
         */
        case babbage

        /**
         Curie is extremely powerful, yet very fast.
         While Davinci is stronger when it comes to analyzing complicated text,
         Curie is quite capable for many nuanced tasks like sentiment classification and summarization.
         Curie is also quite good at answering questions
         and performing Q&A and as a general service chatbot.
         */
        case curie

        /**
         Davinci is the most capable engine and can perform any task the other models can perform
         and often with less instruction.
         For applications requiring a lot of understanding of the content,
         like summarization for a specific audience and content creative generation,
         Davinci is going to produce the best results.
         The trade-off with Davinci is that it costs more to use per API call
         and other engines are faster.

         Another area where Davinci shines is in understanding the intent of text.
         Davinci is quite good at solving many kinds of logic problems
         and explaining the motives of characters.
         Davinci has been able to solve some of the most challenging AI problems
         involving cause and effect.

         Good at: Language translation, complex classification, text sentiment, summarization
         */
        case davinci

        case other(String)
    }

    public let id: ID

    public let owner: String

    public let ready: Bool

    private let created: Int?
    public var creationDate: Date? {
        created.map { Date(timeIntervalSince1970: TimeInterval($0)) }
    }
}

// MARK: - Comparable

extension Engine: Comparable {
    public static func < (lhs: Engine, rhs: Engine) -> Bool {
        return lhs.id < rhs.id
    }
}

extension Engine.ID: Comparable {
    public static func < (lhs: Engine.ID, rhs: Engine.ID) -> Bool {
        return lhs.description < rhs.description
    }
}

// MARK: - CustomStringConvertible

extension Engine.ID: CustomStringConvertible {
    public var description: String {
        switch self {
        case .ada:
            return "ada"
        case .babbage:
            return "babbage"
        case .curie:
            return "curie"
        case .davinci:
            return "davinci"
        case .other(let name):
            return name
        }
    }
}

// MARK: - LosslessStringConvertible

extension Engine.ID: LosslessStringConvertible {
    public init(_ description: String) {
        switch description {
        case "ada":
            self = .ada
        case "babbage":
            self = .babbage
        case "curie":
            self = .curie
        case "davinci":
            self = .davinci
        default:
            self = .other(description)
        }
    }
}

// MARK: - ExpressibleByStringLiteral

extension Engine.ID: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

// MARK: - Codable

extension Engine.ID: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        self.init(value)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}
