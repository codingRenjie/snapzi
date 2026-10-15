import Foundation

enum DebugSettings {
    #if DEBUG
    static var skipCamera: Bool {
        get { UserDefaults.standard.object(forKey: "snapzi.debugSkipCamera") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "snapzi.debugSkipCamera") }
    }
    #else
    static var skipCamera: Bool { false }
    #endif
}
