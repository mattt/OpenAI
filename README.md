# OpenAI

![CI][ci badge]
[![Documentation][documentation badge]][documentation]

A Swift client for the [OpenAI API](https://beta.openai.com/).

## Requirements

- Swift 5.3+
- An OpenAI API Key

## Example Usage

### Base Series

> Our [base GPT-3 models] can understand and generate natural language.
> We offer four base models called `davinci`, `curie`, `babbage`, and `ada`
> with different levels of power suitable for different tasks.

#### Completions

```swift
import OpenAI

let apiKey: String // required
let client = Client(apiKey: apiKey)

let prompt = "Once upon a time"

client.completions(engine: .davinci,
                   prompt: prompt,
                   numberOfTokens: ...5,
                   numberOfCompletions: 1) { result in
    guard case .success(let completions) = result else { return }

    completions.first?.choices.first?.text // " there was a girl who"
}
```

#### Searches

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

client.search(engine: .davinci,
              documents: documents,
              query: query) { result in
    guard case .success(let searchResults) = result else { return }
    searchResults.max()?.document // 0 (for "White House")
}
```

#### Classifications

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

client.classify(engine: .curie,
                query: query,
                examples: examples,
                labels: labels,
                searchEngine: .ada) { result in
    guard case .success(let classification) = result else { return }

    classification.label // "Negative"
}
```

#### Answers

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

### Codex

> The [Codex] models are descendants of our base GPT-3 models
> that can understand and generate code.
> Their training data contains both natural language and
> billions of lines of public code from GitHub.

```swift
import OpenAI

// `Engine.ID` provides cases for the
// `ada`, `babbage`, `curie`, and `davinci` engines.
// You can add convenience APIs for other engines
// by defining computed type properties in an extension.
extension Engine.ID {
    static var davinciCodex: Self = "code-davinci-002"
}

let apiKey: String // required
let client = Client(apiKey: apiKey)

let prompt = #"""
// Translate this function from Swift into Objective-C
// Swift

let numbers = [Int](1...10)
let evens = numbers.filter { $0 % 2 == 0 }
let sumOfEvens = evens.reduce(0, +)

// Objective-C

"""#

client.completions(engine: .davinciCodex,
                   prompt: prompt,
                   sampling: .temperature(0.0),
                   numberOfTokens: ...256,
                   numberOfCompletions: 1,
                   echo: false,
                   stop: ["//"],
                   presencePenalty: 0.0,
                   frequencyPenalty: 0.0,
                   bestOf: 1) { result in
    guard case .success(let completions) = result else { fatalError("\(result)") }

    for choice in completions.flatMap(\.choices) {
        print("\(choice.text)")
    }
}
// Prints the following code:
// ```
// NSArray *numbers = @[@1, @2, @3, @4, @5, @6, @7, @8, @9, @10];
// NSArray *evens = [numbers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self % 2 == 0"]];
// NSInteger sumOfEvens = [[evens valueForKeyPath:@"@sum.self"] integerValue];
// ```
```

### Instruct Series

> The [Instruct] models share our base GPT-3 models’ ability to
> understand and generate natural language,
> but they’re better at understanding and following your instructions.
> You simply tell the model what you want it to do,
> and it will do its best to fulfill your instructions.

```swift
import OpenAI

let apiKey: String // required
let client = Client(apiKey: apiKey)

let prompt = "Describe the Swift programming language in a few sentences."

client.completions(engine: "davinci-instruct-beta",
                   prompt: prompt,
                   sampling: .temperature(0.0),
                   numberOfTokens: ...100,
                   numberOfCompletions: 1,
                   stop: ["\n\n"],
                   presencePenalty: 0.0,
                   frequencyPenalty: 0.0,
                   bestOf: 1) { result in
    guard case .success(let completions) = result else { fatalError("\(result)") }

    for choice in completions.flatMap(\.choices) {
        print("\(choice.text)")
    }
}
// Prints the following:
// "Swift is a general-purpose programming language that was developed by Apple Inc. for iOS and OS X development. Swift is designed to work with Apple's Cocoa and Cocoa Touch frameworks and the large body of existing Objective-C code written for Apple products. Swift is intended to be more resilient to erroneous code (such as buffer overflow errors) and better support concurrency (such as multi-threading) than Objective-C."
```

### Content Filter

> The [content filter] aims to detect generated text that could be
> sensitive or unsafe coming from the API.
> It's currently in beta mode and has three ways of classifying text —
> as safe, sensitive, or unsafe.
> The filter will make mistakes and we have currently built it to
> err on the side of caution, thus, resulting in higher false positives.

```swift
import OpenAI

let apiKey: String // required
let client = Client(apiKey: apiKey)

let prompt = "I know it's an unpopular political opinion to hold, but I think that..."

client.completions(engine: "content-filter-alpha-c4",
                   prompt: "<|endoftext|>\(prompt)\n--\nLabel:",
                   sampling: .temperature(0.0),
                   numberOfTokens: ...1,
                   numberOfCompletions: 1,
                   echo: false,
                   stop: ["<|endoftext|>[prompt]\n--\nLabel:"],
                   presencePenalty: 0.0,
                   frequencyPenalty: 0.0,
                   bestOf: 1) { result in
    guard case .success(let completions) = result else { fatalError("\(result)") }

    if let text = completions.flatMap(\.choices).first?.text.trimmingCharacters(in: .whitespacesAndNewlines) {
        switch Int(text) {
        case 0:
            print("Safe")
        case 1:
            print("Sensitive")
            // This means that the text could be talking about a sensitive topic, something political, religious, or talking about a protected class such as race or nationality.
        case 2:
            print("Unsafe")
            // This means that the text contains profane language, prejudiced or hateful language, something that could be NSFW, or text that portrays certain groups/people in a harmful manner.
        default:
            print("unexpected token: \(text)")
        }
    }
}
// Prints "Sensitive"
```

## Installation

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
        from: "0.1.3"
    ),
  ]
)
```

Then run the `swift build` command to build your project.

## License

MIT

## Contact

Mattt ([@mattt](https://twitter.com/mattt))

[ci badge]: https://github.com/mattt/OpenAI/workflows/CI/badge.svg
[documentation badge]: https://github.com/mattt/OpenAI/workflows/Documentation/badge.svg
[documentation]: https://github.com/mattt/OpenAI/wiki

[base GPT-3 models]: https://beta.openai.com/docs/engines/base-series
[Codex]: https://beta.openai.com/docs/engines/codex-series-private-beta
[Instruct]: https://beta.openai.com/docs/engines/instruct-series-beta
[content filter]: https://beta.openai.com/docs/engines/content-filter
