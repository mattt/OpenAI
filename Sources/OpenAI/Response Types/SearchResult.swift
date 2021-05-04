import AnyCodable

/**
 The result of a search request.

 Given a query and a set of documents or labels,
 the model ranks each document based on its semantic similarity to the provided query.
 */
public struct SearchResult: Codable {
    /// The index of the document returned as a search result.
    public let document: Int

    /// The relevance score assigned by the model.
    public let score: Double

    /// Metadata for the search result.
    public let metadata: [String: AnyCodable]?
}

// MARK: - Comparable

extension SearchResult: Comparable {
    public static func < (lhs: SearchResult, rhs: SearchResult) -> Bool {
        return lhs.score < rhs.score
    }
}

// MARK: - Hashable

extension SearchResult: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(document)
        hasher.combine(score)
    }
}
