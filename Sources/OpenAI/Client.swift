import Foundation
import Alamofire
import AnyCodable

/**
 A client for interacting with the OpenAI API.
 */
public final class Client {
    /**
     An error returned by the OpenAI API.
     */
    public struct Error: Swift.Error, Decodable {
        /// The type of error.
        public let type: String

        /// The error code, if any.
        public let code: Int?

        /// The parameter that caused the error.
        public let param: String?

        /// A message describing the error.
        public let message: String
    }

    /// The underlying session.
    private let session: Session

    /**
     Creates a new client with a provided API key and optional organization.

     - Parameters:
        - apiKey: An OpenAI API key.
        - organization: The organization associated with the provided API key.

     - SeeAlso: https://beta.openai.com/docs/api-reference/authentication
     */
    public init(apiKey: String, organization: String? = nil) {
        let adaptor = Adapter { (urlRequest, session, completion) in
            var urlRequest = urlRequest
            urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            if let organization = organization {
                urlRequest.setValue(organization, forHTTPHeaderField: "OpenAI-Organization")
            }
            completion(.success(urlRequest))
        }

        self.session = Session(interceptor: adaptor)
    }

    init(session: Session) {
        self.session = session
    }

    // MARK: Engines

    /**
     Lists the currently available engines, and
     provides basic information about each one such as the owner and availability.

     ```
     GET https://api.openai.com/v1/engines
     ```

     - Parameters:
       - completion: A closure to be called once the request finishes.
                     The closure takes a single argument, the result of the request.

     - SeeAlso: https://beta.openai.com/docs/api-reference/engines/list
     */
    public func engines(completion: @escaping (Result<[Engine], Swift.Error>) -> Void) {
        session.request("https://api.openai.com/v1/engines", method: .get)
            .responseDecodable(of: Response<[Engine]>.self, queue: .main) { response in
                completion(response.result.flatMap { $0 })
            }
    }

    /**
     Retrieves an engine instance, providing basic information about the engine
     such as the owner and availability.

     ```
     GET https://api.openai.com/v1/engines/{engine_id}
     ```

     - Parameters:
       - completion: A closure to be called once the request finishes.
                     The closure takes a single argument, the result of the request.

     - SeeAlso: https://beta.openai.com/docs/api-reference/engines/retrieve
     */
    public func engine(id: Engine.ID,
                       completion: @escaping (Result<Engine, Swift.Error>) -> Void)
    {
        session.request("https://api.openai.com/v1/engines/\(id)", method: .get)
            .responseDecodable(of: Response<Engine>.self, queue: .main) { response in
                completion(response.result.flatMap { $0 })
            }
    }

    // MARK: Completions

    /**

     Creates a new completion for the provided prompt and parameters.

     ```
     POST https://api.openai.com/v1/engines/{engine_id}/completions
     ```

     - Parameters:
       - engine: The engine to use for this request.
       - prompt: The prompt(s) to generate completions for.
       - sampling: The sampling to use for generating completions.
       - numberOfTokens: A partially bounded range of tokens to generate.
                         Requests can use up to 2048 tokens shared between prompt and completion.
                         (One token is roughly 4 characters for normal
       - numberOfCompletions: The number of completions to generate.
       - echo: Echo back the prompt in addition to the completion.
       - stop: Up to 4 sequences where the API will stop generating further tokens.
               The returned text will not contain the stop sequence.
       - user: A unique user identifier sometimes required by OpenAI for production.
       - presencePenalty: Number between -2.0 and 2.0 that penalizes new tokens
                          based on whether they appear in the text so far.
                          Increases the model's likelihood to talk about new topics.
       - frequencyPenalty: Number between -2.0 and 2.0 that penalizes new tokens
                           based on their existing frequency in the text so far.
                           Decreases the model's likelihood to repeat the same line verbatim.
       - bestOf: Generates a given number of completions server-side
                 and returns the "best" (the one with the lowest log probability per token).
                 Must be greater than `numberOfCompletions`, if both are specified.
                 When used with `numberOfCompletions`,
                 this parameter controls the number of candidate completions
                 and `numberOfCompletions` specifies how many to return.
       - completion: A closure to be called once the request finishes.
                     The closure takes a single argument, the result of the request.

     - SeeAlso: https://beta.openai.com/docs/api-reference/completions/create

     - Note: Use the `numberOfCompletions` and `bestOf` parameters carefully
             and ensure that you have reasonable settings for `numberOfTokens` and `stop`,
             because it can quickly consume your token quota.
     */

