import Foundation

extension UndoManager {
    /// Executes an action and groups it under a named undo action.
    /// Caller is responsible for registering the inverse action inside `action`.
    func performUndoGroup(_ label: String, _ action: () -> Void) {
        beginUndoGrouping()
        action()
        endUndoGrouping()
        setActionName(label)
    }
}
