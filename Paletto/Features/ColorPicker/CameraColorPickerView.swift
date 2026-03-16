import SwiftUI

/// Camera screen for picking colors from the real world
struct CameraColorPickerView: View {
    @StateObject private var viewModel = CameraColorPickerViewModel()
    @State private var navigateToDetail = false
    @State private var savedPalette: ColorPalette?
    @State private var showSaveDialog = false
    @State private var paletteName = ""
    @State private var isCameraActive = false
    @State private var showSaveError = false
    @State private var saveErrorMessage = ""

    var body: some View {
        NavigationStack {
            ZStack {
                if !viewModel.isCameraAvailable {
                    simulatorPlaceholder
                } else {
                    switch viewModel.cameraPermission {
                    case .authorized:
                        cameraContent
                    case .denied, .restricted:
                        permissionDenied
                    case .unknown:
                        ProgressView()
                            .onAppear { viewModel.checkPermission() }
                    }
                }
            }
            .navigationTitle(L10n.cameraTitle.localized)
            .navigationBarTitleDisplayMode(.inline)
            .alert(L10n.cameraSaveTitle.localized, isPresented: $showSaveDialog) {
                TextField(L10n.cameraSavePlaceholder.localized, text: $paletteName)
                Button(L10n.save.localized) { savePalette() }
                Button(L10n.cancel.localized, role: .cancel) {}
            }
            .navigationDestination(isPresented: $navigateToDetail) {
                if let palette = savedPalette {
                    PaletteDetailView(palette: palette)
                }
            }
            .onAppear {
                viewModel.checkPermission()
                isCameraActive = true
            }
            .onDisappear {
                isCameraActive = false
            }
            .alert(L10n.error.localized, isPresented: $showSaveError) {
                Button(L10n.done.localized, role: .cancel) {}
            } message: {
                Text(saveErrorMessage)
            }
        }
    }

    // MARK: - Camera Content

    private var cameraContent: some View {
        ZStack {
            CameraPreviewView(onColorSampled: { r, g, b in
                viewModel.updateColor(r: r, g: g, b: b)
            }, isActive: isCameraActive)
            .ignoresSafeArea()

            // Crosshair
            VStack {
                Spacer()
                crosshair
                Spacer()
                bottomPanel
            }
        }
    }

    private var crosshair: some View {
        ZStack {
            // Outer gradient ring
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 2.5
                )
                .frame(width: 44, height: 44)
                .shadow(color: .black.opacity(0.4), radius: 4)

            // Inner dot
            Circle()
                .fill(Color.white)
                .frame(width: 5, height: 5)
                .shadow(color: .black.opacity(0.3), radius: 1)
        }
        .accessibilityHidden(true)
    }

    private var bottomPanel: some View {
        VStack(spacing: 14) {
            // Current color display
            if let color = viewModel.currentColor {
                HStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                        .fill(color.color)
                        .frame(width: 54, height: 54)
                        .shadow(color: color.color.opacity(0.4), radius: 6, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                                .strokeBorder(SemanticColors.glassBorder, lineWidth: 1)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(color.hex)
                            .font(.body.monospaced().weight(.semibold))
                            .foregroundColor(.white)
                        Text("RGB: \(color.rgbString)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()

                    Button {
                        viewModel.addCurrentColor()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2)
                    }
                    .buttonStyle(.scale)
                    .accessibilityLabel(L10n.cameraAddA11y.localized)
                }
                .accessibilityElement(children: .combine)
            }

            // Picked colors strip
            if !viewModel.pickedColors.isEmpty {
                HStack(spacing: 6) {
                    ForEach(viewModel.pickedColors) { color in
                        RoundedRectangle(cornerRadius: Constants.UI.smallCornerRadius)
                            .fill(color.color)
                            .frame(width: Constants.UI.colorSwatchSize, height: Constants.UI.colorSwatchSize)
                            .shadow(color: color.color.opacity(0.3), radius: 3, y: 1)
                            .overlay(
                                RoundedRectangle(cornerRadius: Constants.UI.smallCornerRadius)
                                    .strokeBorder(SemanticColors.glassBorder, lineWidth: 0.5)
                            )
                            .accessibilityLabel("Picked color \(color.hex)")
                    }
                    Spacer()
                    if viewModel.pickedColors.count >= 2 {
                        Button(L10n.done.localized) {
                            showSaveDialog = true
                        }
                        .font(.body.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, Constants.UI.paddingLarge)
                        .padding(.vertical, 10)
                        .background(SemanticColors.brandGradient)
                        .cornerRadius(Constants.UI.cornerRadius)
                        .shadow(color: SemanticColors.gradientStart.opacity(0.3), radius: 4, y: 2)
                        .buttonStyle(.scale)
                    }
                }
            }
        }
        .padding(Constants.UI.padding)
        .background(.ultraThinMaterial)
    }

    // MARK: - Fallback States

    private var permissionDenied: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(SemanticColors.gradientStart.opacity(0.1))
                    .frame(width: 110, height: 110)
                Image(systemName: "camera.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(SemanticColors.brandGradient)
            }
            .accessibilityHidden(true)
            Text(L10n.cameraPermissionTitle.localized)
                .font(.title3.weight(.semibold))
            Text(L10n.cameraPermissionMessage.localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button(L10n.cameraPermissionButton.localized) {
                viewModel.openSettings()
            }
            .font(.body.weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, Constants.UI.paddingXL)
            .padding(.vertical, 12)
            .background(SemanticColors.brandGradient)
            .cornerRadius(Constants.UI.cornerRadiusLarge)
            .buttonStyle(.scale)
        }
        .padding(Constants.UI.paddingXL)
    }

    private var simulatorPlaceholder: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(SemanticColors.gradientStart.opacity(0.1))
                    .frame(width: 110, height: 110)
                Image(systemName: "camera.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(SemanticColors.brandGradient)
            }
            .accessibilityHidden(true)
            Text(L10n.cameraUnavailableTitle.localized)
                .font(.title3.weight(.semibold))
            Text(L10n.cameraUnavailableMessage.localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(Constants.UI.paddingXL)
    }

    // MARK: - Actions

    private func savePalette() {
        Task {
            do {
                let palette = try await viewModel.savePalette(name: paletteName)
                savedPalette = palette
                navigateToDetail = true
            } catch {
                saveErrorMessage = error.localizedDescription
                showSaveError = true
            }
        }
    }
}