    public func completions(engine id: Engine.ID,
                            prompt: String? = nil,
                            sampling: Sampling? = nil,
                            numberOfTokens: PartialRangeThrough<Int>? = nil,
                            numberOfCompletions: Int? = nil,
                            echo: Bool? = nil,
                            stop: [String]? = nil,
                            user: String? = nil,
                            presencePenalty: Double? = nil,
                            frequencyPenalty: Double? = nil,
                            bestOf: Int? = nil,
                            completion: @escaping (Result<[Completion], Swift.Error>) -> Void)
    {
        var parameters: [String: Any?] = [
            "prompt": prompt,
            "max_tokens": numberOfTokens?.upperBound,
            "n": numberOfCompletions,
            "echo": echo,
            "stop": stop,
            "user": user,
            "presence_penalty": presencePenalty,
            "frequency_penalty": frequencyPenalty,
            "best_of": bestOf
        ]

        switch sampling {
        case .temperature(let temperature)?:
            parameters["temperature"] = temperature
        case .nucleus(let percentage)?:
            parameters["top_p"] = percentage
        default:
            break
        }

        session.request("https://api.openai.com/v1/engines/\(id)/completions",
                        method: .post,
                        parameters: parameters.compactMapValues { $0.map(AnyEncodable.init) },
                        encoder: JSONParameterEncoder.default)
            .responseDecodable(of: Response<Completion>.self, queue: .main) { response in
                completion(response.result.flatMap { [$0] })
            }
    }

    // MARK: Searches

    /**
     Create search with a list of documents.

     ```
     POST https://api.openai.com/v1/engines/{engine_id}/search
     ```

     The search endpoint computes similarity scores between provided query and documents.
     Documents can be passed directly to the API if there are no more than 200 of them.

     To go beyond the 200 document limit,
     documents can be processed offline and then used for efficient retrieval at query time.
     When file is set, the search endpoint searches over all the documents in the given file
     and returns up to the max_rerank number of documents.
     These documents will be returned along with their search scores.

     The similarity score is a positive score that usually ranges from 0 to 300
     (but can sometimes go higher),
     where a score above 200 usually means the document is semantically similar to the query.

     - Parameters:
       - engine: The engine to use for this request.
       - documents: Up to 200 documents to search over, provided as a list of strings.
                    The maximum document length (in tokens) is 2034
                    minus the number of tokens in the query.
       - query: Query to search against the documents.
       - completion: A closure to be called once the request finishes.
                     The closure takes a single argument, the result of the request.

     - SeeAlso: https://beta.openai.com/docs/api-reference/completions/create
     */
    public func search(engine id: Engine.ID,
                       documents: [String],
                       query: String,
                       completion: @escaping (Result<[SearchResult], Swift.Error>) -> Void)
    {
        let parameters: [String: Any?] = [
            "documents": documents,
            "query": query
        ]

        session.request("https://api.openai.com/v1/engines/\(id)/search",
                        method: .post,
                        parameters: parameters.compactMapValues { $0.map(AnyEncodable.init) },
                        encoder: JSONParameterEncoder.default)
            .responseDecodable(of: Response<[SearchResult]>.self, queue: .main) { response in
                completion(response.result.flatMap { $0 })
            }
    }

