//
//  UsersViewModel.swift
//  tawk.to
//
//  Created by Phua June Jin on 09/12/2022.
//

import UIKit
import Foundation
import Combine

class UsersViewModel: ObservableObject {
    private var counter = 0
    private var services = Services.shared
    private var invertedCache = [String: Data]()

    var allList: Array<User> = []
    var userList: Array<User> = [] { didSet { didSetList.send() } }
    var didSetList = PassthroughSubject<Void, Never>()

    func loadData() {
        if Database.shared.isUsersEmpty() {
            services.getUsersSince { users in
                self.processList(users: users, details: nil)
            }
        } else {
            Database.shared.getLocalUsers { users in
                Database.shared.getLocalDetails { details in
                    self.processList(users: users, details: details)
                }
            }
        }
    }

    func loadMore() {
        services.getUsersSince { users in
            self.processList(users: users, details: nil)
        }
    }

    func filterList(text: String) {
        userList = text.isEmpty ? allList : allList.filter{ $0.login!.contains(text.lowercased()) }
    }

    private func processList(users: Result<[Users], Error>, details: Result<[Details], Error>?) {
        switch users {
        case .success(let users):
            var tempList = [User]()

            for user in users {
                let tempUser = User()

                counter += 1

                if counter == 4 {
                    counter =  0
                    // Since inverting colors of an image is expensive and will cause the UI to hang if done on the fly,
                    // the inverted image results is cached so it can be referred to when trying to display in a cell
                    invertedCache[user.login!] = UIImage(data: user.image!)?.invertColor()?.pngData()
                }

                tempUser.id = user.id
                tempUser.login = user.login ?? ""
                tempUser.image = user.image ?? Data()

                if let details = details {
                    switch details {
                    case .success(let detail):
                        if let data = detail.first(where: { $0.id == user.id }) {
                            let tempDetail = Detail()

                            tempDetail.name = data.name ?? ""
                            tempDetail.company = data.company ?? ""
                            tempDetail.blog = data.blog ?? ""
                            tempDetail.location = data.location ?? ""
                            tempDetail.email = data.email ?? ""
                            tempDetail.bio = data.bio ?? ""
                            tempDetail.twitter_username = data.twitter_username ?? ""
                            tempDetail.followers = Int(data.followers)
                            tempDetail.following = Int(data.following)
                            tempDetail.notes = data.notes
                            tempDetail.image = data.image

                            tempUser.detail = tempDetail
                        }
                    case .failure(let failure):
                        print(failure)
                    }
                }

                tempList.append(tempUser)
            }

            self.userList.append(contentsOf: tempList)
            self.allList = self.userList
        case .failure(let failure):
            print(failure)
        }
    }

    // Return cells based on certain conditions
    func cellForTableView(tableView: UITableView, atIndexPath indexPath: IndexPath) -> UITableViewCell {
        let data = userList[indexPath.section]

        if (indexPath.section + 1) % 4 == 0 {
            if let login = data.login {
                data.image = invertedCache[login] ?? Data()
            }

            let cell = tableView.dequeue(cellClass: CustomCellInverted.self, indexPath: indexPath)
            cell.configure(data: data)

            return cell
        }

        if let detail = data.detail, let notes = detail.notes, !notes.isEmpty {
            let cell = tableView.dequeue(cellClass: CustomCellNote.self, indexPath: indexPath)
            cell.configure(data: data)

            return cell
        } else {
            let cell = tableView.dequeue(cellClass: CustomCellNormal.self, indexPath: indexPath)
            cell.configure(data: data)

            return cell
        }
    }
}

class User: ObservableObject {
    var id: Int64?
    var login: String?
    var image: Data?
    var detail: Detail? { didSet { didSetDetail.send() } }

    var didSetDetail = PassthroughSubject<Void, Never>()
    var didSetNotes = PassthroughSubject<Void, Never>()

    func fetchDetails() {
        Services.shared.getDetails(login: login!) { result in
            switch result {
            case .success(let data):
                let tempDetail = Detail()

                tempDetail.name = data.name ?? ""
                tempDetail.company = data.company ?? ""
                tempDetail.blog = data.blog ?? ""
                tempDetail.location = data.location ?? ""
                tempDetail.email = data.email ?? ""
                tempDetail.bio = data.bio ?? ""
                tempDetail.twitter_username = data.twitter_username ?? ""
                tempDetail.followers = Int(data.followers)
                tempDetail.following = Int(data.following)
                tempDetail.notes = data.notes
                tempDetail.image = data.image

                self.detail = tempDetail
            case .failure(let failure):
                print(failure)
            }
        }
    }

    func saveNotes(notes: String, completion: @escaping (Bool) -> Void) {
        Database.shared.saveNotes(id: id!, notes: notes) { [weak self] result in
            switch result {
            case .success(_):
                completion(true)
                self?.didSetNotes.send()
            case .failure(let failure):
                print(failure)
                completion(false)
                self?.didSetNotes.send()
            }
        }
    }
}

class Detail: ObservableObject {
    var name: String?
    var company: String?
    var blog: String?
    var location: String?
    var email: String?
    var bio: String?
    var twitter_username: String?
    var followers: Int?
    var following: Int?
    var image: Data?
    var notes: String?
}
