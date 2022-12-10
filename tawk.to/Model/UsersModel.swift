//
//  UsersModel.swift
//  tawk.to
//
//  Created by Phua June Jin on 09/12/2022.
//

import Foundation
import CoreData

class Users: NSManagedObject, Decodable {
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
    }
}
