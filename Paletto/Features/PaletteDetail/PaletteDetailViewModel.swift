import SwiftUI
import WidgetKit

/// ViewModel for palette detail screen
final class PaletteDetailViewModel: ObservableObject {

    @Published var palette: ColorPalette
    @Published var contrastMatrix: [[ContrastResult]] = []
    @Published var isSaving = false
    @Published var showExport = false
    @Published var showHarmony = false
    @Published var showShare = false
    @Published var showWidgetConfirmation = false
    @Published var harmonySourceColor: PaletteColor?

    // Tag editor state
    @Published var showTagEditor = false
    @Published var newTagText = ""
    @Published var tagError: String?

    var undoManager: UndoManager?

    private let contrastService: ContrastCheckerServiceProtocol
    private let storageService: PaletteStorageServiceProtocol
    private let settingsManager: SettingsManagerProtocol

    init(
        palette: ColorPalette,
        contrastService: ContrastCheckerServiceProtocol = ContrastCheckerService(),
        storageService: PaletteStorageServiceProtocol = PaletteStorageService.shared,
        settingsManager: SettingsManagerProtocol = SettingsManager.shared
    ) {
        self.palette = palette
        self.contrastService = contrastService
        self.storageService = storageService
        self.settingsManager = settingsManager
        updateContrastMatrix()
    }

    // MARK: - Actions

    func autoAssignRoles() {
        let previousColors = palette.colors

        palette.colors = contrastService.assignRoles(to: palette.colors)
        // Register inverse: restore previous colors
        undoManager?.registerUndo(withTarget: self) { target in
            target.palette.colors = previousColors
            target.updateContrastMatrix()
            target.save()
        }
        undoManager?.setActionName(L10n.libraryUndoAutoAssign.localized)

        updateContrastMatrix()
        save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    func updateRole(for colorId: UUID, to role: ColorRole) {
        guard let index = palette.colors.firstIndex(where: { $0.id == colorId }) else { return }
        let previousRole = palette.colors[index].role

        undoManager?.beginUndoGrouping()
        palette.colors[index].role = role
        undoManager?.registerUndo(withTarget: self) { target in
            if let idx = target.palette.colors.firstIndex(where: { $0.id == colorId }) {
                target.palette.colors[idx].role = previousRole
            }
        }
        undoManager?.endUndoGrouping()
        undoManager?.setActionName(L10n.libraryUndoChangeRole.localized)

        save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    func suggestFix(foregroundIndex: Int, backgroundIndex: Int) -> PaletteColor? {
        guard palette.colors.indices.contains(foregroundIndex),
              palette.colors.indices.contains(backgroundIndex) else { return nil }
        return contrastService.suggestFix(
            for: palette.colors[foregroundIndex],
            against: palette.colors[backgroundIndex],
            targetLevel: .aa
        )
    }

    func applyFix(_ fixedColor: PaletteColor, at index: Int) {
        guard palette.colors.indices.contains(index) else { return }
        let previousColor = palette.colors[index]
        let role = previousColor.role

        undoManager?.beginUndoGrouping()
        var updated = fixedColor
        updated.role = role
        palette.colors[index] = updated
        undoManager?.registerUndo(withTarget: self) { target in
            if target.palette.colors.indices.contains(index) {
                target.palette.colors[index] = previousColor
            }
        }
        undoManager?.endUndoGrouping()
        undoManager?.setActionName(L10n.libraryUndoFixContrast.localized)

        updateContrastForColor(at: index)
        save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    func updateName(_ name: String) {
        let previousName = palette.name

        undoManager?.beginUndoGrouping()
        palette.name = name
        undoManager?.registerUndo(withTarget: self) { target in
            target.palette.name = previousName
            target.save()
        }
        undoManager?.endUndoGrouping()
        undoManager?.setActionName(L10n.libraryUndoEditName.localized)

        save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    func copyHex(_ hex: String) {
        UIPasteboard.general.string = hex
        if settingsManager.hapticFeedbackEnabled {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    func openHarmony(for color: PaletteColor) {
        harmonySourceColor = color
        showHarmony = true
    }

    // MARK: - Widget (multi-size)

    func setAsWidget(forKind kind: WidgetKind) {
        SharedDataService.shared.setWidgetPalette(palette, forKind: kind)
        showWidgetConfirmation = true
        if settingsManager.hapticFeedbackEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    // MARK: - Tag editing

    func addTag(_ tag: String) -> Bool {
        let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            tagError = L10n.libraryTagErrorEmpty.localized
            return false
        }

        if trimmed.contains("/") {
            tagError = L10n.libraryTagErrorSlash.localized
            return false
        }

        if trimmed.count > Constants.Palette.maxTagLength {
            tagError = L10n.libraryTagErrorMaxLength.localized
            return false
        }

        if palette.tags.contains(trimmed) {
            tagError = L10n.libraryTagErrorDuplicate.localized
            return false
        }

        if palette.tags.count >= Constants.Palette.maxTagsPerPalette {
            tagError = L10n.libraryTagErrorMaxCount.localized
            return false
        }

        addTagToCurrentPalette(tag: trimmed)
        return true
    }

    func addTagToCurrentPalette(tag: String) {
        let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !palette.tags.contains(trimmed) else { return }
        guard palette.tags.count < Constants.Palette.maxTagsPerPalette else { return }

        palette.tags.append(trimmed)
        palette.updatedAt = Date()
        save()
    }

    func removeTag(_ tag: String) {
        palette.tags.removeAll { $0 == tag }
        palette.updatedAt = Date()
        save()
    }

    func clearTagError() {
        tagError = nil
    }

    // MARK: - Private

    private func updateContrastMatrix() {
        contrastMatrix = contrastService.contrastMatrix(for: palette.colors)
    }

    private func updateContrastForColor(at index: Int) {
        contrastMatrix = contrastService.updateContrastMatrix(contrastMatrix, forColorAt: index, in: palette.colors)
    }

    private func save() {
        isSaving = true
        Task { @MainActor in
            do {
                try await storageService.update(palette)
            } catch {
                // Silently fail — UI already shows the updated state
            }
            isSaving = false
        }
    }
}
