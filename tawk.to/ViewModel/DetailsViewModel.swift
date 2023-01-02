//
//  DetailsViewModel.swift
//  tawk.to
//
//  Created by Phua June Jin on 31/12/2022.
//

import Foundation
import Combine
import UIKit

actor DetailsViewModel: ObservableObject {
    @MainActor private var user: User

    init(user: User) {
        self.user = user
    }

    @MainActor var name: String { return user.detail?.name ?? "" }
    @MainActor var login: String { return user.detail?.login ?? "" }
    @MainActor var bio: String { return user.detail?.bio ?? "" }
    @MainActor var blog: String { return user.detail?.blog ?? "" }
    @MainActor var email: String { return user.detail?.email ?? "" }
    @MainActor var twitter: String { return user.detail?.twitter_username ?? "" }
    @MainActor var location: String { return user.detail?.location ?? "" }
    @MainActor var company: String { return user.detail?.company ?? "" }
    @MainActor var detail: Detail? { return user.detail }
    @MainActor var image: UIImage { return user.detail?.image ?? UIImage() }
    @MainActor var followers: String { return String(user.detail?.followers ?? 0) }
    @MainActor var following: String { return String(user.detail?.following ?? 0) }
    @MainActor var public_repos: String { return String(user.detail?.public_repos ?? 0) }
    @MainActor var navigationBarTitle: String { return user.detail?.name ?? "" }
    @MainActor var notes: String {
        get { return user.notes ?? "" }
        set { user.notes = newValue }
    }

    @MainActor var didSetDetail = PassthroughSubject<Void, Never>()
    @MainActor var didSetNotes = PassthroughSubject<String, Never>()
    @MainActor var didSetSeen = PassthroughSubject<Void, Never>()

    /**
     Populate the user's detail.

     The flow of operation for fetching the data:
     1. Attempt to load from disk.
     2. Attempt to load from web.
     3. Retries with exponential backoff.

     - Note: If the connection is online, it will cancel the retry, and immediately attempt to fetch from web.
     */
    func loadData() async {
        do {
            let model = try await DetailsServices.shared.loadLocal(id: user.id)
            await setDetail(model: model)
            await loadWeb(update: true)
        } catch let error {
            print(error.localizedDescription)
            await loadWeb(update: true)
        }
    }

    /// Check whether to retry fetching user's detail and immediately retry if necessary.
    @MainActor func retryIfNecessary() async {
        if await DetailsServices.shared.shouldRetry() { await loadWeb(update: true) }
    }

    /// Updates the "seen" status of a single user, once complete, it will broadcast to subscribers.
    func updateSeen() async {
        do {
            await user.seen = try await DetailsServices.shared.updateSeen(id: user.id)
            await MainActor.run { didSetSeen.send() }
        } catch let error {
            print(error.localizedDescription)
        }
    }

    /**
     Save or updates the notes of a single user, once complete, it will broadcast to subscribers.

     - Returns: Bool status on whether the save was successful.
     */
    func saveNotes(notes: String) async -> Bool {
        do {
            let success = try await DetailsServices.shared.saveNotes(id: user.id, notes: notes)
            await MainActor.run { didSetNotes.send(notes) }

            return success
        } catch let error {
            print(error.localizedDescription)
            return false
        }
    }

    /**
     Attempt to load user's detail from web, will retry with exponential backoff if initial fetch failed.

     - Parameters:
        - update: whether to update the user's image as well
     */
    private func loadWeb(update: Bool) async {
        do {
            let model = try await DetailsServices.shared.loadWeb(login: user.login, update: update)
            await setDetail(model: model)
        } catch let error {
            print(error.localizedDescription)
        }
    }

    /**
     Set the user's detail, and broadcast to subscribers.

     - Parameters:
        - model: A user's details
     */
    private func setDetail(model: Detail) async {
        await MainActor.run { [model] in
            user.detail = model
            didSetDetail.send()
        }
    }
}
