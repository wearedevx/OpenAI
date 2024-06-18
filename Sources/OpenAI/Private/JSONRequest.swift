//
//  JSONRequest.swift
//
//
//  Created by Sergii Kryvoblotskyi on 12/19/22.
//

import Foundation
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

final class JSONRequest<ResultType> {
    let body: Codable?
    let url: URL
    let method: String

    init(body: Codable? = nil, url: URL, method: String = "POST") {
        self.body = body
        self.url = url
        self.method = method
    }
}

extension JSONRequest: URLRequestBuildable {
    func build(token: String, organizationIdentifier: String? = nil, appName: String? = nil, siteURL: String? = nil, timeoutInterval: TimeInterval) throws -> URLRequest {
        var request = URLRequest(url: url, timeoutInterval: timeoutInterval)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if let organizationIdentifier {
            request.setValue(organizationIdentifier, forHTTPHeaderField: "OpenAI-Organization")
        }

        if let appName {
            request.setValue(appName, forHTTPHeaderField: "X-Title")
        }

        if let siteURL {
            request.setValue(siteURL, forHTTPHeaderField: "HTTP-Referer")
        }

        request.httpMethod = method
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        return request
    }
}
