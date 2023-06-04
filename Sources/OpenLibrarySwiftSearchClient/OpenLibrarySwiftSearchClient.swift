import Foundation
import os.log

enum OpenLibraryAPIError: Error {
    case invalidURL
    case requestFailed
    case invalidResponse
    case serializationFailed
}

public struct OpenLibrarySwiftSearchClient {
    
    public private(set) var text = "Hello, World!"

    private static let baseURL = "https://openlibrary.org"
    private static let log = OSLog(subsystem: "com.example.OpenLibraryAPI", category: "API")

    public init() {
    }
    
    static func findClosestBook(title: String?, author: String?, completion: @escaping (Result<OpenLibraryBook, OpenLibraryAPIError>) -> Void) {
        if title == nil && author == nil {
            completion(.failure(.invalidURL))
            return
        }

        var urlComponents = URLComponents(string: "\(baseURL)/search.json")
        var queryItems = [URLQueryItem(name: "limit", value: "1")] // limit the results to 1
        
        if let title = title {
            queryItems.append(URLQueryItem(name: "title", value: title))
        }
        
        if let author = author {
            queryItems.append(URLQueryItem(name: "author", value: author))
        }
        
        urlComponents?.queryItems = queryItems

        guard let url = urlComponents?.url else {
            completion(.failure(.invalidURL))
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                let logMessage = "Request failed: \(error.localizedDescription)"
                os_log("%@, function: %@, line: %d", log: Self.log, type: .error, logMessage, #function, #line)
                completion(.failure(.requestFailed))
                return
            }
            
            guard let data = data else {
                os_log("Invalid response data, function: %@, line: %d", log: Self.log, type: .error, #function, #line)
                completion(.failure(.invalidResponse))
                return
            }
            
            // Print raw JSON response
            print(String(data: data, encoding: .utf8) ?? "Invalid data")

            
            do {
                let decoder = JSONDecoder()
                let searchResponse = try decoder.decode(OpenLibrarySearchResponse.self, from: data)
                if let firstBook = searchResponse.docs.first {
                    completion(.success(firstBook))
                } else {
                    completion(.failure(.serializationFailed))
                }
            } catch {
                let logMessage = "Serialization failed: \(error.localizedDescription)"
                os_log("%@, function: %@, line: %d", log: Self.log, type: .error, logMessage, #function, #line)
                completion(.failure(.serializationFailed))
            }
        }.resume()
    }


}

struct OpenLibraryBook: Codable {
    let key: String
    let title: String
    let isbn: [String]?
    let author_name: [String]?
    let url: String?
    
    enum CodingKeys: String, CodingKey {
        case key
        case title
        case isbn
        case author_name
        case url
    }
}


struct OpenLibrarySearchResponse: Codable {
    let docs: [OpenLibraryBook]
}
