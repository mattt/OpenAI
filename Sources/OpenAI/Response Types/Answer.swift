/**
 The result of a question answering request.

 Given a question, a set of documents, and some examples,
 the API generates an answer to the question
 based on the information in the set of documents.
 This is useful for question-answering applications on sources of truth,
 like company documentation or a knowledge base.
 */
public struct Answers: Hashable {
    /// The completion for the answer.
    public let completion: String

    /// The possible answers.
    public let answers: [String]

    /// The engine used to answer the question.
    public let engine: Engine.ID

    /// The engine used for searching.
    public let searchEngine: Engine.ID

    /// The documents selected for each answer.
    public let selectedDocuments: [Int: String]
}

// MARK: - Codable

extension Answers: Codable {
    private struct Document: Codable {
        let key: Int
        let text: String

        private enum CodingKeys: String, CodingKey {
            case key = "document"
            case text
        }
    }

    private enum CodingKeys: String, CodingKey {
        case answers
        case completion
        case engine = "model"
        case searchEngine = "search_model"
        case selectedDocuments = "selected_documents"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.completion = try container.decode(String.self, forKey: .completion)
        self.answers = try container.decode([String].self, forKey: .answers)
        self.engine = try container.decode(Engine.ID.self, forKey: .engine)
        self.searchEngine = try container.decode(Engine.ID.self, forKey: .searchEngine)

        let documents = try container.decode([Document].self, forKey: .selectedDocuments)
        self.selectedDocuments = Dictionary(uniqueKeysWithValues: documents.map { ($0.key, $0.text) })
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(completion, forKey: .completion)
        try container.encode(answers, forKey: .answers)
        try container.encode(engine, forKey: .engine)
        try container.encode(searchEngine, forKey: .searchEngine)
        let documents = selectedDocuments.map { Document(key: $0.key, text: $0.value) }
        try container.encode(documents, forKey: .selectedDocuments)
        try container.encode(completion, forKey: .completion)
    }
}
