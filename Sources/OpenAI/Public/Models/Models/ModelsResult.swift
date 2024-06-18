//
//  ModelsResult.swift
//
//
//  Created by Aled Samuel on 08/04/2023.
//

import Foundation

/// A list of model objects.
public struct ModelsResult: Codable, Equatable {
    /// A list of model objects.
    public let data: [ModelResult]
    /// The object type, which is always `list`
    public let object: String

    enum CodingKeys: CodingKey {
        case data
        case object
    }
}

public extension ModelsResult {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        data = try container.decode([ModelResult].self, forKey: .data)
        object = try container.decodeIfPresent(String.self, forKey: .object) ?? "list"
    }
}
