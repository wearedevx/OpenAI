//
//  OpenAIProtocol+Async.swift
//
//
//  Created by Maxime Maheo on 10/02/2023.
//

import Combine
import Foundation

@available(iOS 13.0, *)
@available(macOS 12, *)
@available(tvOS 13.0, *)
@available(watchOS 6.0, *)
public extension OpenAIProtocol {
    func completions(
        query: CompletionsQuery
    ) async throws -> CompletionsResult {
        try await (Future<CompletionsResult, Error> { promise in
            completions(query: query) { result in
                promise(result)
            }
        }).value
    }

    func completionsStream(
        query: CompletionsQuery
    ) -> AsyncThrowingStream<CompletionsResult, Error> {
        return AsyncThrowingStream { continuation in
            completionsStream(query: query) { result in
                continuation.yield(with: result)
            } completion: { error in
                continuation.finish(throwing: error)
            }
        }
    }

    func images(
        query: ImagesQuery
    ) async throws -> ImagesResult {
        try await (Future<ImagesResult, Error> { promise in
            images(query: query) { result in
                promise(result)
            }
        }).value
    }

    func imageEdits(
        query: ImageEditsQuery
    ) async throws -> ImagesResult {
        try await (Future<ImagesResult, Error> { promise in
            imageEdits(query: query) { result in
                promise(result)
            }
        }).value
    }

    func imageVariations(
        query: ImageVariationsQuery
    ) async throws -> ImagesResult {
        try await (Future<ImagesResult, Error> { promise in
            imageVariations(query: query) { result in
                promise(result)
            }
        }).value
    }

    func embeddings(
        query: EmbeddingsQuery
    ) async throws -> EmbeddingsResult {
        try await (Future<EmbeddingsResult, Error> { promise in
            embeddings(query: query) { result in
                promise(result)
            }
        }).value
    }

    func chats(
        query: ChatQuery
    ) async throws -> ChatResult {
        try await (Future<ChatResult, Error> { promise in
            chats(query: query) { result in
                promise(result)
            }
        }).value
    }

    func chatsStream(
        query: ChatQuery
    ) -> AsyncThrowingStream<ChatStreamResult, Error> {
        return AsyncThrowingStream { continuation in
            let session = chatsStream(query: query) { result in
                continuation.yield(with: result)
            } completion: { error in
                continuation.finish(throwing: error)
            }
        }
    }

    func edits(
        query: EditsQuery
    ) async throws -> EditsResult {
        try await (Future<EditsResult, Error> { promise in
            edits(query: query) { result in
                promise(result)
            }
        }).value
    }

    func model(
        query: ModelQuery
    ) async throws -> ModelResult {
        try await (Future<ModelResult, Error> { promise in
            model(query: query) { result in
                promise(result)
            }
        }).value
    }

    func models() async throws -> ModelsResult {
        try await (Future<ModelsResult, Error> { promise in
            models { result in
                promise(result)
            }
        }).value
    }

    func moderations(
        query: ModerationsQuery
    ) async throws -> ModerationsResult {
        try await (Future<ModerationsResult, Error> { promise in
            moderations(query: query) { result in
                promise(result)
            }
        }).value
    }

    func audioCreateSpeech(
        query: AudioSpeechQuery
    ) async throws -> AudioSpeechResult {
        try await (Future<AudioSpeechResult, Error> { promise in
            audioCreateSpeech(query: query) { result in
                promise(result)
            }
        }).value
    }

    func audioTranscriptions(
        query: AudioTranscriptionQuery
    ) async throws -> AudioTranscriptionResult {
        try await (Future<AudioTranscriptionResult, Error> { promise in
            audioTranscriptions(query: query) { result in
                promise(result)
            }
        }).value
    }

    func audioTranslations(
        query: AudioTranslationQuery
    ) async throws -> AudioTranslationResult {
        try await (Future<AudioTranslationResult, Error> { promise in
            audioTranslations(query: query) { result in
                promise(result)
            }
        }).value
    }
}
