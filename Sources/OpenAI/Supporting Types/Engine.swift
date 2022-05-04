import Foundation

/**
 Engines describe and provide access to the various models available in the API.

 OpenAI’s API provides access to several different engines - Ada, Babbage, Curie and Davinci, including the instruct series and the older models, as well as Codex models.

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
    /// A unique identifier for the engine.
    public enum ID: Hashable {
        
        //In 2021, we released a set of beta GPT-3 models called the Instruct series. The 4 Instruct models, unlike our original base GPT-3 models, are optimized to follow your instructions. This means they're better at producing accurate completions for your prompts.
        
        /**
         Davinci is the most capable engine and can perform any task the other models can perform and often with less instruction. For applications requiring a lot of understanding of the content, like summarization for a specific audience and creative content generation, Davinci is going to produce the best results. These increased capabilities require more compute resources, so Davinci costs more per API call and is not as fast as the other engines.

         Another area where Davinci shines is in understanding the intent of text. Davinci is quite good at solving many kinds of logic problems and explaining the motives of characters. Davinci has been able to solve some of the most challenging AI problems involving cause and effect.

         Good at: Complex intent, cause and effect, summarization for audience
         */
        case textDavinci002
        
        /**
         Curie is extremely powerful, yet very fast. While Davinci is stronger when it comes to analyzing complicated text, Curie is quite capable for many nuanced tasks like sentiment classification and summarization. Curie is also quite good at answering questions and performing Q&A and as a general service chatbot.

         Good at: Language translation, complex classification, text sentiment, summarization
         */
        case textCurie001
        
        /**
         Babbage can perform straightforward tasks like simple classification. It’s also quite capable when it comes to Semantic Search ranking how well documents match up with search queries.

         Good at: Moderate classification, semantic search classification
         */
        case textBabbage001
        
        /**
         Ada is usually the fastest model and can perform tasks like parsing text, address correction and certain kinds of classification tasks that don’t require too much nuance. Ada’s performance can often be improved by providing more context.

         Good at: Parsing text, simple classification, address correction, keywords

         - Note: Any task performed by a faster model like Ada can be performed by a more powerful model like Curie or Davinci.
         */
        case textAda001
        
        /**
         Ada is usually the fastest model and can perform tasks like parsing text, address correction
         and certain kinds of classification tasks that don’t require too much nuance.
         Ada’s performance can often be improved by providing more context.

         Good at: Parsing text, simple classification, address correction, keywords

         - Note: Any task performed by a faster model like Ada
                 can be performed by a more powerful model like Curie or Davinci
         */
        
        
        //Older versions of our GPT-3 models are available as davinci, curie, babbage, and ada. These are meant to be used with our fine-tuning, search, classification, and question answering endpoints.
        
        /**
         This model is part of our original, base GPT-3 series. We recommend using our latest GPT-3 models instead. (See above.)
         
         Good at: Complex intent, cause and effect, summarization for audience
         */
        case davinci
        
        /**
         This model is part of our original, base GPT-3 series. We recommend using our latest GPT-3 models instead. (See above.)
         
         Good at: Moderate classification, semantic search classification
         */
        case curie
        
        /**
         This model is part of our original, base GPT-3 series. We recommend using our latest GPT-3 models instead. (See above.)
         
         Good at: Parsing text, simple classification, address correction, keywords
         */
        case babbage
        
        /**
         This model is part of our original, base GPT-3 series. We recommend using our latest GPT-3 models instead. (See above.)
         
         Good at: Parsing text, simple classification, address correction, keywords
         */
        case ada
        
        
        //Codex: A set of models that can understand and generate code, including translating natural language to code. (Private Beta.)
        
        /**
         Most capable Codex model. Particularly good at translating natural language to code. In addition to completing code, also supports inserting completions within code.
         
         The Codex models are descendants of our GPT-3 models that can understand and generate code. Their training data contains both natural language and billions of lines of public code from GitHub.

         They’re most capable in Python and proficient in over a dozen languages including JavaScript, Go, Perl, PHP, Ruby, Swift, TypeScript, SQL, and even Shell.
         
         Max Request: 4,000 tokens
         Training Data: Up to Jun 2021
         */
        case codeDavinci002
        
        /**
         Almost as capable as Davinci Codex, but slightly faster. This speed advantage may make it preferable for real-time applications.
         
         The Codex models are descendants of our GPT-3 models that can understand and generate code. Their training data contains both natural language and billions of lines of public code from GitHub.

         They’re most capable in Python and proficient in over a dozen languages including JavaScript, Go, Perl, PHP, Ruby, Swift, TypeScript, SQL, and even Shell.
         
         Max Request: 2,048 tokens
         */
        case codeCushman001

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
        case .textDavinci002:
            return "text-davinci-002"
        case .textCurie001:
            return "text-curie-001"
        case .textBabbage001:
            return "text-babbage-001"
        case .textAda001:
            return "text-ada-001"
            
        case .davinci:
            return "davinci"
        case .curie:
            return "curie"
        case .babbage:
            return "babbage"
        case .ada:
            return "ada"
            
        case .codeDavinci002:
            return "code-davinci-002"
        case .codeCushman001:
            return "code-cushman-001"
            
        case .other(let name):
            return name
        }
    }
}

// MARK: - LosslessStringConvertible

extension Engine.ID: LosslessStringConvertible {
    public init(_ description: String) {
        switch description {
        case "text-davinci-002":
            self = .textDavinci002
        case "text-curie-001":
            self = .textCurie001
        case "text-babbage-001":
            self = .textBabbage001
        case "text-ada-001":
            self = .textAda001
            
        case "davinci":
            self = .davinci
        case "curie":
            self = .curie
        case "babbage":
            self = .babbage
        case "ada":
            self = .ada
            
        case "code-davinci-002":
            self = .codeDavinci002
        case "code-cushman-001":
            self = .codeCushman001
            
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