    /**
     Create search with a list of documents.

     ```
     POST https://api.openai.com/v1/engines/{engine_id}/search
     ```

     The search endpoint computes similarity scores between provided query and documents.
     Documents can be passed directly to the API if there are no more than 200 of them.

     To go beyond the 200 document limit,
     documents can be processed offline and then used for efficient retrieval at query time.
     When file is set, the search endpoint searches over all the documents in the given file
     and returns up to the max_rerank number of documents.
     These documents will be returned along with their search scores.

     The similarity score is a positive score that usually ranges from 0 to 300
     (but can sometimes go higher),
     where a score above 200 usually means the document is semantically similar to the query.

     - Parameters:
       - engine: The engine to use for this request.
       - file: The ID of an uploaded file that contains documents to search over.
       - query: Query to search against the documents.
       - completion: A closure to be called once the request finishes.
                   The closure takes a single argument, the result of the request.

     - SeeAlso: https://beta.openai.com/docs/api-reference/completions/create
     */
    public func search(engine id: Engine.ID,
                       file: String,
                       query: String,
                       numberOfDocuments: PartialRangeThrough<Int>? = nil,
                       includeMetadata: Bool? = nil,
                       completion: @escaping (Result<[SearchResult], Swift.Error>) -> Void)
    {
        let parameters: [String: Any?] = [
            "file": file,
            "query": query,
            "max_rerank": numberOfDocuments?.upperBound,
            "return_metadata": includeMetadata
        ]

        session.request("https://api.openai.com/v1/engines/\(id)/search",
                        method: .post,
                        parameters: parameters.compactMapValues { $0.map(AnyEncodable.init) },
                        encoder: JSONParameterEncoder.default)
            .responseDecodable(of: Response<[SearchResult]>.self, queue: .main) { response in
                completion(response.result.flatMap { $0 })
            }
    }

    // MARK: Classifications

    /**
     Create classification.

     ```
     POST https://api.openai.com/v1/classifications
     ```

     Classifies the specified query using provided examples.

     The endpoint first searches over the labeled examples
     to select the ones most relevant for the particular query.
     Then, the relevant examples are combined with the query
     to construct a prompt to produce the final label via the completions endpoint.

     Labeled examples can be provided via an uploaded file,
     or explicitly listed in the request using the examples parameter
     for quick tests and small scale use cases.

     - Parameters:
       - engine: The engine to use for this request.
       - query: Query to be classified.
       - examples: A list of examples with labels.
                   All the label strings will be normalized to be capitalized.
       - labels: The set of categories being classified.
                 If not specified, candidate labels will be automatically collected
                 from the examples you provide.
                 All the label strings will be normalized to be capitalized.
       - searchEngine: The engine to use for Search.
       - temperature: What sampling temperature to use.
                      Higher values mean the model will take more risks.
                      Try 0.9 for more creative applications,
                      and 0 (argmax sampling) for ones with a well-defined answer.
       - includingLogProbabilities: Include the log probabilities on the logprobs most likely tokens,
                                    as well the chosen tokens.
                                    For example, if logprobs is 10,
                                    the API will return a list of the 10 most likely tokens.
                                    The API will always return the logprob of the sampled token,
                                    so there may be up to logprobs+1 elements in the response.
       - includePrompt: Whether to include the original prompt in the response.
                        This is mainly useful for debugging purposes.
       - completion: A closure to be called once the request finishes.
                     The closure takes a single argument, the result of the request.

     - SeeAlso: https://beta.openai.com/docs/api-reference/classifications/create
    */
    public func classify(engine id: Engine.ID,
                         query: String,
                         examples: [(String, label: String)],
                         labels: [String]? = nil,
                         searchEngine: Engine.ID? = nil,
                         temperature: Double? = nil,
                         numberOfExamples: PartialRangeThrough<Int>? = nil,
                         includeLogProbabilities: Int? = nil,
                         includePrompt: Bool? = nil,
                         completion: @escaping (Result<Classification, Swift.Error>) -> Void)
    {
        let parameters: [String: Any?] = [
            "model": id.description,
            "query": query,
            "examples": examples.map { [$0.0, $0.label] },
            "labels": labels,
            "search_model": searchEngine?.description,
            "temperature": temperature,
            "logprobs": includeLogProbabilities,
            "max_examples": numberOfExamples?.upperBound,
            "return_prompt": includePrompt,
        ]

        session.request("https://api.openai.com/v1/classifications",
                        method: .post,
                        parameters: parameters.compactMapValues { $0.map(AnyEncodable.init) },
                        encoder: JSONParameterEncoder.default)
            .responseDecodable(of: Response<Classification>.self, queue: .main) { response in
                completion(response.result.flatMap { $0 })
            }
    }

