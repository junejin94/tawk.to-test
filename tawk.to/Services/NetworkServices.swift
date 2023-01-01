//
//  Services.swift
//  tawk.to
//
//  Created by Phua June Jin on 09/12/2022.
//

import Foundation
import Combine

/// Singleton for network services.
actor NetworkServices {
    static let shared = NetworkServices()

    /// Custom session, limits connection to 1, with 15 seconds timeout
    static let sessionManager: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = 1
        config.timeoutIntervalForRequest = TimeInterval(15)
        config.timeoutIntervalForResource = TimeInterval(15)

        return URLSession(configuration: config)
    }()

    private init() {}

    /**
     Fetch user list from the web.

     The function will attempt to fetch the user list from the web, and save it to disk.

     - Parameters:
        - id: A user ID
        - per_page: The number of results per page, if it's 0 or less, it will not send it in the request

     - Returns: A list of users.
     */
    func fetchUsers(id: Int64, per_page: Int) async throws -> [Users] {
        if per_page == 0 {
            let data = try await request(endpoint: Endpoint.since(since: String(id)))
            return try await Database.shared.saveUsers(data: data)
        } else {
            let data = try await request(endpoint: Endpoint.since(since: String(id), per_page: String(per_page)))
            return try await Database.shared.saveUsers(data: data)
        }
    }

    /**
     Fetch details of a single user from the web.

     The function will attempt to fetch details of a single user from the web, and save it to disk.

     - Parameters:
        - login: A user login

     - Returns: Details of a single user.
     */
    func fetchDetails(login: String?) async throws -> Details {
        guard let login = login else { throw UserError.missingLogin }

        let data = try await request(endpoint: Endpoint.details(login))

        return try await Database.shared.saveDetails(data: data)
    }

    /**
     Fetch an image from the provided url.

     The function will attempt to fetch image of a single user from the web, and save it to disk.

     - Parameters:
        - url: The url to download the image

     - Returns: raw data of the image.
     */
    func fetchImage(url: String) async throws -> Data {
        return try await request(url: url)
    }

    /**
     Fetch data from the Endpoint struct.
.
     - Parameters:
        - endpoint: Endpoint struct that contains the URL requests

     - Returns: raw data downloaded from the URL.
     */
    private func request(endpoint: Endpoint) async throws -> Data {
        guard let url = endpoint.url else { throw EndpointError.missingEndpointURL(endpoint: endpoint) }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method

        let (data, _) = try await NetworkServices.sessionManager.data(for: request)

        return data
    }

    /**
     Fetch data from the provided url.

     - Parameters:
        - url: The URL string

     - Returns: raw data downloaded from the URL.
     */
    private func request(url: String) async throws -> Data {
        guard let imageURL = URL(string: url) else { throw NetworkError.invalidURL(url: url) }

        let request = URLRequest(url: imageURL)
        let (data, _) = try await NetworkServices.sessionManager.data(for: request)

        return data
    }
}

/**
 Manage endpoints and generate URL object.

 The current list of endpoint supported,
 - since
 - since (per_page)
 - details
 */
struct Endpoint {
    let path: String
    let method: String = "GET"
    let queryItems: [URLQueryItem]

    static func since(since: String) -> Endpoint {
        return Endpoint(path: Subpath.users.path, queryItems: [URLQueryItem(name: "since", value: since)])
    }

    static func since(since: String, per_page: String) -> Endpoint {
        return Endpoint(path: Subpath.users.path, queryItems: [URLQueryItem(name: "since", value: since), URLQueryItem(name: "per_page", value: per_page)])
    }

    static func details(_ details: String) -> Endpoint {
        return Endpoint(path: Subpath.users.path + "/\(details)", queryItems: [])
    }

    var url: URL? {
        let scheme = "https"
        let host = "api.github.com"

        var components = URLComponents()

        components.scheme = scheme
        components.host = host
        components.path = path
        components.queryItems = queryItems

        return components.url
    }
}

private enum Subpath {
    case users

    var path: String {
        switch self {
        case .users: return "/users"
        }
    }
}
