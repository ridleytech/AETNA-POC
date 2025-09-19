//
//  WatsonChatManager.swift
//  AETNA POC
//
//  Created by Randall Ridley on 9/19/25.
//

import Foundation

import Combine

class WatsonChatManager: ObservableObject {
    @Published var messages: [String] = []
    @Published var messageList: [Message] = [Message(text: "Hello, how may I help you?", sender: "Bot", id: UUID()),
//                                             Message(text: "Am I covered?", sender: "User", id: UUID())
    ]
    @Published var providerResults: [Provider] = []

    private var context: WatsonContext?

    func sendMessage(_ userMessage: String) {
        guard let url = URL(string: "http://localhost:3001/watson/processResponse") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = WatsonRequest(
            userMessage: userMessage,
            data: "message",
            context: context // 🧠 pass previous context
        )

        request.httpBody = try? JSONEncoder().encode(requestBody)

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self = self else { return }
            if let data = data {
                do {
                    let response = try JSONDecoder().decode(WatsonResponse.self, from: data)

                    DispatchQueue.main.async {
                        self.messages.append("🧑 \(userMessage)")
                        if let botReply = response.data.output.text.first {
                            self.messages.append("🤖 \(botReply)")
                        }
                        self.context = response.data.context // 🔄 update context
                    }
                } catch {
                    print("Decode error:", error)
                }
            } else if let error = error {
                print("Network error:", error)
            }
        }.resume()
    }
}