    /**
     Create classification.

     ```
     POST https://api.openai.com/v1/classifications
     ```

     Classifies the specified query using provided examples.

     The endpoint first searches over the labeled examples
     to select the ones most relevant for the particular query.
     Then, the relevant examples are combined with the query
     to construct a prompt to produce the final label via the completions endpoint.

     Labeled examples can be provided via an uploaded file,
     or explicitly listed in the request using the examples parameter
     for quick tests and small scale use cases.

     - Parameters:
       - engine: The engine to use for this request.
       - query: Query to be classified.
       - file: The ID of the uploaded file that contains training examples.
               See upload file for how to upload a file of the desired format and purpose.
       - labels: The set of categories being classified.
                 If not specified, candidate labels will be automatically collected
                 from the examples you provide.
                 All the label strings will be normalized to be capitalized.
       - searchEngine: The engine to use for Search.
       - temperature: What sampling temperature to use.
                      Higher values mean the model will take more risks.
                      Try 0.9 for more creative applications,
                      and 0 (argmax sampling) for ones with a well-defined answer.
       - numberOfExamples: The maximum number of examples to be ranked by Search when using file.
                           Setting it to a higher value leads to improved accuracy
                           but with increased latency and cost.
       - includingLogProbabilities: Include the log probabilities on the logprobs most likely tokens,
                                    as well the chosen tokens.
                                    For example, if logprobs is 10,
                                    the API will return a list of the 10 most likely tokens.
                                    The API will always return the logprob of the sampled token,
                                    so there may be up to logprobs+1 elements in the response.
       - includePrompt: Whether to include the original prompt in the response.
                        This is mainly useful for debugging purposes.
       - completion: A closure to be called once the request finishes.
                     The closure takes a single argument, the result of the request.

     - SeeAlso: https://beta.openai.com/docs/api-reference/classifications/create
    */
    public func classify(engine id: Engine.ID,
                         query: String,
                         file: File.ID,
                         labels: [String]? = nil,
                         searchEngine: Engine.ID? = nil,
                         temperature: Double? = nil,
                         numberOfExamples: PartialRangeThrough<Int>? = nil,
                         includingLogProbabilities logProbabilities: Int? = nil,
                         includePrompt: Bool? = nil,
                         includeMetadata: Bool? = nil,
                         completion: @escaping (Result<Classification, Swift.Error>) -> Void)
    {
        let parameters: [String: Any?] = [
            "model": id.description,
            "query": query,
            "file": file,
            "labels": labels,
            "search_model": searchEngine?.description,
            "temperature": temperature,
            "logprobs": logProbabilities,
            "max_examples": numberOfExamples?.upperBound,
            "return_prompt": includePrompt,
        ]

        session.request("https://api.openai.com/v1/classifications",
                        method: .post,
                        parameters: parameters.compactMapValues { $0.map(AnyEncodable.init) },
                        encoder: JSONParameterEncoder.default)
            .responseDecodable(of: Response<Classification>.self, queue: .main) { response in
                completion(response.result.flatMap { $0 })
            }
    }

