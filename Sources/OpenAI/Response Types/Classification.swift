/**
 The result of a classification request.

 Given a query and a set of labeled examples,
 the model will predict the most likely label for the query.
 Useful as a drop-in replacement for any ML classification or text-to-label task.
 */
public struct Classification: Hashable {
    /// A classification example.
    public struct Example: Hashable {
        /// The source of an example.
        public enum Source: Hashable {
            /// A document identified by its position.
            case document(Int)

            /// A file
            case file(File.ID)
        }

        /// The source of the example.
        public let source: Source

        /// The classification label for the example.
        public let label: String

        /// The text of the example.
        public let text: String
    }

    /// The completion for the classification.
    public let completion: String

    /// The classification label assigned by the model.
    public let label: String

    /// The engine used to perform classification.
    public let engine: Engine.ID

    /// The engine used for searching.
    public let searchEngine: Engine.ID

    /// The examples selected by the model in making its classification determination.
    public let selectedExamples: [Example]
}

// MARK: - Codable

extension Classification: Codable {
    private enum CodingKeys: String, CodingKey {
        case completion
        case label
        case engine = "model"
        case searchEngine = "search_model"
        case selectedExamples = "selected_examples"
    }
}

extension Classification.Example: Codable {
    private enum CodingKeys: String, CodingKey {
        case document, file
        case label
        case text
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let document = try? container.decode(Int.self, forKey: .document) {
            self.source = .document(document)
        } else if let file = try? container.decode(File.ID.self, forKey: .file) {
            self.source = .file(file)
        } else {
            let context = DecodingError.Context(codingPath: [], debugDescription: "unable to decode document or file")
            throw DecodingError.dataCorrupted(context)
        }

        self.label = try container.decode(String.self, forKey: .label)
        self.text = try container.decode(String.self, forKey: .text)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch source {
        case .document(let document):
            try container.encode(document, forKey: .document)
        case .file(let file):
            try container.encode(file, forKey: .file)
        }

        try container.encode(label, forKey: .label)
        try container.encode(text, forKey: .text)
    }
}
