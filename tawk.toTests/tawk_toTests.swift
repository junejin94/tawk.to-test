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
    let path = Bundle.main.path(forResource: "dummy", ofType: "json")
    let context = CoreDataStore.shared.persistentContainer.viewContext

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testOperations() throws {
        let testString = "Test"
        let testRowName = "login"

        let decoder = JSONDecoder()
        decoder.userInfo[CodingUserInfoKey.managedObjectContext] = context

        var users = [Users]()

        // Attempt to decode an actual JSON response and map it to the Model
        do {
            let url = URL(fileURLWithPath: path!)
            let json = try Data(contentsOf: url)
            _ = try decoder.decode([Users].self, from: json)
        } catch {
            fatalError("Unable to decode JSON to User Model")
        }

        // Attempt to save the data into a database
        do {
            try context.save()
        } catch {
            fatalError("Unable to save to database")
        }

        // Attempt to fetch the data from database
        do {
            let sort = NSSortDescriptor(key: "id", ascending: true)
            let request = NSFetchRequest<Users>(entityName: "Users")
            request.sortDescriptors = [sort]

            users = try context.fetch(request)
        } catch {
            fatalError("Unable to fetch the data")
        }

        // Ensure that the users count is correct
        XCTAssertEqual(users.count, 30)

        // Attempt to unwrap optional, if fail means that either fail to unwrap optional or missing data
        guard let firstUser = users.first else {
            fatalError("Unable to get the user")
        }

        // Attempt to update a model and save it to the database
        do {
            firstUser.setValue(testString, forKey: testRowName)

            try context.save()
        } catch {
            fatalError("Unable to update the data")
        }

        // Ensure that the data is update accordingly with the test string
        do {
            let request = NSFetchRequest<Users>(entityName: "Users")
            request.predicate = NSPredicate(format: "id == %d", firstUser.id)
            request.fetchLimit = 1

            let result = try context.fetch(request)

            if let detail = result.first {
                XCTAssertEqual(detail.login, testString)
            }
        } catch {
            fatalError("Unable to fetch the data")
        }
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
