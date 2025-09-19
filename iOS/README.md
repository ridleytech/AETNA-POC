# AETNA POC

A Swift UI proof-of-concept iOS app that integrates with IBM Watson to provide a chat interface for users. The app can process user messages, interact with a Watson backend, and display provider search results in a conversational UI.

## Features

- Chat interface using SwiftUI
- Sends user messages to a Watson backend via REST API
- Displays Watson responses in a chat format
- Detects and displays provider search results with navigation to a provider list
- Custom UI with Aetna branding

## Requirements

- Xcode 14 or later
- iOS 16.0+
- Swift 5.7+
- Internet connection (uses ngrok for backend endpoint)

## Setup

1. Clone the repository.
2. Open `AETNA POC.xcodeproj` in Xcode.
3. Update the Watson backend URL in `ContentView.swift` if needed.
4. Build and run on a simulator or device.

## Project Structure

- `ContentView.swift`: Main chat UI and logic
- `WatsonChatManager.swift`: Manages chat state and provider results
- `ProviderListView.swift`: Displays a list of providers (if found)
- `Models/`: Contains data models for messages, Watson requests/responses, and provider records

## License

For internal proof-of-concept use only.
