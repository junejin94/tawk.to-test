//
//  DetailsModel.swift
//  tawk.to
//
//  Created by Phua June Jin on 09/12/2022.
//

import Foundation
import CoreData

class Details: NSManagedObject, Decodable {
    enum CodingKeys: CodingKey {
        case login
        case id
        case node_id
        case avatar_url
        case gravatar_id
        case url
        case html_url
        case followers_url
        case following_url
        case gists_url
        case starred_url
        case subscriptions_url
        case organizations_url
        case repos_url
        case events_url
        case received_events_url
        case type
        case site_admin
        case name
        case company
        case blog
        case location
        case email
        case hireable
        case bio
        case twitter_username
        case public_repos
        case public_gists
        case followers
        case following
        case created_at
        case updated_at
    }

    required convenience init(from decoder: Decoder) throws {
        guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext else {
            throw DecoderConfigurationError.missingManagedObjectContext
        }

        self.init(context: context)

        guard NSEntityDescription.entity(forEntityName: "Users", in: context) != nil else {
            throw DatabaseError.invalidEntity
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.login = try container.decode(String.self, forKey: .login)
        self.id = try container.decode(Int64.self, forKey: .id)
        self.node_id = try container.decode(String.self, forKey: .node_id)
        self.avatar_url = try container.decode(String.self, forKey: .avatar_url)
        self.gravatar_id = try container.decode(String.self, forKey: .gravatar_id)
        self.url = try container.decode(String.self, forKey: .url)
        self.html_url = try container.decode(String.self, forKey: .html_url)
        self.followers_url = try container.decode(String.self, forKey: .followers_url)
        self.following_url = try container.decode(String.self, forKey: .following_url)
        self.gists_url = try container.decode(String.self, forKey: .gists_url)
        self.starred_url = try container.decode(String.self, forKey: .starred_url)
        self.subscriptions_url = try container.decode(String.self, forKey: .subscriptions_url)
        self.organizations_url = try container.decode(String.self, forKey: .organizations_url)
        self.repos_url = try container.decode(String.self, forKey: .repos_url)
        self.events_url = try container.decode(String.self, forKey: .events_url)
        self.received_events_url = try container.decode(String.self, forKey: .received_events_url)
        self.type = try container.decode(String.self, forKey: .type)
        self.site_admin = try container.decode(Bool.self, forKey: .site_admin)
        self.name = try container.decode(String.self, forKey: .name)
        self.company = try container.decodeIfPresent(String.self, forKey: .company) ?? ""
        self.blog = try container.decodeIfPresent(String.self, forKey: .blog) ?? ""
        self.location = try container.decodeIfPresent(String.self, forKey: .location) ?? ""
        self.email = try container.decodeIfPresent(String.self, forKey: .email) ?? ""
        self.hireable = try container.decodeIfPresent(Bool.self, forKey: .hireable) ?? false
        self.bio = try container.decodeIfPresent(String.self, forKey: .bio) ?? ""
        self.twitter_username = try container.decodeIfPresent(String.self, forKey: .twitter_username) ?? ""
        self.public_repos = try container.decodeIfPresent(Int64.self, forKey: .public_repos) ?? 0
        self.public_gists = try container.decodeIfPresent(Int64.self, forKey: .public_gists) ?? 0
        self.followers = try container.decodeIfPresent(Int64.self, forKey: .followers) ?? 0
        self.following = try container.decodeIfPresent(Int64.self, forKey: .following) ?? 0
        self.created_at = try container.decode(String.self, forKey: .created_at)
        self.updated_at = try container.decode(String.self, forKey: .updated_at)

        var image = Data()

        let semaphore = DispatchSemaphore(value: 0)

        Services.shared.fetchData(self.avatar_url!) { result in
            switch result {
            case .success(let data):
                image = data
            case .failure(_):
                image = Data()
            }

            semaphore.signal()
        }

        semaphore.wait()

        self.image = image
        self.notes = ""
    }
}
