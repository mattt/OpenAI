# OpenAI

A Swift client for the [OpenAI API](https://beta.openai.com/).

## Requirements

- Swift 5.3+
- An OpenAI API Key

## Example Usage

### Completions

```swift
import OpenAI

let apiKey: String // required
let client = Client(apiKey: apiKey)

let prompt = "Once upon a time"

client.completions(engine: .davinci, prompt: prompt, numberOfTokens: ...5, numberOfCompletions: 1) { result in
    guard case .success(let completions) = result else { return }
    
    completions.first?.choices.first?.text // " there was a girl who"
}
```

### Searches

```swift
import OpenAI

let apiKey: String // required
let client = Client(apiKey: apiKey)

let documents: [String] = [
    "White House",
    "hospital",
    "school"
]

let query = "president"

client.search(engine: .davinci, documents: documents, query: query) { result in
    guard case .success(let searchResults) = result else { return }
    searchResults.max()?.document // 0 (for "White House")
}
```

### Classifications

```swift
import OpenAI

let apiKey: String // required
let client = Client(apiKey: apiKey)

let query = "It is a raining day :("

let examples: [(String, label: String)] = [
    ("A happy moment", label: "Positive"),
    ("I am sad.", label: "Negative"),
    ("I am feeling awesome", label: "Positive")
]

let labels = ["Positive", "Negative", "Neutral"]

client.classify(engine: .curie, query: query, examples: examples, labels: labels, searchEngine: .ada) { result in
    guard case .success(let classification) = result else { return }
    
    classification.label // "Negative"
}
```

### Answers

```swift
import OpenAI

let apiKey: String // required
let client = Client(apiKey: apiKey)

let documents: [String] = [
    "Puppy A is happy.", 
    "Puppy B is sad."
]

let question = "which puppy is happy?"

let examples: (context: String, [(question: String, answer: String)]) = (
    context: "In 2017, U.S. life expectancy was 78.6 years.",
    [
        (question: "What is human life expectancy in the United States?", answer: "78 years.")
    ]
)

client.answer(engine: .curie, 
              question: question, 
              examples: examples, 
              documents: documents, 
              searchEngine: .ada, 
              stop: ["\n", "<|endoftext|>"]) { result in
    guard case .success(let response) = result else { return }
    
    response.answers.first // "puppy A."
}
```

### Swift Package Manager

Add the OpenAI package to your target dependencies in `Package.swift`:

```swift
// swift-tools-version:5.3
import PackageDescription

let package = Package(
  name: "YourProject",
  dependencies: [
    .package(
        url: "https://github.com/mattt/OpenAI",
        from: "0.1.0"
    ),
  ]
)
```

Then run the `swift build` command to build your project.

## License

MIT

## Contact

Mattt ([@mattt](https://twitter.com/mattt))
