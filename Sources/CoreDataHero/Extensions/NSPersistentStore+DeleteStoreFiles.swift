// Copyright © 2021 SpotHero, Inc. All rights reserved.

import CoreData

extension NSPersistentStore {
    /// Deletes the store's .sqlite, .sqlite-shm, and .sqlite.wal files.
    func deleteStoreFiles() throws {
        guard let storeURLPath = self.url?.path else {
            return
        }
        
        // Remove the .sqlite file.
        try FileManager.default.removeItem(atPath: storeURLPath)
        // Remove the shared memory (.sqlite-shm) file.
        try FileManager.default.removeItem(atPath: storeURLPath.appending("-shm"))
        // Remove the write ahead logging (.sqlite-wal) file.
        try FileManager.default.removeItem(atPath: storeURLPath.appending("-wal"))
    }
}
