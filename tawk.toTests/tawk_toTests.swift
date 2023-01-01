//
//  tawk_toTests.swift
//  tawk.toTests
//
//  Created by Phua June Jin on 09/12/2022.
//

import XCTest
import CoreData

@testable import tawk_to

final class tawk_toTests: XCTestCase {
    let lastID: Int64 = 0
    /// The path for the mock data to load from
    let path = Bundle.main.path(forResource: "dummy", ofType: "json")

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    /// Simple CRU unit tests, doesn't cover everything.
    func testOperations() async throws {
        /// Attempt to load mock data from the disk
        let data = try loadMock()

        /// Attempt to save user lists to database, the returned list is omitted because we don't need it
        _ = try await Database.sharedTest.saveUsers(data: data)

        /// Attempt to load the previously saved users from the database
        let users = try await Database.sharedTest.getUsersSince(id: lastID)
        /// Assert that there's a total of 30 users
        XCTAssertEqual(users.count, 30)

        /// Attempt to get the first user in the users list
        guard let first = users.first else {
            fatalError("Unable to get first of user list")
        }

        /// Attempt to update the "seen" status of the user
        let success = try await Database.sharedTest.updateSeen(id: first.id)
        /// Assert that it's successfully saved (true)
        XCTAssertTrue(success)

        /// Attempt to get the "seen" status of the user
        let status = try await Database.sharedTest.getSeenFor(id: first.id)
        /// Assert that the value is the same as in the database
        XCTAssertEqual(success, status)
    }

    /// Attempts to load mock data from disk.
    func loadMock() throws -> Data {
        let url = URL(fileURLWithPath: path!)
        let json = try Data(contentsOf: url)

        return json
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
