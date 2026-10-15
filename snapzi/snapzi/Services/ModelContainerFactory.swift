import Foundation
import SwiftData

/// 开发期模型变更后，旧 SQLite 可能无法轻量迁移；失败时删除本地库并重建，避免启动即 crash。
enum ModelContainerFactory {
    private static let storeBaseName = "SnapZi"

    static func makeShared() -> ModelContainer {
        let schema = Schema([
            LearnedCharacter.self,
            CapturedWordPhoto.self,
        ])

        if let container = openContainer(schema: schema, wipeFirst: false) {
            return container
        }

        removeStoreFiles()
        if let container = openContainer(schema: schema, wipeFirst: false) {
            return container
        }

        let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: [memoryConfig])
        } catch {
            fatalError("Could not create in-memory ModelContainer: \(error)")
        }
    }

    private static func openContainer(schema: Schema, wipeFirst: Bool) -> ModelContainer? {
        if wipeFirst { removeStoreFiles() }
        ensureApplicationSupportExists()
        let url = storeURL()
        let config = ModelConfiguration(schema: schema, url: url)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            print("[SnapZi] ModelContainer open failed: \(error)")
            return nil
        }
    }

    private static func storeURL() -> URL {
        applicationSupportDirectory().appending(path: "\(storeBaseName).store")
    }

    private static func removeStoreFiles() {
        let dir = applicationSupportDirectory()
        let names = [
            "\(storeBaseName).store",
            "\(storeBaseName).store-shm",
            "\(storeBaseName).store-wal",
            // 旧版默认文件名（无自定义 URL 时）
            "default.store",
            "default.store-shm",
            "default.store-wal",
        ]
        for name in names {
            let url = dir.appending(path: name)
            if FileManager.default.fileExists(atPath: url.path) {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    private static func applicationSupportDirectory() -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    }

    private static func ensureApplicationSupportExists() {
        let dir = applicationSupportDirectory()
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }
}
