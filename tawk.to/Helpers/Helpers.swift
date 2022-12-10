//
//  Helpers.swift
//  tawk.to
//
//  Created by Phua June Jin on 09/12/2022.
//

import Foundation
import UIKit
import Network


// NWPathMonitor doesn't work correctly for Simulators, the alternative is to ping a server constantly
class MonitorConnection {
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
                hasConnection = path.status == .satisfied
            }
        }

        monitor.start(queue: connectionQueue)
    }
}


func emptyView() -> UIView {
    let view = UIView()
    view.backgroundColor = .clear

    return view
}

// Invert color of a UIImage
extension UIImage {
    func invertColor() -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }
        guard let filter = CIFilter(name: "CIColorInvert") else { return nil }

        filter.setDefaults()
        filter.setValue(CoreImage.CIImage(cgImage: cgImage), forKey: kCIInputImageKey)

        let context = CIContext(options: nil)

        guard let outputImage = filter.outputImage else { return nil }
        guard let outputImageCopy = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }

        return UIImage(cgImage: outputImageCopy)
    }
}

// To crop an image to a circle
extension UIImageView {
    func cropCircle() {
        layer.borderWidth = 3
        layer.masksToBounds = false
        layer.borderColor = UIColor.secondaryLabel.cgColor
        layer.cornerRadius = self.frame.height / 2
        clipsToBounds = true
    }
}

enum DatabaseError: LocalizedError {
    case invalidEntity
    case unableToWrite
    case unableToRead
    case emptyID

    var errorDescription: String? {
        switch self {
        case .invalidEntity: return "Invalid Entity"
        case .unableToWrite: return "Unable to write to database"
        case .unableToRead: return "Unable to read the database"
        case .emptyID: return "Empty ID"
        }
    }
}

enum DecoderConfigurationError: Error {
    case missingManagedObjectContext
}

extension CodingUserInfoKey {
    static let managedObjectContext = CodingUserInfoKey(rawValue: "managedObjectContext")!
}
