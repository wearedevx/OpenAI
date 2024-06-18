//
//  OpenAI.swift
//
//
//  Created by Sergii Kryvoblotskyi on 9/18/22.
//

import Foundation
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

public final class OpenAI: OpenAIProtocol {
    public struct Configuration {
        /// OpenAI API token. See https://platform.openai.com/docs/api-reference/authentication
        public let token: String

        /// Optional OpenAI organization identifier. See https://platform.openai.com/docs/api-reference/authentication
        public let organizationIdentifier: String?

        /// Optional OpenRouter classification. See https://openrouter.ai/docs/quick-start
        public let appName: String?
        /// Optional OpenRouter classification. See https://openrouter.ai/docs/quick-start
        public let siteURL: String?

        /// API host. Set this property if you use some kind of proxy or your own server. Default is api.openai.com
        public let host: String
        public let port: Int
        public let scheme: String
        public let prefix: String
        /// Default request timeout
        public let timeoutInterval: TimeInterval

        public init(token: String, organizationIdentifier: String? = nil, appName: String? = nil, siteURL: String? = nil, host: String = "api.openai.com", timeoutInterval: TimeInterval = 60.0) {
            self.token = token
            self.organizationIdentifier = organizationIdentifier
            self.appName = appName
            self.siteURL = siteURL
            self.host = host
            port = port
            scheme = scheme
            self.timeoutInterval = timeoutInterval
            prefix = prefix
        }
    }

    private let session: URLSessionProtocol
    private var streamingSessions = ArrayWithThreadSafety<NSObject>()

    public let configuration: Configuration

    public convenience init(apiToken: String) {
        self.init(configuration: Configuration(token: apiToken), session: URLSession.shared)
    }

    public convenience init(configuration: Configuration) {
        self.init(configuration: configuration, session: URLSession.shared)
    }

    init(configuration: Configuration, session: URLSessionProtocol) {
        self.configuration = configuration
        self.session = session
    }

    public convenience init(configuration: Configuration, session: URLSession = URLSession.shared) {
        self.init(configuration: configuration, session: session as URLSessionProtocol)
    }

    public func completions(query: CompletionsQuery, completion: @escaping (Result<CompletionsResult, Error>) -> Void) {
        guard let url = buildURL(path: .completions) else {
            completion(.failure(OpenAIError.invalidURL))
            return
        }

        performRequest(request: JSONRequest<CompletionsResult>(body: query, url: url), completion: completion)
    }

    public func completionsStream(query: CompletionsQuery, onResult: @escaping (Result<CompletionsResult, Error>) -> Void, completion: ((Error?) -> Void)?) {
        guard let url = buildURL(path: .completions) else {
            completion?(OpenAIError.invalidURL)
            return
        }

        performStreamingRequest(request: JSONRequest<CompletionsResult>(body: query.makeStreamable(), url: url), onResult: onResult, completion: completion)
    }

    public func images(query: ImagesQuery, completion: @escaping (Result<ImagesResult, Error>) -> Void) {
        guard let url = buildURL(path: .images) else {
            completion(.failure(OpenAIError.invalidURL))
            return
        }

        performRequest(request: JSONRequest<ImagesResult>(body: query, url: url), completion: completion)
    }

    public func imageEdits(query: ImageEditsQuery, completion: @escaping (Result<ImagesResult, Error>) -> Void) {
        guard let url = buildURL(path: .imageEdits) else {
            completion(.failure(OpenAIError.invalidURL))
            return
        }

        performRequest(request: MultipartFormDataRequest<ImagesResult>(body: query, url: url), completion: completion)
    }

    public func imageVariations(query: ImageVariationsQuery, completion: @escaping (Result<ImagesResult, Error>) -> Void) {
        guard let url = buildURL(path: .imageVariations) else {
            completion(.failure(OpenAIError.invalidURL))
            return
        }

        performRequest(request: MultipartFormDataRequest<ImagesResult>(body: query, url: url), completion: completion)
    }

    public func embeddings(query: EmbeddingsQuery, completion: @escaping (Result<EmbeddingsResult, Error>) -> Void) {
        guard let url = buildURL(path: .embeddings) else {
            completion(.failure(OpenAIError.invalidURL))
            return
        }

        performRequest(request: JSONRequest<EmbeddingsResult>(body: query, url: url), completion: completion)
    }

