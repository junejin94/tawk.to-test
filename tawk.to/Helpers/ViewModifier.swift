//
//  ViewModifier.swift
//  tawk.to
//
//  Created by Phua June Jin on 10/12/2022.
//

import SwiftUI

// MARK: - Toast
struct Toast: ViewModifier {
    static let short: TimeInterval = 2
    static let long: TimeInterval = 3.5

    let message: String
    let config: Config

    @Binding var isShowing: Bool

    func body(content: Content) -> some View {
        ZStack {
            content
            toastView
        }
    }

    private var toastView: some View {
        VStack {
            Spacer()
            if isShowing {
                Group {
                    Text(message)
                        .multilineTextAlignment(.center)
                        .foregroundColor(config.textColor)
                        .padding(8)
                }
                .background(config.backgroundColor)
                .cornerRadius(8)
                .onAppear {
                    Task {
                        try? await Task.sleep(seconds: config.duration)
                        isShowing = false
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 100)
        .animation(config.animation, value: isShowing)
        .transition(config.transition)
    }

    struct Config {
        let textColor: Color
        let backgroundColor: Color
        let duration: TimeInterval
        let transition: AnyTransition
        let animation: Animation

        init(textColor: Color = .primary,
             backgroundColor: Color = .secondary.opacity(0.588),
             duration: TimeInterval = Toast.short,
             transition: AnyTransition = .opacity,
             animation: Animation = .linear(duration: 0.3)) {
            self.textColor = textColor
            self.backgroundColor = backgroundColor
            self.duration = duration
            self.transition = transition
            self.animation = animation
        }
    }
}

extension View {
    /**
     Display a short toast message

     - Parameters:
        - message: The message
        - isShowing: Binding bool for when to display
        - config: Configuration for the toast

     - Returns: Toast message view.
     */
    func toast(message: String, isShowing: Binding<Bool>, config: Toast.Config) -> some View {
        self.modifier(Toast(message: message, config: config, isShowing: isShowing))
    }
}

// MARK: - ViewDidLoad
struct ViewDidLoadModifier: ViewModifier {
    @State private var didLoad = false
    private let action: (() -> Void)?

    init(perform action: (() -> Void)? = nil) {
        self.action = action
    }

    func body(content: Content) -> some View {
        content.onAppear {
            if didLoad == false {
                didLoad = true
                action?()
            }
        }
    }
}

extension View {
    /**
     Modifier to emulate UIKit's viewDidLoad

     SwiftUI doesn't have function that is similiar to UIKit's viewDidLoad, so a customised modifier is necessary to emulate it

     - Parameters:
        - perform: The action to peform once received

     - Returns: View.
     */
    func onLoad(perform action: (() -> Void)? = nil) -> some View {
        modifier(ViewDidLoadModifier(perform: action))
    }
}

// MARK: - Shimmering
public struct ShimmerConfiguration {
    public let gradient: Gradient
    public let startPoint: (start: UnitPoint, end: UnitPoint)
    public let endPoint: (start: UnitPoint, end: UnitPoint)
    public let duration: TimeInterval
    public let opacity: Double

    public static let `default` = ShimmerConfiguration(
        gradient: Gradient(colors: [Color(CustomColor.Skeleton.background), Color(CustomColor.Skeleton.highlight), Color(CustomColor.Skeleton.background)]),
        startPoint: (start: UnitPoint(x: -1, y: 0.5), end: .leading),
        endPoint: (start: .trailing, end: UnitPoint(x: 2, y: 0.5)),
        duration: 2,
        opacity: 1
      )
}

struct ShimmeringView<Content: View>: View {
    private let content: () -> Content
    private let configuration: ShimmerConfiguration

    @State private var startPoint: UnitPoint
    @State private var endPoint: UnitPoint
    @Binding private var isPresented: Bool

    init(configuration: ShimmerConfiguration, isPresented: Binding<Bool>, content: @escaping () -> Content) {
        self.configuration = configuration
        self.content = content

        _isPresented = isPresented
        _startPoint = .init(wrappedValue: configuration.startPoint.start)
        _endPoint = .init(wrappedValue: configuration.startPoint.end)
    }

    var body: some View {
        ZStack {
            content()
                .background(isPresented ? Color(CustomColor.Skeleton.background) : .clear)

            if isPresented {
                LinearGradient(
                    gradient: configuration.gradient,
                    startPoint: startPoint,
                    endPoint: endPoint
                )
                .opacity(configuration.opacity)
                .onAppear {
                    withAnimation(Animation.linear(duration: configuration.duration).repeatForever(autoreverses: false)) {
                        startPoint = configuration.endPoint.start
                        endPoint = configuration.endPoint.end
                    }
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

public struct ShimmerModifier: ViewModifier {
    let configuration: ShimmerConfiguration
    let isPresented: Binding<Bool>

    public func body(content: Content) -> some View {
        ShimmeringView(configuration: configuration, isPresented: isPresented) { content }
    }
}

public extension View {
    /**
     Add shimmering effect to SwiftUI's View

     - Parameters:
        - configuration: The configuration for the shimmering effect
        - isPresented: Binding bool status on whether to display the shimmering effect

     - Returns: View.
     */
    func shimmer(configuration: ShimmerConfiguration = .default, isPresented: Binding<Bool>) -> some View {
        modifier(ShimmerModifier(configuration: configuration, isPresented: isPresented))
    }
}
