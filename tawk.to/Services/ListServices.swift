//
//  ListServices.swift
//  tawk.to
//
//  Created by Phua June Jin on 31/12/2022.
//

import Foundation

/// Singleton for list services
actor ListServices {
    private var retryTask: Task<[User], Error>?

    static let shared = ListServices()

    private init() {}

    /**
     Attempt to load user lists from disk.

     - Returns: A list of User model.
     */
    func loadLocal() async throws -> [User] {
        /// Check whether there's data in the disk
        if await isDatabaseEmpty() { throw DatabaseError.emptyDatabase }

        /// Attempt to fetch cached data from disk
        async let users = try Database.shared.getUsersSince(id: 0)
        async let details = try Database.shared.getDetailsSince(id: 0)

        return try await processUsers(users: users, details: details, update: false)
    }

    /**
     Attempt to load user lists from web, retry with exponential backoff if initial fetch failed.

     - Parameters:
        - id: A user ID
        - per_page: The number of results per page (max 100)

     - Returns: A list of User model.
     */
    func loadWeb(id: Int64, per_page: Int = 0) async throws -> [User] {
        do {
            let users = try await NetworkServices.shared.fetchUsers(id: id, per_page: per_page)

            return try await processUsers(users: users, details: nil, update: true)
        } catch let error {
            print(error.localizedDescription)
            return try await loadRetry(id: id, per_page: per_page, update: true)
        }
    }

    /**
     Check whether to retry fetching user list from web.

     - Returns: Bool status on whether to retry.
     */
    func pendingTask() async -> Bool {
        return retryTask != nil
    }

    /**
     Retries to load user list from web with exponential backoff.

     - Parameters:
        - id: A user ID
        - per_page: The number of results per page (max 100)

     - Returns: A list of User model.
     */
    private func loadRetry(id: Int64, per_page: Int, update: Bool) async throws -> [User] {
        retryTask = Task.exponentialRetry(operation: { [self] in
            let users = try await NetworkServices.shared.fetchUsers(id: id, per_page: per_page)

            return try await processUsers(users: users, details: nil, update: update)
        })

        do {
            if let users = try await retryTask?.value {
                return users
            } else {
                throw NetworkError.unexpectedError
            }
        } catch let error {
            throw error
        }
    }

    /// Cancels the retry task.
    func cancelRetry() {
        retryTask?.cancel()
    }

    /**
     Process the Users (CoreData) to User model.

     - Parameters:
        - users: A list of users
        - details: A list of details about the users
        - update: whether to update the user's image as well

     - Returns: An array of User model.
     */
    private func processUsers(users: [Users], details: [Details]?, update: Bool) async throws -> [User] {
        if users.isEmpty { throw UserError.emptyUser }

        var tempList = [User]()

        for user in users {
            let tempUser = User()
            try await tempUser.map(model: user, update: update)

            if let detail = details, let exist = detail.first(where: { $0.id == tempUser.id }) {
                let tempDetail = Detail()
                try await tempDetail.map(model: exist, update: update)

                tempUser.detail = tempDetail
            }

            tempList.append(tempUser)
        }

        return tempList
    }

    /**
     Check whether the database is empty.

     - Returns: Bool status whether the database is empty.
     */
    private func isDatabaseEmpty() async -> Bool {
        return await Database.shared.isEmpty()
    }
}
