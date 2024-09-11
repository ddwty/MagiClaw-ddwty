//
//  extension.swift
//  RoboticDataCollection
//
//  Created by Tianyu on 8/6/24.
//

import Foundation
import SwiftUI
import Combine

extension View {
    func printSizeInfo(_ label: String = "") -> some View {
        background(
            GeometryReader { proxy in
                Color.clear
                    .task(id: proxy.size) {
                        print(label, proxy.size)
                    }
            }
        )
    }
}
struct historyAlignmentID: AlignmentID {
    static func defaultValue(in dim: ViewDimensions) -> CGFloat {
        dim[VerticalAlignment.center]
    }
}
extension VerticalAlignment {
    static let historyAlignment = VerticalAlignment(historyAlignmentID.self)
}


struct KeyboardAwareModifier: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0

    private var keyboardHeightPublisher: AnyPublisher<CGFloat, Never> {
        Publishers.Merge(
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardWillShowNotification)
                .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue }
                .map { $0.cgRectValue.height },
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardWillHideNotification)
                .map { _ in CGFloat(0) }
       ).eraseToAnyPublisher()
    }

    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboardHeight)
            .onReceive(keyboardHeightPublisher) { self.keyboardHeight = $0 }
    }
}

extension View {
    func KeyboardAwarePadding() -> some View {
        ModifiedContent(content: self, modifier: KeyboardAwareModifier())
    }
}

extension View {
    func hideKeyboard() {
        let resign = #selector(UIResponder.resignFirstResponder)
        UIApplication.shared.sendAction(resign, to: nil, from: nil, for: nil)
    }
}


class KeyboardResponder: ObservableObject {
    @Published var keyboardHeight: CGFloat = 0

    private var cancellables = Set<AnyCancellable>()

    init() {
        // 监听键盘出现的通知
        let keyboardWillShow = NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillShowNotification)
            .map { notification -> CGFloat in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    return keyboardFrame.height
                }
                return 0
            }
            .eraseToAnyPublisher()

        // 监听键盘隐藏的通知
        let keyboardWillHide = NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }
            .eraseToAnyPublisher()

        // 合并通知
        Publishers.Merge(keyboardWillShow, keyboardWillHide)
            .receive(on: DispatchQueue.main)
            .assign(to: &$keyboardHeight)
    }
}



private struct KeyboardHeightEnvironmentKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    /// Height of software keyboard when visible
    var keyboardHeight: CGFloat {
        get { self[KeyboardHeightEnvironmentKey.self] }
        set { self[KeyboardHeightEnvironmentKey.self] = newValue }
    }
}

struct KeyboardHeightEnvironmentValue: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .environment(\.keyboardHeight, keyboardHeight)
            /// Approximation of Apple's keyboard animation
            /// source: https://forums.developer.apple.com/forums/thread/48088
            .animation(.interpolatingSpring(mass: 3, stiffness: 1000, damping: 500, initialVelocity: 0), value: keyboardHeight)
            .background {
                GeometryReader { keyboardProxy in
                    GeometryReader { proxy in
                        Color.clear
                            .onChange(of: keyboardProxy.safeAreaInsets.bottom - proxy.safeAreaInsets.bottom) { newValue in
                                DispatchQueue.main.async {
                                    if keyboardHeight != newValue {
                                        keyboardHeight = newValue
                                    }
                                }
                            }
                    }
                    .ignoresSafeArea(.keyboard)
                }
            }
    }
}

public extension View {
    /// Adds an environment value for software keyboard height when visible
    ///
    /// Must be applied on a view taller than the keyboard that touches the bottom edge of the safe area.
    /// Access keyboard height in any child view with
    /// @Environment(\.keyboardHeight) var keyboardHeight
    func keyboardHeightEnvironmentValue() -> some View {
        #if os(iOS)
        modifier(KeyboardHeightEnvironmentValue())
        #else
        environment(\.keyboardHeight, 0)
        #endif
    }
}


extension View {
    /// Applies the given transform if the given condition evaluates to `true`.
    /// https://stackoverflow.com/questions/77425304/swiftui-disable-swipeactions-on-specific-rows-only
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

struct ReverseLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .center, spacing: 8) {
            configuration.title
            configuration.icon
        }
    }
}

extension View {
    //强制改变某个视图方向
    @ViewBuilder
    func forceRotation(orientation: UIInterfaceOrientationMask) -> some View {
        if UIDevice.current.userInterfaceIdiom == .phone {
            self.onAppear() {
                AppDelegate.orientationLock = orientation
            }
            // Reset orientation to previous setting
            let currentOrientation = AppDelegate.orientationLock
            self.onDisappear() {
                AppDelegate.orientationLock = currentOrientation
            }
        } else {
            self
        }
    }
}

struct ExitButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        
        return configuration.label
        
            .padding()
            .background(
                Circle()
                    .fill(Color(white: colorScheme == .dark ? 0.19 : 0.93))
                    //.brightness(isPressed ? 0.1 : 0) // Aclara el color cuando está presionado
                    .frame(width: 40, height: 40)
            )
            .overlay(
                Image(systemName: "xmark")
                    .resizable()
                    .scaledToFit()
                    .font(Font.body.weight(.bold))
                    .scaleEffect(0.416)
                    .foregroundColor(Color(white: colorScheme == .dark ? 0.62 : 0.51))
                    
            )
            .buttonStyle(PlainButtonStyle())
            .opacity(isPressed ? 0.18 : 1)

    }
}
