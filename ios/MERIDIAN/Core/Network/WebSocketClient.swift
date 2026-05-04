import Foundation

struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let v = try? container.decode(String.self) { self.value = v }
        else if let v = try? container.decode(Double.self) { self.value = v }
        else if let v = try? container.decode(Bool.self) { self.value = v }
        else if let v = try? container.decode(Int.self) { self.value = v }
        else if let v = try? container.decode([String: AnyCodable].self) {
            self.value = v.mapValues(\.value)
        }
        else if let v = try? container.decode([AnyCodable].self) {
            self.value = v.map(\.value)
        }
        else {
            self.value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let v as String: try container.encode(v)
        case let v as Double: try container.encode(v)
        case let v as Bool: try container.encode(v)
        case let v as Int: try container.encode(v)
        default: try container.encodeNil()
        }
    }
}

struct WebSocketMessage: Decodable {
    let event: String
    let payload: [String: AnyCodable]
    let topic: String?
    let ref: String?
}

enum WebSocketClientError: LocalizedError {
    case connectionFailed
    case notConnected
    case encodingError

    var errorDescription: String? {
        switch self {
        case .connectionFailed: return "WebSocket connection failed."
        case .notConnected: return "WebSocket is not connected."
        case .encodingError: return "Failed to encode WebSocket message."
        }
    }
}

actor WebSocketClient {
    static let shared = WebSocketClient()

    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession
    private var subscriptions: [String: AsyncStream<WebSocketMessage>.Continuation] = [:]
    private var isConnected = false

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }

    func connect(to url: URL) {
        disconnect()
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        isConnected = true
        startReceiving()
    }

    func subscribe(topic: String) -> AsyncStream<WebSocketMessage> {
        let stream = AsyncStream<WebSocketMessage> { continuation in
            subscriptions[topic] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { await self?.unsubscribe(topic: topic) }
            }
        }

        Task {
            let joinPayload: [String: String] = [:]
            await sendPhoenixJoin(topic: topic, payload: joinPayload)
        }

        return stream
    }

    func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        isConnected = false
        subscriptions.values.forEach { $0.finish() }
        subscriptions.removeAll()
    }

    private func unsubscribe(topic: String) {
        subscriptions.removeValue(forKey: topic)
    }

    private func startReceiving() {
        Task {
            while isConnected, let task = webSocketTask {
                do {
                    let message = try await task.receive()
                    switch message {
                    case .string(let text):
                        await handleMessage(text)
                    case .data(let data):
                        if let text = String(data: data, encoding: .utf8) {
                            await handleMessage(text)
                        }
                    @unknown default:
                        break
                    }
                } catch {
                    isConnected = false
                    break
                }
            }
        }
    }

    private func handleMessage(_ text: String) async {
        guard let data = text.data(using: .utf8) else { return }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let msg = try? decoder.decode(WebSocketMessage.self, from: data) else { return }
        let topic = msg.topic ?? ""
        subscriptions[topic]?.yield(msg)
        subscriptions["*"]?.yield(msg)
    }

    private func sendPhoenixJoin(topic: String, payload: [String: String]) async {
        guard let task = webSocketTask else { return }
        let joinMsg: [String: Any] = [
            "topic": topic,
            "event": "phx_join",
            "payload": payload,
            "ref": UUID().uuidString
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: joinMsg),
              let text = String(data: data, encoding: .utf8) else { return }
        try? await task.send(.string(text))
    }
}