    // MARK: Answers

    /**
     Answers the specified question using the provided documents and examples.

     ```
     POST https://api.openai.com/v1/answers
     ```

     The endpoint first searches over provided documents or files to find relevant context.
     The relevant context is combined with the provided examples and question
     to create the prompt for completion.

     - Parameters:
       - engine: The engine to use for this request.
       - question: Question to get answered.
       - examples: List of (question, answer) pairs that will help steer the model
                   towards the tone and answer format you'd like.
                   We recommend adding 2 to 3 examples.
       - file: The ID of an uploaded file that contains documents to search over.
       - searchEngine: The engine to use for Search.
       - temperature: What sampling temperature to use.
                      Higher values mean the model will take more risks
                      and value 0 (argmax sampling) works better
                      for scenarios with a well-defined answer.
       - stop: Up to 4 sequences where the API will stop generating further tokens.
               The returned text will not contain the stop sequence.
       - numberOfDocuments: The maximum number of documents to be ranked by Search when using file.
                            Setting it to a higher value leads to improved accuracy
                            but with increased latency and cost.
       - numberOfTokens: The maximum number of tokens allowed for the generated answer.
       - numberOfAnswers: How many answers to generate for each question.
       - includingLogProbabilities: Include the log probabilities on the logprobs most likely tokens,
                                    as well the chosen tokens.
                                    For example, if logprobs is 10,
                                    the API will return a list of the 10 most likely tokens.
                                    The API will always return the logprob of the sampled token,
                                    so there may be up to logprobs+1 elements in the response.
       - includePrompt: If set to true, the returned JSON will include a "prompt" field
                        containing the final prompt that was used to request a completion.
                        This is mainly useful for debugging purposes.
       - includeMetadata: A special boolean flag for showing metadata.
                          If set to true, each document entry in the returned JSON
                          will contain a "metadata" field.
       - completion: A closure to be called once the request finishes.
                     The closure takes a single argument, the result of the request.

     - SeeAlso: https://beta.openai.com/docs/api-reference/answers/create
     */
    public func answer(engine id: Engine.ID,
                       question: String,
                       examples: (context: String, [(question: String, answer: String)]),
                       documents: [String],
                       searchEngine: Engine.ID,
                       temperature: Double? = nil,
                       stop: [String]? = nil,
                       numberOfDocuments: PartialRangeThrough<Int>? = nil,
                       numberOfTokens: PartialRangeThrough<Int>? = nil,
                       numberOfAnswers: Int? = nil,
                       includingLogProbabilities logProbabilities: Int? = nil,
                       includePrompt: Bool? = nil,
                       includeMetadata: Bool? = nil,
                       completion: @escaping (Result<Answers, Swift.Error>) -> Void)
    {
        let parameters: [String: Any?] = [
            "model": id.description,
            "question": question,
            "examples": examples.1.map { [$0.question, $0.answer] },
            "examples_context": examples.context,
            "documents": documents,
            "search_model": searchEngine.description,
            "max_rerank": numberOfDocuments?.upperBound,
            "temperature": temperature,
            "logprobs": logProbabilities,
            "max_tokens": numberOfTokens?.upperBound,
            "stop": stop,
            "n": numberOfAnswers,
            "return_metadata": includeMetadata,
            "return_prompt": includePrompt
        ]

        session.request("https://api.openai.com/v1/answers",
                        method: .post,
                        parameters: parameters.compactMapValues { $0.map(AnyEncodable.init) },
                        encoder: JSONParameterEncoder.default)
            .responseDecodable(of: Response<Answers>.self, queue: .main) { response in
                completion(response.result.flatMap { $0 })
            }
    }

