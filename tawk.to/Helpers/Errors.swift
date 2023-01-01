//
//  Errors.swift
//  tawk.to
//
//  Created by Phua June Jin on 31/12/2022.
//

import Foundation

/// Error related to Database
enum DatabaseError: LocalizedError {
    case emptyDatabase
    case invalidEntity
    case unableToRead

    var errorDescription: String? {
        switch self {
        case .emptyDatabase: return "The database is empty, will attempt to fetch from web"
        case .invalidEntity: return "Invalid Entity"
        case .unableToRead: return "Unable to read the database"
        }
    }
}

/// Error related to Endpoint
enum EndpointError: LocalizedError {
    case missingEndpointURL(endpoint: Endpoint)

    var errorDescription: String? {
        switch self {
        case let .missingEndpointURL(endpoint): return "The URL is missing for Endpoint: \(endpoint)"
        }
    }
}

/// Error related to Network
enum NetworkError: LocalizedError {
    case unexpectedError
    case invalidURL(url: String)
    case failedToDownloadFile(url: String)

    var errorDescription: String? {
        switch self {
        case .unexpectedError: return "Unexpected error"
        case let .invalidURL(url): return "Invalid URL: \(url)"
        case let .failedToDownloadFile(url): return "Failed to download image from: \(url)"
        }
    }
}

/// Error related to User model
enum UserError: LocalizedError {
    case missingID
    case missingLogin
    case missingAvatarURL
    case emptyUser
    case emptyDetail(id: Int64)

    var errorDescription: String? {
        switch self {
        case .missingID: return "The user's ID is missing"
        case .missingLogin: return "The user's login is missing"
        case .missingAvatarURL: return "The user's Avatar URL is missing"
        case .emptyUser: return "The user list is empty"
        case let .emptyDetail(id): return "The database doesn't have the details for user with the ID : \(id)"
        }
    }
}
