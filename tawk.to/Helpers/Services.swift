//
//  Services.swift
//  tawk.to
//
//  Created by Phua June Jin on 09/12/2022.
//

import Foundation
import Combine

class Services {
    var cancellable: AnyCancellable?
    private var networkQueue = DispatchQueue(label: "Network")

    static let shared = Services()

    private init() {}

    func getUsersSince(_ completion: @escaping (Result<[Users], Error>) -> Void) {
        Database.shared.getLastID { result in
            var lastID = 0

            switch result {
            case .success(let id):
                lastID = id
            case .failure(_):
                lastID = 0
            }

            self.request(Endpoint.since(String(lastID))) { result in
                switch result {
                case .success(let data):
                    DispatchQueue.main.async {
                        Database.shared.saveUsers(data) { result in
                            switch result {
                            case .success(let users):
                                completion(.success(users))
                            case .failure(let error):
                                completion(.failure(error))
                            }
                        }
                    }
                case .failure(let error):
                    print(String(describing: error))
                }
            }
        }
    }

    func getDetails(login: String, completion: @escaping (Result<Details, Error>) -> Void) {
        self.request(Endpoint.details(login)) { result in
            switch result {
            case .success(let data):
                DispatchQueue.main.async {
                    Database.shared.saveDetails(data) { result in
                        switch result {
                        case .success(let details):
                            completion(.success(details))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                }
            case .failure(let error):
                print(String(describing: error))
            }
        }
    }
    
    func request(_ endpoint: Endpoint, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = endpoint.url else {
            completion(.failure(CustomError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method

        networkQueue.async {
            URLSession.shared.dataTask(with: request) { data, _, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let data = data else {
                    completion(.failure(CustomError.noData))
                    return
                }

                completion(.success(data))
            }.resume()
        }
    }

    func fetchData(_ url: String, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let imageURL = URL(string: url) else {
            return completion(.failure(CustomError.invalidImageURL))
        }

        var request = URLRequest(url: imageURL)
        request.httpMethod = "GET"

        networkQueue.async {
            URLSession.shared.dataTask(with: request) { data, _, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let data = data else {
                    completion(.failure(CustomError.noData))
                    return
                }

                completion(.success(data))
            }.resume()
        }
    }
}

// Convenient struct to construct URL
struct Endpoint {
    let path: String
    let method: String = "GET"
    let queryItems: [URLQueryItem]

    static func since(_ since: String) -> Endpoint {
        return Endpoint(path: Subpath.users.path, queryItems: [URLQueryItem(name: "since", value: since)])
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

enum CustomError: LocalizedError {
    case invalidURL
    case invalidImageURL
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidImageURL: return "Invalid Image URL"
        case .noData: return "No Data"
        }
    }
}
