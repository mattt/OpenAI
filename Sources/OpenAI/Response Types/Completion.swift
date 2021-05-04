import Foundation

/**
 The result of a completion request.

 Given a prompt, the model will return one or more predicted completions,
 and can also return the probabilities of alternative tokens at each position.
 */
public struct Completion: Hashable, Identifiable {
    /// A completion choice.
    public struct Choice: Hashable {
        /// The reason why the completion finished.
        public enum FinishReason: String, Codable {
            /// The completion finished because it reached a maximum token limit.
            case length

            /// The completion finished because it encountered a stop word.
            case stop
        }

        /// The text of the completion choice.
        public let text: String

        /// The index of the completion choice.
        public let index: Int

        /// The reason why the completion finished.
        public let finishReason: FinishReason
    }

    /// A unique identifier for the completion.
    public let id: String

    /// The completion choices.
    public let choices: [Choice]

    /// A timestamp for when the completion was generated.
    public var creationDate: Date {
        Date(timeIntervalSince1970: TimeInterval(created))
    }
    private let created: Int

    /// The engine used to generate the completion.
    public let engine: Engine.ID
}

// MARK: - Codable

extension Completion: Codable {
    private enum CodingKeys: String, CodingKey {
        case id
        case choices
        case created
        case engine = "model"
    }
}

extension Completion.Choice: Codable {
    private enum CodingKeys: String, CodingKey {
        case text
        case index
        case finishReason = "finish_reason"
    }
}
