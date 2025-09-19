# AETNA-POC

A proof-of-concept Conversational AI Chatbot Application built for Aetna, demonstrating integration between a SwiftUI mobile frontend, a Node.js backend powered by IBM Watson Assistant and Discovery services, and dynamic provider search capabilities. This POC supports natural language health insurance inquiries, document retrieval, chatbot response chaining, and data-driven user interactions.

---

## 🧩 Project Structure

### Watson Discovery Integration

The application leverages IBM Watson Discovery to provide accurate, document-based responses to user queries. Key features include:

- **Natural Language Query Processing**: Understands user questions in natural language
- **Relevant Document Retrieval**: Fetches the most relevant policy documents and FAQs
- **Answer Extraction**: Extracts precise answers from documents using AI
- **Context-Aware Responses**: Maintains conversation context for follow-up questions

The Discovery service is integrated through the `/processResponse` endpoint, which routes queries to either Watson Assistant or Watson Discovery based on the request type.

### 1. 📱 iOS Chat App (SwiftUI)

- A mobile front-end built with **SwiftUI**
- Chat interface with user-bot messaging
- Auto-scroll, dynamic response handling
- Supports Watson context chaining
- “Click to view” interaction navigates to a list of providers

### 2. 🌐 Node.js Backend

- Express server handling Watson Assistant and Discovery API calls
- Uses Watson Assistant v2 API for conversational AI
- Integrates with Watson Discovery for document retrieval and question answering
- Custom logic to detect intents and dynamically inject provider data
- Supports response chaining and disambiguation
- Handles natural language queries for insurance policy details and benefits

### 3. 📊 K-Fold Testing Data (Screenshots)

- Located in `screenshots/kfold` folder
- Contains annotated training data and screenshots of fold-based testing for intent quality
- Used during Watson Assistant tuning and validation

---

## 🚀 Getting Started

### Prerequisites

- Xcode 15+ (for SwiftUI app)
- Node.js 18+
- IBM Cloud account with the following services:
  - Watson Assistant instance with API key
  - Watson Discovery instance with API key and project ID

### Environment Variables

Create a `.env` file in the `backend` directory with the following variables:

```
WATSON_AUTH=your_watson_auth_token
WATSON_SKILL_ID=your_watson_skill_id
DISCOVERY_AUTH=your_discovery_auth_token
DISCOVERY_INSTANCE_ID=your_discovery_instance_id
DISCOVERY_PROJECT_ID=your_discovery_project_id
```
