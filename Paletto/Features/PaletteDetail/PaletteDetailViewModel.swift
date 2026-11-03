import SwiftUI
import WidgetKit

/// ViewModel for palette detail screen
@MainActor
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

    // MARK: - Coalescing state
    private var roleChangeCoalesceTimer: Timer?
    private var pendingRoleChange: (colorId: UUID, previousRole: ColorRole?, appliedRole: ColorRole)?
    private var pendingRoleChangeCount: Int = 0

    private let contrastService: ContrastCheckerServiceProtocol
    private let storageService: PaletteStorageServiceProtocol
    private let settingsManager: SettingsManagerProtocol

    /// When non-nil, palette mutations are propagated back through this binding to the caller's state.
    private var paletteBinding: Binding<ColorPalette>?

    /// Creates a ViewModel with a Binding — palette mutations propagate back to the caller's state.
    /// Use this when navigating from a live list (PaletteListView).
    init(
        binding: Binding<ColorPalette>,
        contrastService: ContrastCheckerServiceProtocol = ContrastCheckerService(),
        storageService: PaletteStorageServiceProtocol = PaletteStorageService.shared,
        settingsManager: SettingsManagerProtocol = SettingsManager.shared
    ) {
        self.paletteBinding = binding
        self.palette = binding.wrappedValue
        self.contrastService = contrastService
        self.storageService = storageService
        self.settingsManager = settingsManager
        updateContrastMatrix()
    }

    /// Creates a ViewModel with a local copy — changes are persisted but NOT propagated to caller.
    /// Use this for new/imported palettes where no live list needs updating.
    init(
        palette: ColorPalette,
        contrastService: ContrastCheckerServiceProtocol = ContrastCheckerService(),
        storageService: PaletteStorageServiceProtocol = PaletteStorageService.shared,
        settingsManager: SettingsManagerProtocol = SettingsManager.shared
    ) {
        self.paletteBinding = nil
        self.palette = palette
        self.contrastService = contrastService
        self.storageService = storageService
        self.settingsManager = settingsManager
        updateContrastMatrix()
    }

    /// Propagates the current palette state back through the binding, updating the caller's array.
    private func syncPaletteToCaller() {
        paletteBinding?.wrappedValue = palette
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
            target.syncPaletteToCaller()
        }
        undoManager?.setActionName(L10n.libraryUndoAutoAssign.localized)

        updateContrastMatrix()
        save()
        WidgetCenter.shared.reloadAllTimelines()
        syncPaletteToCaller()
    }

    func updateRole(for colorId: UUID, to role: ColorRole) {
        guard let index = palette.colors.firstIndex(where: { $0.id == colorId }) else { return }
        let previousRole = palette.colors[index].role

        // Coalescing: cancel any pending timer, capture original state, schedule new timer
        roleChangeCoalesceTimer?.invalidate()
        pendingRoleChange = (colorId, previousRole, role)
        pendingRoleChangeCount += 1

        roleChangeCoalesceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.commitPendingRoleChange()
        }

        // Apply immediately for instant UI feedback — registerUndo is deferred to timer
        palette.colors[index].role = role
        save()
        WidgetCenter.shared.reloadAllTimelines()
        syncPaletteToCaller()
    }

    private func commitPendingRoleChange() {
        guard let pending = pendingRoleChange else { return }
        let count = pendingRoleChangeCount
        let appliedRole = pending.appliedRole

        undoManager?.beginUndoGrouping()
        // Restore the captured original state as the undo target
        if let idx = palette.colors.firstIndex(where: { $0.id == pending.colorId }) {
            palette.colors[idx].role = pending.previousRole ?? .none
        }
        undoManager?.registerUndo(withTarget: self) { [weak self] target in
            guard let self else { return }
            // Note: pendingRoleChange is nil at undo-time, so we capture colorId and appliedRole
            // by value above. Do NOT reference self.pendingRoleChange here.
            if let idx = target.palette.colors.firstIndex(where: { $0.id == pending.colorId }) {
                target.palette.colors[idx].role = appliedRole ?? .none
            }
            target.updateContrastMatrix()
            target.save()
            target.syncPaletteToCaller()
        }
        undoManager?.endUndoGrouping()
        undoManager?.setActionName(L10n.libraryUndoChangeRole.localized)

        pendingRoleChange = nil
        pendingRoleChangeCount = 0
        roleChangeCoalesceTimer = nil
        updateContrastMatrix()
        save()
        WidgetCenter.shared.reloadAllTimelines()
        syncPaletteToCaller()
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
            target.updateContrastMatrix()
            target.save()
            target.syncPaletteToCaller()
        }
        undoManager?.endUndoGrouping()
        undoManager?.setActionName(L10n.libraryUndoFixContrast.localized)

        updateContrastForColor(at: index)
        save()
        WidgetCenter.shared.reloadAllTimelines()
        syncPaletteToCaller()
    }

    func updateName(_ name: String) {
        let previousName = palette.name

        undoManager?.beginUndoGrouping()
        palette.name = name
        undoManager?.registerUndo(withTarget: self) { target in
            target.palette.name = previousName
            target.updateContrastMatrix()
            target.save()
            target.syncPaletteToCaller()
        }
        undoManager?.endUndoGrouping()
        undoManager?.setActionName(L10n.libraryUndoEditName.localized)

        save()
        WidgetCenter.shared.reloadAllTimelines()
        syncPaletteToCaller()
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

        // Register undo before adding tag
        let previousTags = palette.tags
        undoManager?.beginUndoGrouping()
        undoManager?.registerUndo(withTarget: self) { target in
            target.palette.tags = previousTags
            target.palette.updatedAt = Date()
            target.save()
            target.syncPaletteToCaller()
        }
        undoManager?.endUndoGrouping()
        undoManager?.setActionName(L10n.libraryUndoAddTag.localized)

        palette.tags.append(trimmed)
        palette.updatedAt = Date()
        save()
        syncPaletteToCaller()
        return true
    }

    func addTagToCurrentPalette(tag: String) {
        let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !palette.tags.contains(trimmed) else { return }
        guard palette.tags.count < Constants.Palette.maxTagsPerPalette else { return }

        // Capture for undo
        let previousTags = palette.tags

        undoManager?.beginUndoGrouping()
        undoManager?.registerUndo(withTarget: self) { target in
            target.palette.tags = previousTags
            target.palette.updatedAt = Date()
            target.save()
            target.syncPaletteToCaller()
        }
        undoManager?.endUndoGrouping()
        undoManager?.setActionName(L10n.libraryUndoAddTag.localized)

        palette.tags.append(trimmed)
        palette.updatedAt = Date()
        save()
        syncPaletteToCaller()
    }

    func removeTag(_ tag: String) {
        // Capture previous state for undo
        let previousTags = palette.tags

        undoManager?.beginUndoGrouping()
        undoManager?.registerUndo(withTarget: self) { target in
            target.palette.tags = previousTags
            target.palette.updatedAt = Date()
            target.save()
            target.syncPaletteToCaller()
        }
        undoManager?.endUndoGrouping()
        undoManager?.setActionName(L10n.libraryUndoRemoveTag.localized)

        palette.tags.removeAll { $0 == tag }
        palette.updatedAt = Date()
        save()
        syncPaletteToCaller()
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
