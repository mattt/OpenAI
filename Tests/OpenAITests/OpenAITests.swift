import XCTest
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@testable import OpenAI
import Alamofire

final class OpenAITests: XCTestCase {
    var client: Client!

    override func setUpWithError() throws {
        if let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"]?.trimmingCharacters(in: .whitespacesAndNewlines),
           !apiKey.isEmpty
        {
            self.client = Client(apiKey: apiKey)
        } else {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.protocolClasses = [MockOpenAIURLProtocol.self]
            let session = Session(configuration: configuration)
            self.client = Client(session: session)
        }
    }

    func testEngines() {
        let expectation = XCTestExpectation()

        client.engines { result in
            expectation.fulfill()

            XCTAssertNoThrow {
                let engines = try result.get()
                try self.add(XCTAttachment(jsonEncoded: engines))

                XCTAssertNotNil(engines.first(where: { $0 == "ada" }))
                XCTAssertNotNil(engines.first(where: { $0 == "babbage" }))
                XCTAssertNotNil(engines.first(where: { $0 == "curie" }))
                XCTAssertNotNil(engines.first(where: { $0 == "davinci" }))
            }
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testEngine() {
        let expectation = XCTestExpectation()

        client.engine(id: "ada") { result in
            expectation.fulfill()

            do {
                let engine = try result.get()
                try self.add(XCTAttachment(jsonEncoded: engine))

                XCTAssertEqual(engine, "ada")
            } catch {
                XCTFail(error.localizedDescription)
            }
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testCompletions() {
        let expectation = XCTestExpectation()

        let prompt = """
        Write a recipe based on these ingredients and instructions:

        Frito Pie

        Ingredients:
        Fritos
        Chili
        Shredded cheddar cheese
        Sweet white or red onions, diced small
        Sour cream

        Directions:
        """

        client.completions(engine: "text-davinci-002", prompt: prompt, numberOfTokens: ...20, numberOfCompletions: 1) { result in
            expectation.fulfill()

            do {
                let completions = try result.get()
                try self.add(XCTAttachment(jsonEncoded: completions))

                XCTAssertEqual(completions.count, 1)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }

        wait(for: [expectation], timeout: 60.0)
    }

    func testSearch() {
        let expectation = XCTestExpectation()

        let documents: [String] = [
            "White House",
            "hospital",
            "school"
        ]

        let query = "president"

        client.search(engine: "text-davinci-002", documents: documents, query: query) { result in
            expectation.fulfill()

            do {
                let searchResults = try result.get()
                try self.add(XCTAttachment(jsonEncoded: searchResults))

                XCTAssertEqual(searchResults.count, 3)
                XCTAssertEqual(searchResults.max()?.document, 0)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }

        wait(for: [expectation], timeout: 60.0)
    }

    func testClassification() {
        let expectation = XCTestExpectation()

        let query = "It is a raining day :("

        let examples: [(String, label: String)] = [
            ("A happy moment", label: "Positive"),
            ("I am sad.", label: "Negative"),
            ("I am feeling awesome", label: "Positive")
        ]

        let labels = ["Positive", "Negative", "Neutral"]

        client.classify(engine: "text-curie-001", query: query, examples: examples, labels: labels, searchEngine: "text-ada-001") { result in
            expectation.fulfill()

            do {
                let classification = try result.get()
                try self.add(XCTAttachment(jsonEncoded: classification))

                XCTAssertEqual(classification.label, "Negative")
            } catch {
                XCTFail(error.localizedDescription)
            }
        }

        wait(for: [expectation], timeout: 60.0)
    }

    func testAnswers() {
        let expectation = XCTestExpectation()

        let documents: [String] = ["Puppy A is happy.", "Puppy B is sad."]
        let question = "which puppy is happy?"

        let examples: (context: String, [(question: String, answer: String)]) = (
            context: "In 2017, U.S. life expectancy was 78.6 years.",
            [
                (question: "What is human life expectancy in the United States?", answer: "78 years.")
            ]
        )

        let stop: [String] = ["\n", "<|endoftext|>"]

        client.answer(engine: "text-curie-001", question: question, examples: examples, documents: documents, searchEngine: "text-ada-001", stop: stop) { result in
            expectation.fulfill()

            do {
                let answers = try result.get()
                try self.add(XCTAttachment(jsonEncoded: answers))

                XCTAssertEqual(answers.answers.count, 1)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }

        wait(for: [expectation], timeout: 60.0)
    }
}
