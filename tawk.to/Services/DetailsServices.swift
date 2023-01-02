//
//  UserServices.swift
//  tawk.to
//
//  Created by Phua June Jin on 31/12/2022.
//

import Foundation

/// Singleton for details services
actor DetailsServices {
    private var retryTask: Task<Detail?, Error>?

    static let shared = DetailsServices()

    private init() {}

    /**
     Updates the "seen" status of a single user.

     - Returns: Bool status on whether the update was successful.
     */
    func updateSeen(id: Int64?) async throws -> Bool {
        guard let id = id else { throw UserError.missingID }

        return try await Database.shared.updateSeen(id: id)
    }

    /**
     Save the notes of a single user.

     - Returns: Bool status on whether the update was successful.
     */
    func saveNotes(id: Int64?, notes: String) async throws -> Bool {
        guard let id = id else { throw UserError.missingID }

        return try await Database.shared.saveNotes(id: id, notes: notes)
    }

    /**
     Attempt to load user's detail from disk.

     - Parameters:
        - id: A user ID

     - Returns: Details about the user.
     */
    func loadLocal(id: Int64?) async throws -> Detail {
        guard let id = id else { throw UserError.missingID }

        let model = try await Database.shared.getDetailsFor(id: id)

        return try await processDetail(model: model, update: false)
    }

    /**
     Attempt to load user's detail from web, will retry with exponential backoff if initial fetch failed.

     - Parameters:
        - login: A user login
        - update: whether to update the user's image as well

     - Returns: Details about the user.
     */
    func loadWeb(login: String?, update: Bool) async throws -> Detail {
        do {
            return try await fetchDetails(login: login, update: update)
        } catch let error {
            print(error.localizedDescription)
            return try await loadRetry(login: login, update: update)
        }
    }

    /**
     Check whether to retry fetching user's details from web.

     - Returns: Bool status on whether to retry.
     */
    func shouldRetry() async -> Bool {
        let retry = retryTask != nil

        if retry { cancelRetry() }

        return retry
    }

    /**
     Retries to load user's detail from web with exponential backoff.

     - Parameters:
        - login: A user login
        - update: whether to update the user's image as well

     - Returns: Details about the user.
     */
    private func loadRetry(login: String?, update: Bool) async throws -> Detail {
        retryTask = Task.exponentialRetry(operation: { [weak self] in
            return try await self?.fetchDetails(login: login, update: update)
        })

        do {
            if let detail = try await retryTask?.value {
                return detail
            } else {
                throw NetworkError.unexpectedError
            }
        } catch let error {
            throw error
        }
    }

    /**
     Attempt to fetch details from web.

     - Parameters:
        - login: A user login
        - update: whether to update the user's image as well

     - Returns: Details about the user.
     */
    private func fetchDetails(login: String?, update: Bool) async throws -> Detail {
        guard let login = login else { throw UserError.missingLogin }

        let model = try await NetworkServices.shared.fetchDetails(login: login)

        return try await processDetail(model: model, update: update)
    }

    /// Cancels the retry task.
    private func cancelRetry() {
        retryTask?.cancel()
    }

    /**
     Process the Details (CoreData) to Detail model, once complete, it will broadcast to subscribers.

     - Parameters:
        - model: A user's details
        - update: whether to update the user's image as well.
     */
    private func processDetail(model: Details, update: Bool) async throws -> Detail {
        let detail = Detail()
        try await detail.map(model: model, update: update)

        return detail
    }
}