    public func chats(query: ChatQuery, completion: @escaping (Result<ChatResult, Error>) -> Void) {
        guard let url = buildURL(path: .chats) else {
            completion(.failure(OpenAIError.invalidURL))
            return
        }

        performRequest(request: JSONRequest<ChatResult>(body: query, url: url), completion: completion)
    }

    public func chatsStream(query: ChatQuery, onResult: @escaping (Result<ChatStreamResult, Error>) -> Void, completion: ((Error?) -> Void)?) -> (any CancelableProtocol)? {
        guard let url = buildURL(path: .chats) else {
            completion?(OpenAIError.invalidURL)
            return nil
        }

        return performStreamingRequest(request: JSONRequest<ChatStreamResult>(body: query.makeStreamable(), url: url), onResult: onResult, completion: completion)
    }

    public func edits(query: EditsQuery, completion: @escaping (Result<EditsResult, Error>) -> Void) {
        guard let url = buildURL(path: .edits) else {
            completion(.failure(OpenAIError.invalidURL))
            return
        }

        performRequest(request: JSONRequest<EditsResult>(body: query, url: url), completion: completion)
    }

    public func model(query: ModelQuery, completion: @escaping (Result<ModelResult, Error>) -> Void) {
        guard let url = buildURL(path: .models.withPath(query.model)) else {
            completion(.failure(OpenAIError.invalidURL))
            return
        }

        performRequest(request: JSONRequest<ModelResult>(url: url, method: "GET"), completion: completion)
    }

    public func models(completion: @escaping (Result<ModelsResult, Error>) -> Void) {
        guard let url = buildURL(path: .models) else {
            completion(.failure(OpenAIError.invalidURL))
            return
        }

        performRequest(request: JSONRequest<ModelsResult>(url: url, method: "GET"), completion: completion)
    }

    @available(iOS 13.0, *)
    public func moderations(query: ModerationsQuery, completion: @escaping (Result<ModerationsResult, Error>) -> Void) {
        guard let url = buildURL(path: .moderations) else {
            completion(.failure(OpenAIError.invalidURL))
            return
        }

        performRequest(request: JSONRequest<ModerationsResult>(body: query, url: url), completion: completion)
    }

    public func audioTranscriptions(query: AudioTranscriptionQuery, completion: @escaping (Result<AudioTranscriptionResult, Error>) -> Void) {
        guard let url = buildURL(path: .audioTranscriptions) else {
            completion(.failure(OpenAIError.invalidURL))
            return
        }

        performRequest(request: MultipartFormDataRequest<AudioTranscriptionResult>(body: query, url: url), completion: completion)
    }

    public func audioTranslations(query: AudioTranslationQuery, completion: @escaping (Result<AudioTranslationResult, Error>) -> Void) {
        guard let url = buildURL(path: .audioTranslations) else {
            completion(.failure(OpenAIError.invalidURL))
            return
        }

        performRequest(request: MultipartFormDataRequest<AudioTranslationResult>(body: query, url: url), completion: completion)
    }

    public func audioCreateSpeech(query: AudioSpeechQuery, completion: @escaping (Result<AudioSpeechResult, Error>) -> Void) {
        guard let url = buildURL(path: .audioSpeech) else {
            completion(.failure(OpenAIError.invalidURL))
            return
        }
        performSpeechRequest(request: JSONRequest<AudioSpeechResult>(body: query, url: url), completion: completion)
    }
}

extension OpenAI {
    func performRequest<ResultType: Codable>(request: any URLRequestBuildable, completion: @escaping (Result<ResultType, Error>) -> Void) -> URLSessionDataTask? {
        do {
            let request = try request.build(token: configuration.token,
                                            organizationIdentifier: configuration.organizationIdentifier,
                                            appName: configuration.appName,
                                            siteURL: configuration.siteURL,
                                            timeoutInterval: configuration.timeoutInterval)
            let task = session.dataTask(with: request) { data, _, error in
                if let error {
                    return completion(.failure(error))
                }
                guard let data else {
                    return completion(.failure(OpenAIError.emptyData))
                }
                let decoder = JSONDecoder()
                do {
                    try completion(.success(decoder.decode(ResultType.self, from: data)))
                } catch {
                    completion(.failure((try? decoder.decode(APIErrorResponse.self, from: data)) ?? error))
                }
            }
            task.resume()

            return task as? URLSessionDataTask
        } catch {
            completion(.failure(error))
        }

        return nil
    }

