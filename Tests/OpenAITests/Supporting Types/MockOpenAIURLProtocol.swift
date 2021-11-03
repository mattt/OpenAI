import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

import Dispatch

public final class MockOpenAIURLProtocol: URLProtocol {
    public enum Error: Swift.Error {
        case unhandled
        case unknown
    }

    private let queue = DispatchQueue(label: "com.openai.test")
    private var workItem: DispatchWorkItem?

    // MARK: - URLProtocol

    override public class func canInit(with request: URLRequest) -> Bool {
        return request.url?.host?.hasSuffix("openai.com") ?? false
    }

    public override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override public func startLoading() {
        let delay: DispatchTimeInterval = .milliseconds(100)

        let workItem = DispatchWorkItem(qos: .userInitiated, flags: []) { [weak self] in
            guard let self = self else { return }

            var json: String?

            switch (self.request.httpMethod, self.request.url?.absoluteString) {
            case ("GET", "https://api.openai.com/v1/engines"):
                json = #"""

                """#

            case ("GET", "https://api.openai.com/v1/engines/ada"):
                json = #"""
                    {
                        "id": "ada",
                        "owner": "openai",
                        "ready": true
                    }

                """#

            case ("POST", "https://api.openai.com/v1/engines/content-filter-alpha/completions"):
                json = #"""
                    {
                        "id": "cmpl-40AKATjmi5zugJr8nGfHTDbo7SR7G",
                        "object": "text_completion",
                        "created": 1635945034,
                        "model": "toxicity-double-18",
                        "choices": [
                            {
                                "text": "0",
                                "index": 0,
                                "logprobs": {
                                    "tokens": [
                                        "0"
                                    ],
                                    "token_logprobs": [
                                        -0.001167275
                                    ],
                                    "top_logprobs": [
                                        {
                                            "0": -0.001167275,
                                            "1": -8.242511,
                                            "2": -7.0130115,
                                            "3": -14.688963,
                                            "5": -15.609307
                                        }
                                    ],
                                    "text_offset": [
                                        133
                                    ]
                                },
                                "finish_reason": "length"
                            }
                        ]
                    }
                """#
                
            case ("POST", "https://api.openai.com/v1/engines/davinci/completions"):
                json = #"""
                    {
                        "id": "cmpl-39DDgiNB7jh1k9GrmRvYmGChlZA6G",
                        "created": 1623324780,
                        "model": "davinci:2020-05-03",
                        "choices": [
                            {
                                "index": 0,
                                "text": "\nMake chili (traditionally \"chili con carne\" (literally \"chili with",
                                "finish_reason": "length"
                            }
                        ]
                    }
                """#

            case ("POST", "https://api.openai.com/v1/engines/davinci/search"):
                json = #"""
                    [
                        {
                            "document": 0,
                            "score": 487.666
                        },
                        {
                            "document": 1,
                            "score": 240.29499999999999
                        },
                        {
                            "document": 2,
                            "score": 156.67099999999999
                        }
                    ]

                """#

            case ("POST", "https://api.openai.com/v1/classifications"):
                json = #"""
                    {
                        "search_model": "ada",
                        "label": "Negative",
                        "model": "curie:2020-05-03",
                        "selected_examples": [
                            {
                                "document": 1,
                                "label": "Negative",
                                "text": "I am sad."
                            },
                            {
                                "document": 0,
                                "label": "Positive",
                                "text": "A happy moment"
                            },
                            {
                                "document": 2,
                                "label": "Positive",
                                "text": "I am feeling awesome"
                            }
                        ],
                        "completion": "cmpl-39DDfnON0L1z1wO6iU5IUMriRPPbH"
                    }

                """#

            case ("POST", "https://api.openai.com/v1/answers"):
                json = #"""
                    {
                        "search_model": "ada",
                        "answers": [
                            "puppy A."
                        ],
                        "model": "curie:2020-05-03",
                        "completion": "cmpl-39DDfoafHcHQAbqMk7AUNyhyshLQo",
                        "selected_documents": [
                            {
                                "document": 0,
                                "text": "Puppy A is happy. "
                            },
                            {
                                "document": 1,
                                "text": "Puppy B is sad. "
                            }
                        ]
                    }

                """#

            default:
                self.client?.urlProtocol(self, didFailWithError: Error.unhandled)
                return
            }

            self.client?.urlProtocol(self, didFinishLoadingResponseForRequest: self.request, statusCode: 200, data: json?.data(using: .utf8))
        }

        self.workItem = workItem
        self.queue.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    override public func stopLoading() {
        self.workItem?.cancel()
    }
}

private extension URLProtocolClient {
    func urlProtocol(_ protocol: URLProtocol,
                     didFinishLoadingResponseForRequest request: URLRequest,
                     statusCode: Int,
                     headerFields: [String: String]? = nil,
                     cacheStoragePolicy policy: URLCache.StoragePolicy = .notAllowed,
                     data: Data? = nil)
    {
        guard let url = request.url,
              let response = HTTPURLResponse(url: url,
                                             statusCode: statusCode,
                                             httpVersion: "HTTP/1.1",
                                             headerFields: headerFields)
        else {
            self.urlProtocol(`protocol`, didFailWithError: MockOpenAIURLProtocol.Error.unknown)
            return
        }

        self.urlProtocol(`protocol`, didReceive: response, cacheStoragePolicy: policy)
        self.urlProtocol(`protocol`, didLoad: data ?? Data())
        self.urlProtocolDidFinishLoading(`protocol`)
    }
}
