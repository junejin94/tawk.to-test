//
//  UsersViewModel.swift
//  tawk.to
//
//  Created by Phua June Jin on 09/12/2022.
//

import UIKit
import Foundation
import Combine

actor ListViewModel: ObservableObject {
    private var counter = 0
    private var isFiltering = false
    private var isPendingLoadMore = false
    private var currentPage = 0
    private var currentID: Int64 = 0
    private var localLastID: Int64 = 0
    private var pendingUsersCount = 0

    @MainActor var allList: [User] = []
    @MainActor var userList: [User] = [] { didSet { didSetList.send() } }
    @MainActor var didSetList = PassthroughSubject<Void, Never>()

    /**
     Populate the user list.

     The flow of operation for fetching the data:
     1. Attempt to load from disk.
     2. Attempt to load from web.
     3. Retries with exponential backoff.

     - Note: If the connection is online, it will cancel the retry, and immediately attempt to fetch from web.
     */
    func loadData() async {
        await ListServices.shared.cancelRetry()

        do {
            let users = try await ListServices.shared.loadLocal()
            await updateList(users: users)

            pendingUsersCount = await allList.count
            localLastID = await allList.max{ $0.id ?? 0 < $1.id ?? 0 }?.id ?? 0

            await syncUsers()
        } catch let error {
            print(error.localizedDescription)

            do {
                try await loadWeb(id: currentID)
            } catch let error {
                print(error.localizedDescription)
            }
        }
    }

    /// Check whether there's pending user updates, if yes, cancel it first, and attempt to load more, once loaded, we attempt to re-sync, else we'll just load more
    func loadMore() async {
        await attemptLoadMore()
    }

    /**
     Filter the user list based on the text provided.

     - Parameters:
        - text: Text for filtering
     */
    func filterList(text: String) async {
        isFiltering = !text.isEmpty

        let filtered = await text.isEmpty ? allList : allList.filter {
            /// Filter the collection whether "login" contains the filtered text
            if let login = $0.login, login.contains(text.lowercased()) { return true }
            /// Filter the collection whether "notes" contains the filtered text
            if let notes = $0.notes, notes.lowercased().contains(text.lowercased()) { return true }

            return false
        }

        await MainActor.run { [filtered] in userList = filtered }
    }

    /**
     Check whether if there's any pending task to load, and will attempt to load it again. It will check for the following condition,

     1. Attempt to fetch from disk and web if the list is empty.
     2. Attempt to load more if it's pending, and sync users if necessary.
     3. Attempt to sync users if there's pending updates.
     */
    @MainActor func retryIfNecessary() async {
        if allList.isEmpty {
            await loadData()
        } else if await isPendingLoadMore {
            await loadMore()
        } else if await pendingUsersCount > 0 {
            await syncUsers()
        }
    }

    /**
     Attempt to get user from list in indexPath.section

     - Parameters:
        - indexPath: indexPath

     - Returns: User or nil if not found.
     */
    @MainActor func getUser(indexPath: IndexPath) -> User? {
        return userList[safe: indexPath.section]
    }

    /**
     Return custom UITableViewCell based on certain conditions.

     - Parameters:
        - tableView: A UITableView
        - atIndexPath: Index path

     - Returns: Custom UITableViewCell.
     */
    @MainActor func cellForTableView(tableView: UITableView, atIndexPath indexPath: IndexPath) -> UITableViewCell {
        if let model = userList[safe: indexPath.section] {
            /// Uses CustomCellInverted for every fourth entry in list
            if (indexPath.section + 1) % 4 == 0 {
                let cell = tableView.dequeue(cellClass: CustomCellInverted.self, indexPath: indexPath)
                cell.configure(data: model)
                cell.selectionStyle = .none

                return cell
            }

            /// Uses CustomCellNote if there's note regarding the user
            if let notes = model.notes, !notes.isEmpty {
                let cell = tableView.dequeue(cellClass: CustomCellNote.self, indexPath: indexPath)
                cell.configure(data: model)
                cell.selectionStyle = .none

                return cell
            } else {
                /// Uses CustomCellNormal as default
                let cell = tableView.dequeue(cellClass: CustomCellNormal.self, indexPath: indexPath)
                cell.configure(data: model)
                cell.selectionStyle = .none

                return cell
            }
        }

        /// If unable to get the "User" object from the list, it means that the data is not ready, so will display skeleton loading cells
        let cell = tableView.dequeue(cellClass: CustomCellShimmer.self, indexPath: indexPath)
        cell.configure(data: ())
        cell.selectionStyle = .none

        return cell
    }

    /**
     Attempt to load from web.

     - Parameters:
        - id: A user ID
     */
    private func loadWeb(id: Int64) async throws {
        do {
            let users = try await ListServices.shared.loadWeb(id: id)
            await updateList(users: users)

            localLastID = await allList.max{ $0.id ?? 0 < $1.id ?? 0 }?.id ?? 0
        } catch let error {
            print(error.localizedDescription)
            throw error
        }
    }

    /// Attempt to load more, will set isPendingLoad = true while processing, and to false once finished, and sync user if necessary.
    private func attemptLoadMore() async {
        await ListServices.shared.cancelRetry()

        do {
            isPendingLoadMore = true

            try await loadWeb(id: localLastID)

            isPendingLoadMore = false

            await syncUsers()
        } catch let error {
            print(error.localizedDescription)
        }
    }

    /// Attempt to sync latest information about the users from web.
    private func syncUsers() async {
        currentPage = pendingUsersCount >= 100 ? 100 : pendingUsersCount

        if pendingUsersCount > 0 {
            do {
                await ListServices.shared.cancelRetry()

                let users = try await ListServices.shared.loadWeb(id: currentID, per_page: currentPage)
                let maxID = users.max{ $0.id ?? 0 < $1.id ?? 0 }?.id ?? 0

                await updateList(users: users)

                currentID = maxID
                pendingUsersCount = pendingUsersCount > 0 ? pendingUsersCount - users.count : 0

                await syncUsers()
            } catch let error {
                print(error.localizedDescription)
            }
        }
    }

    /**
     Update the list by either updating existing model, or append to the list if it doesn't exists.

     - Parameters:
        - users: A list of users
     */
    @MainActor private func updateList(users: [User]) async {
        if allList.isEmpty {
            allList = await invertImageForFourthUsers(users: users)
        } else {
            for user in users {
                if let row = allList.firstIndex(where: { $0.id == user.id! }) {
                    await allList[row].update(model: user)
                } else {
                    await allList.append(invertImageIfNecessary(user: user))
                }
            }
        }

        /// It is ncessary to check whether the list is being filtered or else it will have the filtered list will suddenly moves
        if await !isFiltering {
            await MainActor.run { [allList] in userList = allList }
        }
    }

    /**
     Invert every fourth user in the user list.

     Since inverting an image is quite expensive, and might cause lag if done on the fly, so we preemptively invert it and cache it for every fourth user in the list.

     - Parameters:
        - users: A list of users
     */
    private func invertImageForFourthUsers(users: [User]) async -> [User] {
        for (idx, user) in users.enumerated() {
            if (idx + 1) % 4 == 0 {
                user.inverted = user.image.invertColor()
            }
        }

        counter = users.count % 4

        return users
    }

    /**
     Invert user's image if necessary.

     Since inverting an image is quite expensive, and might cause lag if done on the fly, so we will invert it and cache it for every fourth user in the list.

     - Parameters:
        - users: A list of users
     */
    private func invertImageIfNecessary(user: User) async -> User {
        counter += 1

        if counter == 4 {
            counter = 0
            user.inverted = user.image.invertColor()
        }

        return user
    }
}
