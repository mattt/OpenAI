import Foundation
import AnyCodable

/**
 An uploaded file.

 Files are used to upload documents that can be used across features like
 Answers, Search, and Classifications.
 */
public struct File: Hashable, Identifiable {
    /// The purpose of the file.
    public enum Purpose: String, CaseIterable, Hashable, Codable {
        /// Searching.
        case search

        /// Answering questions.
        case answers

        /// Classification.
        case classifications
    }

    /// A unique identifier for the file.
    public let id: String

    /// The filename.
    public let filename: String

    /// The size in bytes.
    public var size: Int

    /// A timestamp for when the file was uploaded.
    public var creationDate: Date {
        Date(timeIntervalSince1970: TimeInterval(created))
    }
    private let created: Int
}

// MARK: - Codable

extension File: Codable {
    private enum CodingKeys: String, CodingKey {
        case id
        case size = "bytes"
        case created = "created_at"
        case filename
    }
}
