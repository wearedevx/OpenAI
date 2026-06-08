//
//  StreamingError.swift
//  OpenAI
//
//  Created by Oleksii Nezhyborets on 03.02.2025.
//

import Foundation

enum StreamingError: DescribedError, CustomStringConvertible {
    case unknownContent
    case emptyContent

    var errorDescription: String? {
        switch self {
        case .unknownContent:
            "Unable to decode streaming content. Expected UTF-8 encoded stream data in an OpenAI-compatible format."
        case .emptyContent:
            "Received empty streaming content. Expected stream data in an OpenAI-compatible format."
        }
    }

    var failureReason: String? {
        switch self {
        case .unknownContent:
            "The server sent stream data that could not be decoded as UTF-8 text."
        case .emptyContent:
            "The server sent a stream message without any usable content."
        }
    }

    var recoverySuggestion: String? {
        "Verify that the server is using an OpenAI-compatible streaming format. If you are using a local provider such as LM Studio, inspect the raw stream payload for non-OpenAI-compatible status or binary data."
    }

    var description: String {
        errorDescription ?? String(describing: self)
    }
}
