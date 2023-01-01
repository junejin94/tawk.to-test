//
//  Detail.swift
//  tawk.to
//
//  Created by Phua June Jin on 29/12/2022.
//

import Foundation
import UIKit

class Detail: ObservableObject {
    var name: String?
    var login: String?
    var company: String?
    var blog: String?
    var location: String?
    var email: String?
    var bio: String?
    var twitter_username: String?
    var followers: Int?
    var following: Int?
    var public_repos: Int?
    var image: UIImage = UIImage()

    /**
     Maps data from CoreData object to Detail model

     - Parameters:
        - model: CoreData object
        - update: whether to update the user's image as well
     */
    func map(model: Details, update: Bool) async throws {
        self.image = try await getImage(id: model.id, url: model.avatar_url, update: update)
        self.name = model.name ?? ""
        self.login = model.login ?? ""
        self.company = model.company ?? ""
        self.blog = model.blog ?? ""
        self.location = model.location ?? ""
        self.email = model.email ?? ""
        self.bio = model.bio ?? ""
        self.twitter_username = model.twitter_username ?? ""
        self.followers = Int(model.followers)
        self.following = Int(model.following)
        self.public_repos = Int(model.public_repos)
    }
}
