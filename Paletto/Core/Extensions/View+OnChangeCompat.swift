import SwiftUI

// MARK: - Availability-safe onChange wrapper

extension View {
    /// Uses the iOS 17 two-parameter `onChange` when available, falls back to the
    /// deprecated single-parameter overload on iOS 16.
    @ViewBuilder
    func onChangeCompat<V: Equatable>(of value: V, perform action: @escaping (V) -> Void) -> some View {
        if #available(iOS 17.0, *) {
            self.onChange(of: value) { _, newValue in
                action(newValue)
            }
        } else {
            self.onChange(of: value) { newValue in
                action(newValue)
            }
        }
    }
}

