//
//  API.swift
//  AETNA POC
//
//  Created by Randall Ridley on 9/19/25.
//

import Foundation

// MARK: - Models

struct WatsonRequest: Codable {
    let userMessage: String
    let data: String
    let context: WatsonContext?
}

struct WatsonResponse: Codable {
    let status: String
    let data: WatsonData
}

struct WatsonData: Codable {
    let intents: [WatsonIntent]
    let entities: [WatsonEntity]
    let input: WatsonInput
    let output: WatsonOutput
    let context: WatsonContext
    let user_id: String
}

struct WatsonEntity: Codable {
    let entity: String
    let location: [Int]
    let value: String
    let confidence: Double
}

struct WatsonIntent: Codable {
    let intent: String
    let confidence: Double
}

struct WatsonInput: Codable {
    let text: String
}

struct WatsonOutput: Codable {
    let generic: [WatsonGeneric]
    let text: [String]
    let nodes_visited: [String]
    let log_messages: [String]
}

struct WatsonGeneric: Codable {
    let response_type: String
    let text: String
}

struct WatsonContext: Codable {
    let conversation_id: String
    let system: [String: AnyCodable]
    let metadata: [String: String]
}

struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intVal = try? container.decode(Int.self) {
            value = intVal
        } else if let doubleVal = try? container.decode(Double.self) {
            value = doubleVal
        } else if let boolVal = try? container.decode(Bool.self) {
            value = boolVal
        } else if let stringVal = try? container.decode(String.self) {
            value = stringVal
        } else if let nestedDict = try? container.decode([String: AnyCodable].self) {
            value = nestedDict
        } else if let arrayVal = try? container.decode([AnyCodable].self) {
            value = arrayVal
        } else {
            value = ()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let intVal as Int:
            try container.encode(intVal)
        case let doubleVal as Double:
            try container.encode(doubleVal)
        case let boolVal as Bool:
            try container.encode(boolVal)
        case let stringVal as String:
            try container.encode(stringVal)
        case let dict as [String: AnyCodable]:
            try container.encode(dict)
        case let array as [AnyCodable]:
            try container.encode(array)
        default:
            try container.encodeNil()
        }
    }
}
