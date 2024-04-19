//
//  StreamingSession.swift
//
//
//  Created by Sergii Kryvoblotskyi on 18/04/2023.
//

import Foundation
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

final class StreamingSession<ResultType: Codable>: NSObject, Identifiable, URLSessionDelegate, URLSessionDataDelegate {
    enum StreamingError: Error {
        case unknownContent
        case emptyContent
    }

    var onReceiveContent: ((StreamingSession, ResultType) -> Void)?
    var onProcessingError: ((StreamingSession, Error) -> Void)?
    var onComplete: ((StreamingSession, Error?) -> Void)?

    private let streamingCompletionMarker = "[DONE]"
    private let urlRequest: URLRequest
    private lazy var urlSession: URLSession = {
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        return session
    }()

    private var previousChunkBuffer = ""
    private var dataTask: URLSessionDataTask?

    init(urlRequest: URLRequest) {
        self.urlRequest = urlRequest
    }

    func perform() {
        dataTask = urlSession
            .dataTask(with: urlRequest)

        dataTask?.resume()
    }

    // func cancel() {
    //     dataTask?.cancel()
    // }

    func urlSession(_: URLSession, task _: URLSessionTask, didCompleteWithError error: Error?) {
        onComplete?(self, error)
    }

    func urlSession(_: URLSession, dataTask _: URLSessionDataTask, didReceive data: Data) {
        guard let stringContent = String(data: data, encoding: .utf8) else {
            onProcessingError?(self, StreamingError.unknownContent)
            return
        }
        processJSON(from: stringContent)
    }
}

extension StreamingSession {
    private func processJSON(from stringContent: String) {
        if stringContent.isEmpty {
            return
        }
        // NOTE: if the json content includes data: this causes a problem. i've fixed it by preprending a newline character to the previousChunkBuffer, since all except the first chunk have two newlines anyway. not perfect, but it will help
        let jsonObjects = "\n\(previousChunkBuffer)\(stringContent)"
            // .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: "\ndata:")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }

        previousChunkBuffer = ""

        guard jsonObjects.isEmpty == false, jsonObjects.first != streamingCompletionMarker else {
            return
        }
        for (index, jsonContent) in jsonObjects.enumerated() {
            guard jsonContent != streamingCompletionMarker, !jsonContent.isEmpty else {
                continue
            }
            guard let jsonData = jsonContent.data(using: .utf8) else {
                onProcessingError?(self, StreamingError.unknownContent)
                continue
            }
            let decoder = JSONDecoder()
            do {
                let object = try decoder.decode(ResultType.self, from: jsonData)
                onReceiveContent?(self, object)
            } catch {
                if let decoded = try? decoder.decode(APIErrorResponse.self, from: jsonData) {
                    onProcessingError?(self, decoded)
                } else if index == jsonObjects.count - 1 {
                    previousChunkBuffer = "data: \(jsonContent)" // Chunk ends in a partial JSON
                } else {
                    onProcessingError?(self, error)
                }
            }
        }
    }
}

extension StreamingSession: CancelableProtocol {
    func cancel() {
        dataTask?.cancel()
    }
}