    /**
     Answers the specified question using the provided file and examples.

     ```
     POST https://api.openai.com/v1/answers
     ```

     The endpoint first searches over provided documents or files to find relevant context.
     The relevant context is combined with the provided examples and question
     to create the prompt for completion.

     - Parameters:
       - engine: The engine to use for this request.
       - question: Question to get answered.
       - examples: List of (question, answer) pairs that will help steer the model
                   towards the tone and answer format you'd like.
                   We recommend adding 2 to 3 examples.
       - documents: List of documents from which the answer for the question should be derived.
                    If this is an empty list,
                    the question will be answered based on the question-answer examples.
       - searchEngine: The engine to use for Search.
       - temperature: What sampling temperature to use.
                      Higher values mean the model will take more risks
                      and value 0 (argmax sampling) works better
                      for scenarios with a well-defined answer.
       - stop: Up to 4 sequences where the API will stop generating further tokens.
               The returned text will not contain the stop sequence.
       - numberOfDocuments: The maximum number of documents to be ranked by Search when using file.
                            Setting it to a higher value leads to improved accuracy
                            but with increased latency and cost.
       - numberOfTokens: The maximum number of tokens allowed for the generated answer.
       - numberOfAnswers: How many answers to generate for each question.
       - includingLogProbabilities: Include the log probabilities on the logprobs most likely tokens,
                                    as well the chosen tokens.
                                    For example, if logprobs is 10,
                                    the API will return a list of the 10 most likely tokens.
                                    The API will always return the logprob of the sampled token,
                                    so there may be up to logprobs+1 elements in the response.
       - includePrompt: If set to true, the returned JSON will include a "prompt" field
                        containing the final prompt that was used to request a completion.
                        This is mainly useful for debugging purposes.
       - includeMetadata: A special boolean flag for showing metadata.
                          If set to true, each document entry in the returned JSON
                          will contain a "metadata" field.
       - completion: A closure to be called once the request finishes.
                     The closure takes a single argument, the result of the request.

     - SeeAlso: https://beta.openai.com/docs/api-reference/answers/create
     */
    public func answer(engine id: Engine.ID,
                       question: String,
                       examples: (context: String, [(question: String, answer: String)]),
                       file: File.ID,
                       searchEngine: Engine.ID,
                       temperature: Double? = nil,
                       stop: [String]? = nil,
                       numberOfDocuments: PartialRangeThrough<Int>? = nil,
                       numberOfTokens: PartialRangeThrough<Int>? = nil,
                       numberOfAnswers: Int? = nil,
                       includingLogProbabilities logProbabilities: Int? = nil,
                       includePrompt: Bool? = nil,
                       includeMetadata: Bool? = nil,
                       completion: @escaping (Result<Answers, Swift.Error>) -> Void)
    {
        let parameters: [String: Any?] = [
            "model": id.description,
            "question": question,
            "examples": examples.1.map { [$0.question, $0.answer] },
            "examples_context": examples.context,
            "file": file,
            "search_model": searchEngine.description,
            "max_rerank": numberOfDocuments?.upperBound,
            "temperature": temperature,
            "logprobs": logProbabilities,
            "max_tokens": numberOfTokens?.upperBound,
            "stop": stop,
            "n": numberOfAnswers,
            "return_metadata": includeMetadata,
            "return_prompt": includePrompt
        ]

        session.request("https://api.openai.com/v1/answers",
                        method: .post,
                        parameters: parameters.compactMapValues { $0.map(AnyEncodable.init) },
                        encoder: JSONParameterEncoder.default)
            .responseDecodable(of: Response<Answers>.self, queue: .main) { response in
                completion(response.result.flatMap { $0 })
            }
    }

    // MARK: Files

    /**
     Returns a list of files that belong to the user's organization.

     ```
     GET https://api.openai.com/v1/files
     ```

     - Parameters:
       - completion: A closure to be called once the request finishes.
                     The closure takes a single argument, the result of the request.

     - SeeAlso: https://beta.openai.com/docs/api-reference/files/list

     */
    public func files(completion: @escaping (Result<[File], Swift.Error>) -> Void) {
        session.request("https://api.openai.com/v1/files", method: .get)
            .responseDecodable(of: Response<[File]>.self, queue: .main) { response in
                completion(response.result.flatMap { $0 })
            }
    }

