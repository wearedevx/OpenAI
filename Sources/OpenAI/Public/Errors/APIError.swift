//
//  APIError.swift
//
//
//  Created by Sergii Kryvoblotskyi on 02/04/2023.
//

import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

public enum OpenAIError: DescribedError {
    case emptyData
    case statusError(response: HTTPURLResponse, statusCode: Int)
    case invalidURL
}

public struct AnthropicError: Decodable, Equatable {
    public let type: String
    public let message: String
}

public struct AnthropicResponseType: Decodable, Equatable {
    public enum Kind: String, Decodable {
        case error
    }

    public let type: Kind
    public let error: AnthropicError?
    public let requestId: String?

    enum CodingKeys: String, CodingKey {
        case type
        case error
        case requestId = "request_id"
    }
}

public struct OpenRouterMetadata: Error, Decodable, Equatable {
    public let raw: String
    public let providerName: String

    public enum CodingKeys: String, CodingKey {
        case raw
        case providerName = "provider_name"
    }
}

public struct APIError: Error, Decodable, Equatable {
    public let message: String
    public let type: String?
    public let param: String?
    public let code: String?
    public let metadata: OpenRouterMetadata?

    public init(
        message: String,
        type: String,
        param: String?,
        code: String?,
        metadata: OpenRouterMetadata?
    ) {
        self.message = message
        self.type = type
        self.param = param
        self.code = code
        self.metadata = metadata
    }

    enum CodingKeys: CodingKey {
        case message
        case type
        case param
        case code
        case metadata
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        //
        // message can be String or [String].
        //
        if let string = try? container.decode(String.self, forKey: .message) {
            message = string
        } else if let array = try? container.decode([String].self, forKey: .message) {
            message = array.joined(separator: "\n")
        } else {
            throw DecodingError.typeMismatch(String.self, .init(codingPath: [CodingKeys.message], debugDescription: "message: expected String or [String]"))
        }

        type = try container.decodeIfPresent(String.self, forKey: .type)
        param = try container.decodeIfPresent(String.self, forKey: .param)
        if let code = try? container.decodeIfPresent(Int.self, forKey: .code) {
            self.code = String(code)
        } else if let code = try? container.decodeIfPresent(String.self, forKey: .code) {
            self.code = code
        } else {
            code = nil
        }

        metadata = try? container.decodeIfPresent(OpenRouterMetadata.self, forKey: .metadata)
    }
}

extension APIError: LocalizedError {
    public var errorDescription: String? {
        if let metadata {
            let providerName = metadata.providerName
            if providerName == "Anthropic",
               let data = metadata.raw.data(using: .utf8),
               let response = try? JSONDecoder().decode(AnthropicResponseType.self, from: data),
            let error = response.error {
                return "\(providerName): \(error.type): \(error.message)"
            }
            return "\(providerName): \(message)"
        }

        return message
    }
}

public struct APIErrorResponse: ErrorResponse {
    public let error: APIError
}

extension APIErrorResponse: LocalizedError {
    public var errorDescription: String? {
        error.errorDescription
    }
}

public protocol ErrorResponse: Error, Decodable, Equatable, LocalizedError {
    associatedtype Err: Error, Decodable, Equatable, LocalizedError

    var error: Err { get }
    var errorDescription: String? { get }
}
