import XCTest

extension XCTAttachment {
    convenience init<T: Encodable>(jsonEncoded value: T) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(value)
        self.init(data: data, uniformTypeIdentifier: "public.json")
    }
}
