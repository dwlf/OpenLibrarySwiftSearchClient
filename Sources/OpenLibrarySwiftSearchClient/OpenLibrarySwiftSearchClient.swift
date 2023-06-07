import Foundation
import os.log

public enum OpenLibraryAPIError: Error {
    case invalidURL
    case requestFailed
    case invalidResponse
    case serializationFailed
    case noResultsFound
}

public struct OpenLibrarySwiftSearchClient {
    public private(set) var text = "Hello, World!"
    
    private static let baseURL = "https://openlibrary.org"
    private static let log = OSLog(subsystem: "com.example.OpenLibraryAPI", category: "API")
    
    public init() {}
    
    public static func findClosestBook(title: String?, author: String?, completion: @escaping (Result<OpenLibraryBook, OpenLibraryAPIError>) -> Void) {
        guard let url = constructSearchURL(withTitle: title, author: author, limit: 1) else {
            completion(.failure(.invalidURL))
            return
        }
        
        os_log("URL for the request: %@", log: Self.log, type: .debug, url.absoluteString)
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
    
    public static func findBooks(title: String?, author: String?, limit: Int, completion: @escaping (Result<[OpenLibraryBook], OpenLibraryAPIError>) -> Void) {
        guard let url = constructSearchURL(withTitle: title, author: author, limit: limit) else {
            completion(.failure(.invalidURL))
            return
        }
        
        os_log("URL for the request: %@", log: Self.log, type: .debug, url.absoluteString)
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
            
            do {
                let decoder = JSONDecoder()
                let searchResponse = try decoder.decode(OpenLibrarySearchResponse.self, from: data)
                let books = searchResponse.docs
                completion(.success(books))
            } catch {
                let logMessage = "Serialization failed: \(error.localizedDescription)"
                os_log("%@, function: %@, line: %d", log: Self.log, type: .error, logMessage, #function, #line)
                completion(.failure(.serializationFailed))
            }
        }.resume()
    }
    
    private static func constructSearchURL(withTitle title: String?, author: String?, limit: Int) -> URL? {
        var urlComponents = URLComponents(string: "\(baseURL)/search.json")
        var queryItems = [URLQueryItem]()
        
        if let title = title {
            queryItems.append(URLQueryItem(name: "title", value: title))
        }
        
        if let author = author {
            queryItems.append(URLQueryItem(name: "author", value: author))
        }
        
        queryItems.append(URLQueryItem(name: "limit", value: "\(limit)"))
        urlComponents?.queryItems = queryItems
        
        return urlComponents?.url
    }
    
    public static func searchBooksByTitleAndAuthor(_ searchString: String, limit: Int, completion: @escaping (Result<[OpenLibraryBook], OpenLibraryAPIError>) -> Void) {
        
        let pairs = generateTitleAuthorPairs(from: searchString)

        let dispatchGroup = DispatchGroup()
        var allBooks: [OpenLibraryBook] = []
        var lastError: OpenLibraryAPIError?

        for pair in pairs {
            let title = pair.title.isEmpty ? nil : pair.title
            let author = pair.author.isEmpty ? nil : pair.author

            dispatchGroup.enter()
            OpenLibrarySwiftSearchClient.findBooks(title: title, author: author, limit: limit) { result in
                // Handle the search result
                switch result {
                case .success(let books):
                    // Add the books from this query to the cumulative list
                    allBooks += books
                case .failure(let error):
                    // Keep track of the last error that occurred
                    lastError = error
                }
                
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            if !allBooks.isEmpty {
                // If we found any books, return those
                completion(.success(allBooks))
            } else if let error = lastError {
                // If no books were found and there was an error, return the error
                completion(.failure(error))
            } else {
                // If no books were found and there were no errors, return an appropriate error
                completion(.failure(.noResultsFound))
            }
        }
    }
    
    
    
    public static func generateTitleAuthorPairs(from searchString: String) -> [(title: String, author: String)] {
        var pairs: [(title: String, author: String)] = []

        if !searchString.isEmpty {
            pairs.append((title: searchString, author: ""))
            let words = searchString.split(separator: " ")
            if let lastWord = words.last {
                let titleWithoutLastWord = words.dropLast().joined(separator: " ")
                pairs.append((title: titleWithoutLastWord, author: String(lastWord)))
            }

            if words.count > 1 {
                let lastTwoWords = words.suffix(2).joined(separator: " ")
                let titleWithoutLastTwoWords = words.dropLast(2).joined(separator: " ")
                pairs.append((title: titleWithoutLastTwoWords, author: lastTwoWords))
            }
        }

        return pairs
    }
    
}


private let MAX_API_CALLS_PER_SEARCH = 7


public struct OpenLibraryBook: Codable {
    public let key: String
    public let title: String
    public let first_publish_year: Int16
    public let isbn: [String]?
    public let author_name: [String]?
    public let url: String?
    
    enum CodingKeys: String, CodingKey {
        case key
        case title
        case first_publish_year
        case isbn
        case author_name
        case url
    }
}

public struct OpenLibrarySearchResponse: Codable {
    public let docs: [OpenLibraryBook]
}
