//
//  Extensions.swift
//  tawk.to
//
//  Created by Phua June Jin on 31/12/2022.
//

import Foundation
import UIKit
import CoreData
import Combine

extension UIImage {
    /// Invert the color using CIFilter
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

extension UIImageView {
    /// Crop an UIImageView to a circle
    func cropCircle() {
        layer.borderWidth = 3
        layer.masksToBounds = false
        layer.borderColor = UIColor.secondaryLabel.cgColor
        layer.cornerRadius = self.frame.height / 2
        clipsToBounds = true
    }
}

extension URL {
    /// Document directory
    static var documents: URL { return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] }
}

extension Task where Success == Never, Failure == Never {
    /// Sleep for **n** seconds
    static func sleep(seconds: Double) async throws {
        let duration = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
}

extension Task where Failure == Error {
    /// Retry a task with exponential backoff, by using Int.max as maxRetryCount, we can ensure that it will practically keep retrying.
    @discardableResult
    static func exponentialRetry(
        priority: TaskPriority? = nil,
        maxRetryCount: Int = Int.max,
        retryDelay: TimeInterval = 20,
        retryMultiplier: Double = 0.5,
        operation: @Sendable @escaping () async throws -> Success
    ) -> Task {
        Task(priority: priority) {
            for count in 1...maxRetryCount {
                do {
                    return try await operation()
                } catch {
                    let delay = exponentialBackoff(count: count, time: retryDelay, multiplier: retryMultiplier)
                    try await Task<Never, Never>.sleep(nanoseconds: delay)

                    continue
                }
            }

            try Task<Never, Never>.checkCancellation()
            return try await operation()
        }
    }
}

extension NSManagedObject {
    /// Generic mapping for Model to NSManagedObject using KVC
    func map<T>(model: T) {
        let mirror = Mirror(reflecting: model)

        for child in mirror.children  {
            if let key = child.label {
                self.setValue(child.value, forKey: key)
            }
        }
    }
}

/// Skeleton loading for UIKit
protocol SkeletonDisplayable {
    /// Applies a layer of shimmering effect to certain UI elements (UILabel, UIImageView, UIButton) in the view
    func showSkeleton()
    /// Remove the layer of shimmering effect that was added to the UI
    func hideSkeleton()
}

extension SkeletonDisplayable where Self: UIViewController {
    private var skeletonLayerName: String {
        return "skeletonLayerName"
    }

    private var skeletonGradientName: String {
        return "skeletonGradientName"
    }

    private func skeletonViews(in view: UIView) -> [UIView] {
        var results = [UIView]()

        for subview in view.subviews as [UIView] {
            switch subview {
            case _ where subview.isKind(of: UILabel.self):
                results += [subview]
            case _ where subview.isKind(of: UIImageView.self):
                results += [subview]
            case _ where subview.isKind(of: UIButton.self):
                results += [subview]
            default: results += skeletonViews(in: subview)
            }
        }

        return results
    }

    func showSkeleton() {
        let skeletons = skeletonViews(in: view)
        let backgroundColor = CustomColor.Skeleton.background.cgColor
        let highlightColor = CustomColor.Skeleton.highlight.cgColor

        let skeletonLayer = CALayer()
        skeletonLayer.backgroundColor = backgroundColor
        skeletonLayer.name = skeletonLayerName
        skeletonLayer.anchorPoint = .zero
        skeletonLayer.frame.size = UIScreen.main.bounds.size

        skeletons.forEach {
            let gradientLayer = CAGradientLayer()
            gradientLayer.colors = [backgroundColor, highlightColor, backgroundColor]
            gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
            gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
            gradientLayer.frame = UIScreen.main.bounds
            gradientLayer.name = skeletonGradientName

            $0.layer.mask = skeletonLayer
            $0.layer.addSublayer(skeletonLayer)
            $0.layer.addSublayer(gradientLayer)
            $0.clipsToBounds = true
            let width = UIScreen.main.bounds.width

            let animation = CABasicAnimation(keyPath: "transform.translation.x")
            animation.duration = 2
            animation.fromValue = -width
            animation.toValue = width
            animation.repeatCount = .infinity
            animation.autoreverses = false
            animation.fillMode = CAMediaTimingFillMode.forwards

            gradientLayer.add(animation, forKey: "gradientLayerShimmerAnimation")
        }
    }

    func hideSkeleton() {
        skeletonViews(in: view).forEach {
            $0.layer.sublayers?.removeAll {
                $0.name == skeletonLayerName || $0.name == skeletonGradientName
            }
        }
    }
}

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

protocol KeyboardReadable {
    var keyboardPublisher: AnyPublisher<Bool, Never> { get }
}

extension KeyboardReadable {
    /// Publisher for keyboard-related events
    var keyboardPublisher: AnyPublisher<Bool, Never> {
        Publishers.Merge(
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardWillShowNotification)
                .map { _ in true },
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardWillHideNotification)
                .map { _ in false }
        )
        .eraseToAnyPublisher()
    }
}