    func performStreamingRequest<ResultType: Codable>(request: any URLRequestBuildable, onResult: @escaping (Result<ResultType, Error>) -> Void, completion: ((Error?) -> Void)?) -> (any CancelableProtocol)? {
        do {
            let request = try request.build(token: configuration.token,
                                            organizationIdentifier: configuration.organizationIdentifier,
                                            appName: configuration.appName,
                                            siteURL: configuration.siteURL,
                                            timeoutInterval: configuration.timeoutInterval)
            let session = StreamingSession<ResultType>(urlRequest: request)
            session.onReceiveContent = { _, object in
                onResult(.success(object))
            }
            session.onProcessingError = { _, error in
                onResult(.failure(error))
            }
            session.onComplete = { [weak self] object, error in
                self?.streamingSessions.removeAll(where: { $0 == object })
                completion?(error)
            }
            session.perform()
            streamingSessions.append(session)
            return session
        } catch {
            completion?(error)
        }

        return nil
    }

    func performSpeechRequest(request: any URLRequestBuildable, completion: @escaping (Result<AudioSpeechResult, Error>) -> Void) {
        do {
            let request = try request.build(token: configuration.token,
                                            organizationIdentifier: configuration.organizationIdentifier,
                                            appName: configuration.appName,
                                            siteURL: configuration.siteURL,
                                            timeoutInterval: configuration.timeoutInterval)

            let task = session.dataTask(with: request) { data, _, error in
                if let error {
                    return completion(.failure(error))
                }
                guard let data else {
                    return completion(.failure(OpenAIError.emptyData))
                }

                completion(.success(AudioSpeechResult(audio: data)))
            }
            task.resume()
        } catch {
            completion(.failure(error))
        }
    }
}

extension OpenAI {
    /**
       Appends path to paths components with a special handling of the 'v1' part.
       Our library use all paths with a /v1/ prefix. However, some providers give an endpoint
       URL ending with a '/v1' suffix. This can cause duplication of the 'v1' path component.
       This function aims at solving this issue by removing the '/v1' suffix from the host path,
       since that the only parameter that comes from the user.
     */
    private func appendToPathComponent(_ pathComponents: [String], _ path: String) -> String {
        var hostParts = pathComponents
        // `url.pathComponents` produce an array that may start with a slash,
        // but we do not want it, as it causes double slashes in URLs.
        if hostParts.first == "/" {
            hostParts = Array(hostParts.dropFirst())
        }
        if hostParts.last == "v1" {
            hostParts = Array(hostParts.dropLast())
        }

        let pathParts = path.split(separator: "/").map(String.init)

        return "/" + (hostParts + pathParts)
            .filter { !$0.isEmpty }
            .joined(separator: "/")
    }

    func buildURL(path: String) -> URL? {
        var components = URLComponents()

        if let url = URL(string: configuration.host), let scheme = url.scheme {
            components.scheme = scheme
            components.host = url.host
            components.port = url.port
            components.path = appendToPathComponent(url.pathComponents, path)
            print("🚀  ~ \(#file):\(#line) ~ components.path: \(components.path)")
        } else {
            components.scheme = "https"

            // Check if host contains a path component
            let hostParts = configuration.host.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: true)
            if hostParts.count > 1 {
                // Host contains a path component
                components.host = String(hostParts[0])
                let hostPath = "/" + hostParts[1]
                components.path = hostPath + path
            } else {
                // Host does not contain a path component
                components.host = configuration.host
                components.path = path
            }
        }

        guard let url = components.url else {
            print("Error: Unable to construct URL from components.")
            return nil
        }

        return url
    }
}

typealias APIPath = String
extension APIPath {
    static let completions = "/v1/completions"
    static let embeddings = "/v1/embeddings"
    static let chats = "/v1/chat/completions"
    static let edits = "/v1/edits"
    static let models = "/v1/models"
    static let moderations = "/v1/moderations"

    static let audioSpeech = "/v1/audio/speech"
    static let audioTranscriptions = "/v1/audio/transcriptions"
    static let audioTranslations = "/v1/audio/translations"

    static let images = "/v1/images/generations"
    static let imageEdits = "/v1/images/edits"
    static let imageVariations = "/v1/images/variations"

    func withPath(_ path: String) -> String {
        self + "/" + path
    }
}
