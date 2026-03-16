import SwiftUI

/// Magnifier overlay for tap-to-pick color from image
struct MagnifierOverlay: View {
    let image: UIImage
    @Binding var position: CGPoint?
    @Binding var pickedColor: PaletteColor?
    let onPick: (CGPoint) -> Void
    let onRelease: () -> Void

    /// Tracks when the drag started so we can enforce a 0.3s hold before activating.
    @State private var dragStartTime: Date?
    /// Whether the hold threshold has been met for the current gesture.
    @State private var isActivated = false

    private let activationDuration: TimeInterval = 0.3

    var body: some View {
        GeometryReader { geometry in
            // NOTE: This overlay sits directly on Image.resizable().aspectRatio(.fit),
            // so geometry.size IS the image display size — no letterbox/pillarbox offset needed.
            let viewSize = geometry.size

            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { drag in
                            // Record start time on first callback
                            if dragStartTime == nil {
                                dragStartTime = Date()
                            }

                            // Only activate after holding for the required duration
                            guard isActivated || Date().timeIntervalSince(dragStartTime!) >= activationDuration else {
                                return
                            }
                            isActivated = true

                            let location = drag.location

                            // Clamp to view bounds
                            guard location.x >= 0, location.x <= viewSize.width,
                                  location.y >= 0, location.y <= viewSize.height else {
                                position = nil
                                return
                            }

                            position = location

                            // Normalize directly — overlay size = image display size
                            let normalizedX = min(max(location.x / viewSize.width, 0), 1)
                            let normalizedY = min(max(location.y / viewSize.height, 0), 1)

                            onPick(CGPoint(x: normalizedX, y: normalizedY))
                        }
                        .onEnded { _ in
                            if isActivated {
                                onRelease()
                            }
                            dragStartTime = nil
                            isActivated = false
                        }
                )
                .overlay {
                    if let pos = position, let color = pickedColor {
                        magnifierView(at: pos, color: color, in: viewSize)
                    }
                }
        }
    }

    @ViewBuilder
    private func magnifierView(at position: CGPoint, color: PaletteColor, in size: CGSize) -> some View {
        let magnifierSize = Constants.Magnifier.size
        // Position magnifier above finger
        let offsetY: CGFloat = -magnifierSize - 20

        ZStack {
            // Zoomed image portion
            Circle()
                .fill(color.color)
                .frame(width: magnifierSize, height: magnifierSize)
                .overlay(
                    Circle()
                        .strokeBorder(color.color, lineWidth: Constants.Magnifier.borderWidth)
                )
                .overlay(
                    // Crosshair
                    ZStack {
                        Rectangle()
                            .fill(.white.opacity(0.8))
                            .frame(width: 1, height: magnifierSize * 0.4)
                        Rectangle()
                            .fill(.white.opacity(0.8))
                            .frame(width: magnifierSize * 0.4, height: 1)
                    }
                )
                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)

            // HEX label below magnifier
            Text(color.hex)
                .font(.caption2.monospaced())
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.ultraThinMaterial)
                .cornerRadius(4)
                .offset(y: magnifierSize / 2 + 12)
        }
        .position(
            x: position.x,
            y: position.y + offsetY
        )
        .accessibilityLabel(L10n.magnifierA11y.localized(args: ["hex": color.hex]))
    }
}

