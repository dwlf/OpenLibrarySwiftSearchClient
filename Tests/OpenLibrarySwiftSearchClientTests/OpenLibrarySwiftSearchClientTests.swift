import XCTest
@testable import OpenLibrarySwiftSearchClient

let openLibraryIsNotFast: TimeInterval = 30.0

final class OpenLibrarySwiftSearchClientTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(OpenLibrarySwiftSearchClient().text, "Hello, World!")
    }
    
    func testFindClosestBook() throws {
        let expectation = XCTestExpectation(description: "Search for a book and return the closest match")

        OpenLibrarySwiftSearchClient.findClosestBook(title: "The Da Vinci Code", author: "Dan Brown") { result in
            switch result {
            case .success(let book):
                XCTAssertEqual(book.title, "The Da Vinci Code")
                XCTAssertEqual(book.author_name?.first, "Dan Brown")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Expected success, but got \(error) instead")
            }
        }

        wait(for: [expectation], timeout: openLibraryIsNotFast)
    }
    
    func testFindClosestBookByTitle() throws {
        let expectation = XCTestExpectation(description: "Book found")
        OpenLibrarySwiftSearchClient.findClosestBook(title: "The Da Vinci Code", author: nil) { result in
            switch result {
            case .success(let book):
                XCTAssertNotNil(book, "No book found")
                XCTAssertEqual(book.title, "The Da Vinci Code")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("API call failed with error: \(error)")
            }
        }
        wait(for: [expectation], timeout: openLibraryIsNotFast)
    }

    func testFindClosestBookByAuthor() throws {
        let expectation = XCTestExpectation(description: "Book found")
        OpenLibrarySwiftSearchClient.findClosestBook(title: nil, author: "Dan Brown") { result in
            switch result {
            case .success(let book):
                XCTAssertNotNil(book, "No book found")
                XCTAssertNotNil(book.author_name, "Author not found")
                XCTAssert(book.author_name!.contains("Dan Brown"), "Author name does not contain 'Dan Brown'")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("API call failed with error: \(error)")
            }
        }
        wait(for: [expectation], timeout: openLibraryIsNotFast)
    }
    
    func testFindBooksByTitleAndAuthor() throws {
        let expectation = XCTestExpectation(description: "Search for books by title and author")
        
        OpenLibrarySwiftSearchClient.findBooks(title: "Adventures of Tom Swift", author: "Victor Appleton", limit: 3) { result in
            switch result {
            case .success(let books):
                XCTAssertEqual(books.count, 3, "Expected 3 books")
                
                XCTAssertTrue(books.contains { $0.title.contains("Adventures of Tom Swift") == true && $0.author_name?.contains("Victor Appleton") == true },
                              "Expected 'Adventures of Tom Swift' by 'Victor Appleton'")
                
                expectation.fulfill()
            case .failure(let error):
                XCTFail("API call failed with error: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: openLibraryIsNotFast)
    }

    
    func testFindBooksByTitle() throws {
        let expectation = XCTestExpectation(description: "Search for books by title")
        
        OpenLibrarySwiftSearchClient.findBooks(title: "Swift Programming", author: nil, limit: 5) { result in
            switch result {
            case .success(let books):
                XCTAssertFalse(books.isEmpty, "No books found")
                
                XCTAssertTrue(books.contains { $0.title.localizedCaseInsensitiveCompare("Swift Programming") == .orderedSame },
                              "Expected 'Swift Programming'")
                
                expectation.fulfill()
            case .failure(let error):
                XCTFail("API call failed with error: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: openLibraryIsNotFast)
    }
}
