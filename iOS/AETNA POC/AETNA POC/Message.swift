//
//  Message.swift
//  AETNA POC
//
//  Created by Randall Ridley on 9/19/25.
//

import Foundation

class Message: Codable, Hashable, Identifiable {
    let id: UUID
    var text: String
    var sender: String

    init(text: String, sender: String, id: UUID = UUID()) {
        self.id = id
        self.text = text
        self.sender = sender
    }

    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    var description: String {
        return """
        Message:
        - Sender: \(sender)
        - ID: \(String(describing: id))
        - text: \(String(describing: text))
        """
    }
}
