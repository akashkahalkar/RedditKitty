import Foundation

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case badStatusCode(Int)
    case invalidJSON
}

final class NetworkManager {
    static let shared = NetworkManager()

    private init() {}

    func getData(_ urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.badStatusCode(httpResponse.statusCode)
        }

        return data
    }

    func getJSON(_ urlString: String) async throws -> [String: Any] {

        let data = try await getData(urlString)
        let json = try JSONSerialization.jsonObject(with: data)

        guard let dictionary = json as? [String: Any] else {
            throw NetworkError.invalidJSON
        }

        return dictionary
    }
}

extension NetworkError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL is invalid."
        case .invalidResponse:
            return "The server response is invalid."
        case .badStatusCode(let statusCode):
            return "The server returned HTTP \(statusCode)."
        case .invalidJSON:
            return "The response JSON is not a dictionary."
        }
    }
}
