//
//  ServerSentEventsStreamInterpreter.swift
//  OpenAI
//
//  Created by Oleksii Nezhyborets on 11.03.2025.
//

import Foundation

/// https://html.spec.whatwg.org/multipage/server-sent-events.html#event-stream-interpretation
/// 9.2.6 Interpreting an event stream
///
/// - Note: This class is NOT thread safe. It is a caller's responsibility to call all the methods in a thread-safe manner.
final class ServerSentEventsStreamInterpreter <ResultType: Codable & Sendable>: @unchecked Sendable, StreamInterpreter {
    private let parser = ServerSentEventsStreamParser()
    private let streamingCompletionMarker = "[DONE]"
    private var previousChunkBuffer = ""
    
    private var onEventDispatched: ((ResultType) -> Void)?
    private var onError: ((Error) -> Void)?
    private let parsingOptions: ParsingOptions
    
    enum InterpreterError: DescribedError, CustomStringConvertible {
        case unhandledStreamEventType(eventType: String, eventData: String, resultType: String)

        var errorDescription: String? {
            switch self {
            case .unhandledStreamEventType(let eventType, let eventData, let resultType):
                "Unhandled server-sent event type \"\(eventType)\" while decoding \(resultType). Expected \"message\" events containing JSON stream chunks or \"[DONE]\". Event data: \(eventData)"
            }
        }

        var failureReason: String? {
            switch self {
            case .unhandledStreamEventType(let eventType, _, _):
                "The server sent an SSE event named \"\(eventType)\", but this stream interpreter only supports default \"message\" events."
            }
        }

        var recoverySuggestion: String? {
            "Verify that the server is using an OpenAI-compatible chat completions streaming format. If you are using a local provider such as LM Studio, check whether it emits non-OpenAI SSE event names or provider status events."
        }

        var description: String {
            errorDescription ?? String(describing: self)
        }
    }
    
    init(parsingOptions: ParsingOptions) {
        self.parsingOptions = parsingOptions
        
        parser.setCallbackClosures { [weak self] event in
            self?.processEvent(event)
        } onError: { [weak self] error in
            self?.onError?(error)
        }
    }
    
    /// Sets closures an instance of type. Not thread safe.
    ///
    /// - Parameters:
    ///     - onEventDispatched: Can be called multiple times per `processData`
    ///     - onError: Will only be called once per `processData`
    func setCallbackClosures(onEventDispatched: @escaping @Sendable (ResultType) -> Void, onError: @escaping @Sendable (Error) -> Void) {
        self.onEventDispatched = onEventDispatched
        self.onError = onError
    }
    
    /// Not thread safe
    func processData(_ data: Data) {
        let decoder = JSONDecoder()
        if let decoded = JSONResponseErrorDecoder(decoder: decoder).decodeErrorResponse(data: data) {
            onError?(decoded)
            return
        }
        
        parser.processData(data: data)
    }
    
    private func processEvent(_ event: ServerSentEventsStreamParser.Event) {
        switch event.eventType {
        case "message":
            let jsonContent = event.decodedData
            guard jsonContent != streamingCompletionMarker && !jsonContent.isEmpty else {
                return
            }
            guard let jsonData = jsonContent.data(using: .utf8) else {
                onError?(StreamingError.unknownContent)
                return
            }
            
            let decoder = JSONResponseDecoder(parsingOptions: parsingOptions)
            do {
                let object: ResultType = try decoder.decodeResponseData(jsonData)
                onEventDispatched?(object)
            } catch {
                onError?(error)
            }
        default:
            onError?(
                InterpreterError.unhandledStreamEventType(
                    eventType: event.eventType,
                    eventData: eventDataPreview(event),
                    resultType: String(reflecting: ResultType.self)
                )
            )
        }
    }

    private func eventDataPreview(_ event: ServerSentEventsStreamParser.Event) -> String {
        let maxLength = 500
        let eventData = String(data: event.data, encoding: .utf8) ?? "<non-UTF-8 data: \(event.data.count) bytes>"

        if eventData.count <= maxLength {
            return eventData
        }

        return "\(eventData.prefix(maxLength))..."
    }
}