    /**
     Upload a file that contains document(s) to be used across various endpoints/features.

     ```
     POST https://api.openai.com/v1/files
     ```

     Currently, the size of all the files uploaded by one organization can be up to 1 GB.
     Please contact us if you need to increase the storage limit.

     - Parameters:
        - lines: An array of objects to be encoded as JSON Lines.
        - purpose: The intended purpose of the uploaded documents.
        - completion: A closure to be called once the request finishes.
                      The closure takes a single argument, the result of the request.

     - SeeAlso: https://beta.openai.com/docs/api-reference/files/upload
     */
    public func uploadFile(_ lines: [AnyEncodable],
                           with purpose: File.Purpose,
                           completion: @escaping (Result<File, Swift.Error>) -> Void)
    {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(lines)
            uploadFile(data, with: purpose, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    /**
     Upload a file that contains document(s) to be used across various endpoints/features.

     ```
     POST https://api.openai.com/v1/files
     ```

     Currently, the size of all the files uploaded by one organization can be up to 1 GB.
     Please contact us if you need to increase the storage limit.

     - Parameters:
        - data: A data respresentation of a JSON Lines file.
        - purpose: The intended purpose of the uploaded documents.
        - completion: A closure to be called once the request finishes.
                      The closure takes a single argument, the result of the request.

     - SeeAlso: https://beta.openai.com/docs/api-reference/files/upload
     */
    public func uploadFile(_ data: Data,
                           with purpose: File.Purpose,
                           completion: @escaping (Result<File, Swift.Error>) -> Void)
    {
        session.upload(multipartFormData: { (multipart) in
            multipart.append(purpose.rawValue.data(using: .utf8)!, withName: "purpose")
            multipart.append(data, withName: "file")
        }, to: "https://api.openai.com/v1/files", method: .post)
            .responseDecodable(of: Response<File>.self, queue: .main) { response in
                completion(response.result.flatMap { $0 })
            }
    }

    /**
     Upload a file that contains document(s) to be used across various endpoints/features.

     ```
     POST https://api.openai.com/v1/files
     ```

     Currently, the size of all the files uploaded by one organization can be up to 1 GB.
     Please contact us if you need to increase the storage limit.

     - Parameters:
        - url: A URL to a JSON Lines file.
        - purpose: The intended purpose of the uploaded documents.
        - completion: A closure to be called once the request finishes.
                      The closure takes a single argument, the result of the request.

     - SeeAlso: https://beta.openai.com/docs/api-reference/files/upload
     */
    public func uploadFile(_ url: URL,
                           length: UInt64,
                           with purpose: File.Purpose,
                           completion: @escaping (Result<File, Swift.Error>) -> Void)
    {
        session.upload(multipartFormData: { (multipart) in
            multipart.append(purpose.rawValue.data(using: .utf8)!, withName: "purpose")
            multipart.append(url, withName: "file")
        }, to: "https://api.openai.com/v1/files", method: .post)
            .responseDecodable(of: Response<File>.self, queue: .main) { response in
                completion(response.result.flatMap { $0 })
            }
    }

    /**
     Upload a file that contains document(s) to be used across various endpoints/features.

     ```
     POST https://api.openai.com/v1/files
     ```

     Currently, the size of all the files uploaded by one organization can be up to 1 GB.
     Please contact us if you need to increase the storage limit.

     - Parameters:
        - stream: An input stream to a JSON Lines file.
        - purpose: The intended purpose of the uploaded documents.
        - completion: A closure to be called once the request finishes.
                      The closure takes a single argument, the result of the request.

     - SeeAlso: https://beta.openai.com/docs/api-reference/files/upload
     */
    public func uploadFile(_ stream: InputStream,
                           length: UInt64,
                           with purpose: File.Purpose,
                           completion: @escaping (Result<File, Swift.Error>) -> Void)
    {
        session.upload(multipartFormData: { (multipart) in
            multipart.append(purpose.rawValue.data(using: .utf8)!, withName: "purpose")
            multipart.append(stream, withLength: length, headers: [:])
        }, to: "https://api.openai.com/v1/files", method: .post)
            .responseDecodable(of: Response<File>.self, queue: .main) { response in
                completion(response.result.flatMap { $0 })
            }
    }

    /**
     Returns information about a specific file.

     ```
     GET https://api.openai.com/v1/files/{file_id}
     ```

     - Parameters:
       - id: The ID of the file to use for this request.
       - completion: A closure to be called once the request finishes.
                     The closure takes a single argument, the result of the request.

     - SeeAlso: https://beta.openai.com/docs/api-reference/files/retrieve
     */
    public func file(id: File.ID,
                     completion: @escaping (Result<File, Swift.Error>) -> Void)
    {
        session.request("https://api.openai.com/v1/files/\(id)", method: .get)
            .responseDecodable(of: Response<File>.self, queue: .main) { response in
                completion(response.result.flatMap { $0 })
            }
    }

    /**
     Delete a file.

     ```
     DELETE https://api.openai.com/v1/files/{file_id}
     ```

     Only owners of organizations can delete files currently.

     - Parameters:
        - id: The ID of the file to use for this request
        - completion: A closure to be called once the request finishes.
                      The closure takes a single argument, the result of the request.

     - SeeAlso: https://beta.openai.com/docs/api-reference/files/delete
     */
    public func deleteFile(id: File.ID,
                           completion: @escaping (Result<Void, Swift.Error>) -> Void)
    {
        session.request("https://api.openai.com/v1/files", method: .delete)
            .response { response in
                switch response.result {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
}

// MARK: - CustomStringConvertible

extension Client.Error: CustomStringConvertible {
    public var description: String {
        return message
    }
}

// MARK: - CustomStringConvertible

extension Client.Error: CustomDebugStringConvertible {
    public var debugDescription: String {
        var description = "Error"

        if let code = code {
            description += " (\(code))"
        }

        description += " \(type) -"

        if let param = param {
            description += " \(param):"
        }

        description += " \(message)"

        return description
    }
}

// MARK: - LocalizedError

extension Client.Error: LocalizedError {
    public var errorDescription: String? {
        return message
    }

    public var failureReason: String? {
        return param
    }
}

// MARK: -

fileprivate enum Response<Value>: Decodable where Value: Decodable {
    case success(Value)
    case failure(Error)

    private enum CodingKeys: String, CodingKey {
        case data
        case error
    }

    init(from decoder: Decoder) throws {
        if let value = try? Value(from: decoder) {
            self = .success(value)
        } else if let error = try? Client.Error(from: decoder) {
            self = .failure(error)
        } else if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            if let value = try? container.decode(Value.self, forKey: .data) {
                self = .success(value)
            } else if let error = try? container.decode(Client.Error.self, forKey: .error) {
                self = .failure(error)
            } else {
                let context = DecodingError.Context(codingPath: [], debugDescription: "unable to decode value or error")
                throw DecodingError.dataCorrupted(context)
            }
        } else {
            let context = DecodingError.Context(codingPath: [], debugDescription: "unable to decode value or error")
            throw DecodingError.dataCorrupted(context)
        }
    }
}

fileprivate extension Result {
    func flatMap<T, U>(_ transform: (T) -> U) -> Result<U, Error> where Success == Response<T> {
        switch self {
        case .success(.success(let value)):
            return .success(transform(value))
        case .success(.failure(let error)):
            return .failure(error)
        case .failure(let error):
            return .failure(error)
        }
    }
}
