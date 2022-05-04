import PlaygroundSupport
import Foundation
import OpenAI

PlaygroundPage.current.needsIndefiniteExecution = true

guard let url = Bundle.main.url(forResource: "api-key", withExtension: "txt"),
      let apiKey = try? String(contentsOf: url).trimmingCharacters(in: .whitespacesAndNewlines)
else {
    fatalError("OpenAI API key not found in OpenAI.playground/Resources/api-key.txt")
}

let client = OpenAI.Client(apiKey: apiKey)

// MARK: -

let prompt = "Tell me a story.\n"

client.completions(engine: "text-curie-001",
                   prompt: prompt,
                   sampling: .temperature(0.7),
                   numberOfTokens: ...64,
//                   numberOfCompletions: 5,
                   echo: true,
                   stop: [".", "\n", "<|endoftext|>"],
                   presencePenalty: 0,
                   frequencyPenalty: 0,
                   bestOf: 1) { result in
    guard case .success(let completions) = result else { fatalError() }

    for choice in completions.flatMap(\.choices) {
        let sentence = "\(choice.text)."
        print(sentence)
    }
}
