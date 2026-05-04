import Foundation

enum APIError: LocalizedError {
    case networkError(Error)
    case decodingError(Error)
    case serverError(Int)
    case unauthorized
    case invalidEndpoint

    var errorDescription: String? {
        switch self {
        case .networkError(let e): return "Network error: \(e.localizedDescription)"
        case .decodingError(let e): return "Decoding error: \(e.localizedDescription)"
        case .serverError(let code): return "Server error: HTTP \(code)"
        case .unauthorized: return "Unauthorised. Please check your API credentials."
        case .invalidEndpoint: return "Invalid endpoint configuration."
        }
    }
}

struct CreativeRequest: Encodable {
    var url: String
    var platform: String
    var format: String
    var language: String
    var currency: String
    var framework: String
}

enum Endpoint {
    case scanDomain(String)
    case getCompetitors(String, Int)
    case getRates([String])
    case generateCreative(CreativeRequest)
    case getOpportunities
    case executeMQL(String)

    var path: String {
        switch self {
        case .scanDomain: return "/v1/intelligence/scan"
        case .getCompetitors: return "/v1/intelligence/competitors"
        case .getRates: return "/v1/currency/rates"
        case .generateCreative: return "/v1/creative/generate"
        case .getOpportunities: return "/v1/radar/opportunities"
        case .executeMQL: return "/v1/mql/execute"
        }
    }

    var method: String {
        switch self {
        case .scanDomain, .generateCreative, .executeMQL: return "POST"
        case .getCompetitors, .getRates, .getOpportunities: return "GET"
        }
    }

    func queryItems() -> [URLQueryItem] {
        switch self {
        case .getCompetitors(let domain, let limit):
            return [
                URLQueryItem(name: "domain", value: domain),
                URLQueryItem(name: "limit", value: "\(limit)")
            ]
        case .getRates(let pairs):
            return [URLQueryItem(name: "pairs", value: pairs.joined(separator: ","))]
        default:
            return []
        }
    }

    func body() throws -> Data? {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        switch self {
        case .scanDomain(let domain):
            return try encoder.encode(["domain": domain])
        case .generateCreative(let request):
            return try encoder.encode(request)
        case .executeMQL(let query):
            return try encoder.encode(["query": query])
        default:
            return nil
        }
    }
}

actor APIClient {
    static let shared = APIClient()

    private let baseURL: URL
    private let session: URLSession

    private init() {
        self.baseURL = URL(string: "https://api.meridian.io")!
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.httpAdditionalHeaders = [
            "Accept": "application/json",
            "X-MERIDIAN-Version": "1.0"
        ]
        self.session = URLSession(configuration: config)
    }

    func fetch<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        var components = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: false)!
        let queryItems = endpoint.queryItems()
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else { throw APIError.invalidEndpoint }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method

        if let body = try endpoint.body() {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        if let token = retrieveToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        if let httpResponse = response as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 401: throw APIError.unauthorized
            case 400...599: throw APIError.serverError(httpResponse.statusCode)
            default: break
            }
        }

        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    private func retrieveToken() -> String? {
        KeychainHelper.shared.retrieve(key: "meridian.api_token")
    }
}

final class KeychainHelper {
    static let shared = KeychainHelper()
    private init() {}

    func retrieve(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func store(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
}
