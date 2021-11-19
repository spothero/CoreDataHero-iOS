// Copyright © 2021 SpotHero, Inc. All rights reserved.

import CoreData

extension NSPersistentStore {
    /// Deletes the store's .sqlite, .sqlite-shm, and .sqlite-wal files.
    func deleteStoreFiles() throws {
        guard let storeURLPath = self.url?.path else {
            return
        }
        
        let filePaths = [
            storeURLPath, // The .sqlite file
            storeURLPath.appending("-shm"), // The shared memory (.sqlite-shm) file
            storeURLPath.appending("-wal"), // The write ahead logging (.sqlite-wal) file
        ]
        
        for filePath in filePaths {
            try FileManager.default.deleteFileIfFileExists(atPath: filePath)
        }
    }
}

// MARK: - FileManager + Utilities

private extension FileManager {
    func deleteFileIfFileExists(atPath path: String) throws {
        if self.fileExists(atPath: path) {
            try self.removeItem(atPath: path)
        }
    }
}
