//
//  ViewModifier.swift
//  tawk.to
//
//  Created by Phua June Jin on 10/12/2022.
//

import SwiftUI

// To display short toast messages
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + config.duration) {
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
    func toast(message: String, isShowing: Binding<Bool>, config: Toast.Config) -> some View {
        self.modifier(Toast(message: message, config: config, isShowing: isShowing))
  }

  func toast(message: String, isShowing: Binding<Bool>, duration: TimeInterval) -> some View {
      self.modifier(Toast(message: message, config: .init(duration: duration), isShowing: isShowing))
    }
}

// Since SwiftUI doesn't yet support ViewDidLoad, need to customise
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
    func onLoad(perform action: (() -> Void)? = nil) -> some View {
        modifier(ViewDidLoadModifier(perform: action))
    }
}
