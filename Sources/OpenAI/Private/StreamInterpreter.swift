//
//  StreamInterpreter.swift
//  OpenAI
//
//  Created by Oleksii Nezhyborets on 03.02.2025.
//

import Foundation

/// https://html.spec.whatwg.org/multipage/server-sent-events.html#event-stream-interpretation
/// 9.2.6 Interpreting an event stream
class StreamInterpreter<ResultType: Codable> {
    private let streamingCompletionMarker = "[DONE]"
    private var previousChunkBuffer = ""

    var onEventDispatched: ((ResultType) -> Void)?

    func processData(_ data: Data) throws {
        let decoder = JSONDecoder()
        if let decoded = try? decoder.decode(APIErrorResponse.self, from: data) {
            throw decoded
        }

        guard let stringContent = String(data: data, encoding: .utf8) else {
            throw StreamingError.unknownContent
        }
        try processJSON(from: stringContent)
    }

    private func processJSON(from stringContent: String) throws {
        if stringContent.isEmpty {
            return
        }

        let fullChunk = "\(previousChunkBuffer)\(stringContent)"
        let chunkLines = fullChunk
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }

        var jsonObjects: [String] = []
        for line in chunkLines {
            // Skip comments
            if line.starts(with: ":") { continue }

            // Get JSON object
            let jsonData = line
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .split(separator: "data: ", maxSplits: 1, omittingEmptySubsequences: true)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { $0.isEmpty == false }
            jsonObjects.append(contentsOf: jsonData)
        }

        previousChunkBuffer = ""

        guard jsonObjects.isEmpty == false, jsonObjects.first != streamingCompletionMarker else {
            return
        }

        while !jsonObjects.isEmpty {
            let jsonContent = jsonObjects.removeFirst()
            guard jsonContent != streamingCompletionMarker, !jsonContent.isEmpty else { continue }

            guard let jsonData = jsonContent.data(using: .utf8) else {
                throw StreamingError.unknownContent
            }
            let decoder = JSONDecoder()
            do {
                let object = try decoder.decode(ResultType.self, from: jsonData)
                onEventDispatched?(object)
            } catch {
                if let decoded = try? decoder.decode(APIErrorResponse.self, from: jsonData) {
                    throw decoded
                }
                // This is a partial JSON object, prepend it to the next
                // object in the queue
                else if !jsonObjects.isEmpty {
                    jsonObjects[0] = jsonContent + jsonObjects[0]
                }
                // This is the last object in the chunk and parsing failed:
                // The chunk ended in a partail JSON object
                else if jsonObjects.isEmpty {
                    previousChunkBuffer = "data: \(jsonContent)" // Chunk ends in a partial JSON
                } else {
                    throw error
                }
            }
        }

        try jsonObjects.enumerated().forEach { _, jsonContent in
            guard jsonContent != streamingCompletionMarker, !jsonContent.isEmpty else {
                return
            }
        }
    }
}
