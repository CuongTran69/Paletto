import SwiftUI

/// Protocol for managing app theme
protocol ThemeManagerProtocol: ObservableObject {
    var currentTheme: AppTheme { get set }
    var colorScheme: ColorScheme? { get }
}

