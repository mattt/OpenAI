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

let prompt = "Once upon a time"

client.contentFilter(prompt: prompt) { filterCode in
    switch filterCode {
        case 0:
            print("Safe")
        case 1:
            print("Sensitive")
            // This means that the text could be talking about a sensitive topic, something political, religious, or talking about a protected class such as race or nationality.
            
        case 2:
            print("Unsafe")
            // This means that the text contains profane language, prejudiced or hateful language, something that could be NSFW, or text that portrays certain groups/people in a harmful manner.
        default:
            print("Content Filter failure")
    }
}


client.completions(engine: .davinci,
                   prompt: prompt,
                   sampling: .temperature(0.7),
                   numberOfTokens: ...64,
                   numberOfCompletions: 5,
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
