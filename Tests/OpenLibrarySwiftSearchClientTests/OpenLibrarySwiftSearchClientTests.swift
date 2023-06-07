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
    
    func testSearchBooksByTitleAndAuthor_OneWord() {
        let expectation = XCTestExpectation(description: "Search for books by title and author, one word")
        let searchString = "Swift"
        let limit = 5
        OpenLibrarySwiftSearchClient.searchBooksByTitleAndAuthor(searchString, limit: limit) { result in
            switch result {
            case .success(let books):
                XCTAssertFalse(books.isEmpty, "Expected non-empty search result")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("API call failed with error: \(error)")
            }
        }
        wait(for: [expectation], timeout: openLibraryIsNotFast)
    }
    
    func testSearchBooksByTitleAndAuthor_MultiWord_Split() {
        let expectation = XCTestExpectation(description: "Search for books by title and author, multiple words split")
        let searchString = "The Catcher in the Rye by J.D. Salinger"
        let limit = 5
        
        OpenLibrarySwiftSearchClient.searchBooksByTitleAndAuthor(searchString, limit: limit) { result in
            
            switch result {
            case .success(let books):
                XCTAssertFalse(books.isEmpty, "Expected non-empty search result")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("API call failed with error: \(error)")
            }
        }
        wait(for: [expectation], timeout: openLibraryIsNotFast)
    }
    
    func testSearchBooksByTitleAndAuthor_MultiWord_Combined() {
        let expectation = XCTestExpectation(description: "Search for books by title and author, multiple words combined")
        let searchString = "The Lord of the Rings J.R.R. Tolkien"
        let limit = 5
        OpenLibrarySwiftSearchClient.searchBooksByTitleAndAuthor(searchString, limit: limit) { result in
            switch result {
            case .success(let books):
                XCTAssertFalse(books.isEmpty, "Expected non-empty search result")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("API call failed with error: \(error)")
            }
        }
        wait(for: [expectation], timeout: openLibraryIsNotFast)
    }
    
    func testSearchBooksByTitleAndAuthor_MultiWord_TitleSplit() {
        let expectation = XCTestExpectation(description: "Search for books by title and author, title split")
        let searchString = "Harry Potter and the Sorcerer's Stone J.K. Rowling"
        let limit = 5
        OpenLibrarySwiftSearchClient.searchBooksByTitleAndAuthor(searchString, limit: limit) { result in
            switch result {
            case .success(let books):
                XCTAssertFalse(books.isEmpty, "Expected non-empty search result")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("API call failed with error: \(error)")
            }
        }
        wait(for: [expectation], timeout: openLibraryIsNotFast)
    }
    
    func testSearchBooksByTitleAndAuthor_MultiWord_TitleCombined() {
        let expectation = XCTestExpectation(description: "Search for books by title and author, title combined")
        let searchString = "To Kill a Mockingbird Harper Lee"
        let limit = 5
        OpenLibrarySwiftSearchClient.searchBooksByTitleAndAuthor(searchString, limit: limit) { result in
            switch result {
            case .success(let books):
                XCTAssertFalse(books.isEmpty, "Expected non-empty search result")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("API call failed with error: \(error)")
            }
        }
        wait(for: [expectation], timeout: openLibraryIsNotFast)
    }
    
    func testGenerateTitleAuthorPairs() {
        // Test Case 1: Single word string
        let input1 = "Swift"
        let result1 = OpenLibrarySwiftSearchClient.generateTitleAuthorPairs(from: input1)
        let expected1 = [
            (title: "Swift", author: ""),
            (title: "", author: "Swift")
        ]
        XCTAssertTrue(arePairsEqual(result1, expected1), "Expected pairs not generated")
        
        // Test Case 2: Two word string
        let input2 = "Swift Programming"
        let result2 = OpenLibrarySwiftSearchClient.generateTitleAuthorPairs(from: input2)
        let expected2 = [
            (title: "Swift Programming", author: ""),
            (title: "Swift", author: "Programming"),
            (title: "", author: "Swift Programming")
        ]
        XCTAssertTrue(arePairsEqual(result2, expected2), "Expected pairs not generated")
        
        // Test Case 3: Multiple words string
        let input3 = "The Swift Programming Language"
        let result3 = OpenLibrarySwiftSearchClient.generateTitleAuthorPairs(from: input3)
        let expected3 = [
            (title: "The Swift Programming Language", author: ""),
            (title: "The Swift Programming", author: "Language"),
            (title: "The Swift", author: "Programming Language")
        ]
        XCTAssertTrue(arePairsEqual(result3, expected3), "Expected pairs not generated")
        
        // Test Case 4: String with common adjectives
        let input4 = "The Amazing Swift Programming Language"
        let result4 = OpenLibrarySwiftSearchClient.generateTitleAuthorPairs(from: input4)
        let expected4 = [
            (title: "The Amazing Swift Programming Language", author: ""),
            (title: "The Amazing Swift Programming", author: "Language"),
            (title: "The Amazing Swift", author: "Programming Language")
        ]
        XCTAssertTrue(arePairsEqual(result4, expected4), "Expected pairs not generated")
        
        // Test Case 5: Empty string
        let input5 = ""
        let result5 = OpenLibrarySwiftSearchClient.generateTitleAuthorPairs(from: input5)
        let expected5: [(title: String, author: String)] = []
        XCTAssertTrue(arePairsEqual(result5, expected5), "Expected pairs not generated")
    }
    
    // Custom equality check for arrays of tuples
    func arePairsEqual(_ pairs1: [(title: String, author: String)], _ pairs2: [(title: String, author: String)]) -> Bool {
        guard pairs1.count == pairs2.count else {
            return false
        }
        for i in 0..<pairs1.count {
            if pairs1[i].title != pairs2[i].title || pairs1[i].author != pairs2[i].author {
                return false
            }
        }
        return true
    }
}
