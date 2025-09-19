//
//  ContentView.swift
//  AETNA POC
//
//  Created by Randall Ridley on 9/19/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var chatManager = WatsonChatManager()
    @State private var userMessage: String = ""
    @State private var lastWatsonContext: WatsonContext? = nil
    @State private var navigateToList = false

    let purpleColor = Color(UIColor(red: 125/255, green: 62/255, blue: 151/255, alpha: 1))

    func sendToWatson() {
        chatManager.messageList.append(Message(text: userMessage, sender: "User", id: UUID()))

        guard let APIBaseURL = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String
        else { return }

        guard let url = URL(string: "\(APIBaseURL)") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = WatsonRequest(userMessage: userMessage, data: "message", context: lastWatsonContext)
        request.httpBody = try? JSONEncoder().encode(body)

        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            if let data = data {
                do {
                    let decoded = try JSONDecoder().decode(WatsonResponse.self, from: data)
                    print("Intent: \(decoded.data.intents.first?.intent ?? "None")")
                    print("Confidence: \(decoded.data.intents.first?.confidence ?? 0)")
                    print("Response Text: \(decoded.data.output.text.first ?? "No response")")

                    let responseText = decoded.data.output.text.first ?? "No response"
                    lastWatsonContext = decoded.data.context

                    if let jsonData = responseText.data(using: .utf8) {
                        do {
                            let record = try JSONDecoder().decode(ProviderRecordResponse.self, from: jsonData)

                            if record.status == "successful" {
                                DispatchQueue.main.async {
                                    chatManager.providerResults = record.data.providers

                                    // Add message to chat
                                    let total = record.recordTotal
                                    let messageText = "I have found \(total) provider\(total == 1 ? "" : "s") in your area.\n\nClick to view"
                                    let message = Message(text: messageText, sender: "Bot", id: UUID())
                                    chatManager.messageList.append(message)
                                }
                                return
                            }
                        } catch {
                            // Not a provider record; continue as normal
                        }
                    }

                    // Normal response
                    DispatchQueue.main.async {
                        chatManager.messageList.append(Message(text: responseText, sender: "Bot", id: UUID()))
                    }

                } catch {
                    print("Decoding error:", error)
                }
            } else if let error = error {
                print("Request error:", error)
            }
        }

        userMessage = ""
        task.resume()
    }

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Spacer()
                    Image("aetna-logo")
                        .resizable()
                        .frame(width: 130, height: 30)
                        .scaledToFit()
                    Spacer()
                }
                .padding(5)
                Spacer().frame(height: 15)
            }
            .background(purpleColor)

            VStack {
                Spacer()
                ScrollViewReader { scrollViewProxy in
                    ScrollView {
                        ForEach(chatManager.messageList, id: \.self) { message in

                            HStack {
                                if message.sender == "Bot" {
                                    if message.text.contains("Click to view") {
                                        Button(action: {
                                            navigateToList = true
                                        }) {
                                            Text(message.text)
                                                .padding()
                                                .background(Color.blue.opacity(0.1))
                                                .cornerRadius(10)
                                                .frame(maxWidth: 250, alignment: .leading)
                                                .padding(.trailing, 50)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        Spacer()
                                    } else {
                                        Text(message.text)
                                            .padding()
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(10)
                                            .frame(maxWidth: 250, alignment: .leading)
                                            .padding(.trailing, 50)
                                        Spacer()
                                    }
                                } else {
                                    Spacer()
                                    Text(message.text)
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(10)
                                        .frame(maxWidth: 250, alignment: .trailing)
                                        .padding(.leading, 50)
                                }
                            }
                            .id(message.id)
                        }
                    }
                    .onChange(of: chatManager.messageList) { _ in

                        print("scroll")
                        if let lastMessage = chatManager.messageList.last {
                            withAnimation {
                                scrollViewProxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }

                Spacer()

                Spacer().frame(height: 10)

                HStack {
                    TextField("", text: $userMessage,
                              prompt: Text("Enter a message")
                                  .foregroundColor(.white))
                        .font(.headline)
                        .padding(10)
                        .background(Color.gray)
                        .cornerRadius(10)
                        .foregroundColor(Color.white)

                    Button(action: {
                        sendToWatson()

                    }) {
                        Image("send-messge-icon")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .scaledToFit()
                            .padding(10)
                            .background(purpleColor)
                            .foregroundColor(.white)
                            .cornerRadius(5)
                    }
                    .disabled(userMessage.isEmpty)
                    .opacity(userMessage.isEmpty ? 0.5 : 1.0)
                }

                NavigationLink(
                    destination: ProviderListView(providers: chatManager.providerResults),
                    isActive: $navigateToList
                ) {
                    EmptyView()
                }
            }
            .padding()
        }
    }
}

#Preview {
    NavigationStack {
        ContentView()
    }
}
