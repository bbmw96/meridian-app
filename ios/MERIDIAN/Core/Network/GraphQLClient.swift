import Foundation

struct GraphQLRequest: Encodable {
    let query: String
    let variables: [String: GraphQLValue]

    enum GraphQLValue: Encodable {
        case string(String)
        case int(Int)
        case double(Double)
        case bool(Bool)
        case null

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .string(let v): try container.encode(v)
            case .int(let v): try container.encode(v)
            case .double(let v): try container.encode(v)
            case .bool(let v): try container.encode(v)
            case .null: try container.encodeNil()
            }
        }
    }
}

struct GraphQLResponse<T: Decodable>: Decodable {
    let data: T?
    let errors: [GraphQLError]?
}

struct GraphQLError: Decodable {
    let message: String
    let locations: [GraphQLLocation]?
    let path: [String]?
}

struct GraphQLLocation: Decodable {
    let line: Int
    let column: Int
}

enum GraphQLClientError: LocalizedError {
    case networkError(Error)
    case decodingError(Error)
    case graphQLErrors([GraphQLError])
    case noData

    var errorDescription: String? {
        switch self {
        case .networkError(let e): return "Network error: \(e.localizedDescription)"
        case .decodingError(let e): return "Decoding error: \(e.localizedDescription)"
        case .graphQLErrors(let errs): return errs.map(\.message).joined(separator: ", ")
        case .noData: return "No data returned from GraphQL endpoint."
        }
    }
}

actor GraphQLClient {
    static let shared = GraphQLClient()

    private let endpointURL: URL
    private let session: URLSession

    private init() {
        self.endpointURL = URL(string: "https://bff.meridian.io/graphql")!
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }

    func query<T: Decodable>(query: String, variables: [String: Any] = [:]) async throws -> T {
        let graphQLVars = variables.compactMapValues { value -> GraphQLRequest.GraphQLValue? in
            if let v = value as? String { return .string(v) }
            if let v = value as? Int { return .int(v) }
            if let v = value as? Double { return .double(v) }
            if let v = value as? Bool { return .bool(v) }
            return nil
        }

        let body = GraphQLRequest(query: query, variables: graphQLVars)

        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token = KeychainHelper.shared.retrieve(key: "meridian.api_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            throw GraphQLClientError.decodingError(error)
        }

        let data: Data
        do {
            let (responseData, _) = try await session.data(for: request)
            data = responseData
        } catch {
            throw GraphQLClientError.networkError(error)
        }

        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601
            let response = try decoder.decode(GraphQLResponse<T>.self, from: data)

            if let errors = response.errors, !errors.isEmpty {
                throw GraphQLClientError.graphQLErrors(errors)
            }

            guard let result = response.data else {
                throw GraphQLClientError.noData
            }

            return result
        } catch let err as GraphQLClientError {
            throw err
        } catch {
            throw GraphQLClientError.decodingError(error)
        }
    }
}
