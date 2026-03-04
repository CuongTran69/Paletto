import SwiftUI

/// Button style that scales down on press with spring animation
struct ScaleButtonStyle: ButtonStyle {
    var scaleAmount: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleAmount : 1.0)
            .animation(
                .spring(response: Constants.UI.springResponse, dampingFraction: Constants.UI.springDamping),
                value: configuration.isPressed
            )
    }
}

extension ButtonStyle where Self == ScaleButtonStyle {
    static var scale: ScaleButtonStyle { ScaleButtonStyle() }
}

