//
//  DetailsModel.swift
//  tawk.to
//
//  Created by Phua June Jin on 09/12/2022.
//

import Foundation
import CoreData

/// To decode JSON using Codable protocol and act as a temporary data storage
struct DetailsCodable: Codable {
    var login: String
    var id: Int64
    var node_id: String
    var avatar_url: String
    var gravatar_id: String
    var url: String
    var html_url: String
    var followers_url: String
    var following_url: String
    var gists_url: String
    var starred_url: String
    var subscriptions_url: String
    var organizations_url: String
    var repos_url: String
    var events_url: String
    var received_events_url: String
    var type: String
    var site_admin: Bool
    var name: String?
    var company: String?
    var blog: String?
    var location: String?
    var email: String?
    var hireable: Bool?
    var bio: String?
    var twitter_username: String?
    var public_repos: Int64?
    var public_gists: Int64?
    var followers: Int64?
    var following: Int64?
    var created_at: String
    var updated_at: String

    init(from decoder: Decoder) throws {
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
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
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
    }
}
