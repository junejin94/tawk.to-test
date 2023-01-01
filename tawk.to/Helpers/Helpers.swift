//
//  Helpers.swift
//  tawk.to
//
//  Created by Phua June Jin on 09/12/2022.
//

import Foundation
import Network
import UIKit

// MARK: - Class
/**
 Singleton for monitoring network status of device.

 To monitor the network status, one just need to listen to the "hasConnection" var, and perform dropFirst() because the default status will be pushed first.

 - Note: NWPathMonitor **DOES NOT** work correctly for Simulators, it gives unreliable results.
 */
@MainActor class MonitorConnection {
    @Published var hasConnection: Bool = true

    private let connectionQueue = DispatchQueue(label: "Connection")
    private let monitor = NWPathMonitor()

    private var previousState: NWPath.Status = .satisfied
    private var stateChanged: Bool = false

    static let shared = MonitorConnection()

    private init() {
        monitor.pathUpdateHandler = { [unowned self] path in
            if path.status != self.previousState {
                self.previousState = path.status
                Task { hasConnection = path.status == .satisfied }
            }
        }

        monitor.start(queue: connectionQueue)
    }
}

// MARK: - Function
/**
 Empty view.

 - Returns: An empty view.
 */
func emptyView() -> UIView {
    let view = UIView()
    view.backgroundColor = .clear

    return view
}

/**
 Fetch image for a single user.

 The flow of operation for fetching the image:
 1. Attempt to load from disk.
 2. Attempt to load from web.
 3. Attempt to load from web with exponential backoff.

 - Parameters:
    - id: A user ID
    - url: The url to fetch the image from
    - update: Flag to download from web instead of try to get local image

 - Returns: An image of the user.
 */
func getImage(id: Int64, url: String?, update: Bool) async throws -> UIImage {
    guard let avatarURL = url else { throw UserError.missingAvatarURL }

    let fileURL = URL.documents.appendingPathComponent(String(id) + ".png")
    let filePath = fileURL.path

    if !update && FileManager.default.fileExists(atPath: filePath) {
        if let image = UIImage(contentsOfFile: filePath) {
            return image
        } else {
            return try await fetchImageWeb(url: avatarURL, fileURL: fileURL)
        }
    }

    return try await fetchImageWeb(url: avatarURL, fileURL: fileURL)
}

/**
 Calculate a time interval exponentially with given parameters.

 By using the formula, t * (1 + m)ⁿ where,
 - t = time
 - m = multiplier
 - n = attempt

 we are able to exponentially increase the number based on the attempt.

 - Precondition: `count` must start from 1
 - Parameters:
    - count: The n attempt
    - time: The initial time for delay in seconds
    - multiplier: The exponential multiplier

 - Returns: Time interval in nanoseconds.
 */
func exponentialBackoff(count: Int, time: TimeInterval, multiplier: Double) -> UInt64 {
    return UInt64(count == 1 ? time * 1_000_000_000 : time * 1_000_000_000 * pow(1 + multiplier, Double(count - 1)))
}

/**
 Attempt to fetch an image from the web, and will retry with exponential backoff if initial fetch failed.

 The function will attempt to fetch the image from the web, and save it to disk.

 - Parameters:
    - url: The url to fetch the image
    - fileURL: The internal URL path to save the downloaded image to

 - Returns: An image of the user.
 */
private func fetchImageWeb(url: String, fileURL: URL) async throws -> UIImage {
    do {
        return try await downloadImage(url: url, fileURL: fileURL)
    } catch {
        return try await Task.exponentialRetry(operation: {
            return try await downloadImage(url: url, fileURL: fileURL)
        }).value
    }
}

/**
 Attempt to download an image from the web and save to disk.

 The function will attempt to fetch the image from the web, and save it to disk.

 - Parameters:
    - url: The url to fetch the image
    - fileURL: The internal URL path to save the downloaded image to

 - Returns: An image of the user.
 */
private func downloadImage(url: String, fileURL: URL) async throws -> UIImage {
    let data = try await NetworkServices.shared.fetchImage(url: url)

    if let image = UIImage(data: data) {
        try await saveToDisk(url: fileURL, data: data)

        return image
    } else {
        throw NetworkError.failedToDownloadFile(url: url)
    }
}

/**
 Save data to disk with the given URL.

 - Parameters:
    - url: The internal URL path to save the downloaded image to
    - data: raw data
 */
private func saveToDisk(url: URL, data: Data) async throws {
    if FileManager.default.fileExists(atPath: url.path) {
        try FileManager.default.removeItem(atPath: url.path)
    }

    try data.write(to: url)
}
