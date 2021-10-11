// Copyright © 2021 SpotHero, Inc. All rights reserved.

import CoreData
@testable import CoreDataHero
import XCTest

final class CoreDataOperatorSQLiteTests: XCTestCase, CoreDataOperatorTesting {
    // MARK: Properties
    
    fileprivate static let modelName = "CoreDataHero"
    
    var coreDataOperator: CoreDataOperator = .mocked(
        name: CoreDataOperatorSQLiteTests.modelName,
        storeType: .sqlite,
        managedObjectModel: .mocked
    )
    
    // MARK: Clear Core Data Tests
    
    func testClearCoreDataClearsAllDatabaseFiles() {
        let modelName = CoreDataOperatorSQLiteTests.modelName
        
        // Define the paths where the database and related files will live.
        let databaseFileURL = URL.temporary.appendingPathComponent("\(modelName).sqlite")
        
        let filePaths = [
            databaseFileURL.path,
            databaseFileURL.path.appending("-shm"), // Shared memory file
            databaseFileURL.path.appending("-wal"), // Write ahead logging file
        ]
        
        // Create a local operator so we don't have to worry about re-initializing
        // the shared coreDataOperator property.
        let operatorToClear: CoreDataOperator = .mocked(
            name: modelName,
            storeType: .sqlite,
            managedObjectModel: .mocked,
            databaseURL: databaseFileURL
        )
        
        // After initializing the Core Data stack, very 3 files exist (.sqlite, .sqlite-shm, .sqlite-wal).
        for path in filePaths {
            XCTAssertTrue(FileManager.default.fileExists(atPath: path),
                          "Missing file: \(path)")
        }
        
        // Clear Core Data.
        operatorToClear.clearCoreData()
        
        // Verify all 3 files were deleted.
        for path in filePaths {
            XCTAssertFalse(FileManager.default.fileExists(atPath: path),
                           "File was not deleted: \(path)")
        }
    }
    
    // MARK: Create Tests
    
    func testNewInstance() {
        self.verifyNewInstanceSucceeds()
    }
    
    // MARK: Exists Tests
    
    func testExists() {
        self.verifyExistsSucceeds()
    }
    
    func testExistsWithPredicate() {
        self.verifyExistsWithPredicateSucceeds()
    }
    
    // MARK: Count Tests
    
    func testCount() {
        self.verifyCountSucceeds()
    }
    
    func testCountWithPredicate() {
        self.verifyCountWithPredicateSucceeds()
    }
    
    // MARK: Fetch Tests
    
    func testFetch() {
        self.verifyFetchSucceeds()
    }
    
    func testFetchWithPredicate() {
        self.verifyFetchWithPredicateSucceeds()
    }
    
    func testFetchMultiple() {
        self.verifyFetchMultipleSucceeds()
    }
    
    func testFetchMultipleWithPredicate() {
        self.verifyFetchMultipleWithPredicateSucceeds()
    }
    
    func testFetchMultipleWithSortDescriptors() {
        self.verifyFetchMultipleWithSortDescriptorsSucceeds()
    }
    
    func testFetchMultipleWithFetchLimit() {
        self.verifyFetchMultipleWithFetchLimitSucceeds()
    }
    
    // MARK: Delete Tests
    
    func testDeleteSingleObject() {
        self.verifyDeleteSingleObjectsSucceeds()
    }
    
    func testDeleteAllObjects() {
        self.verifyDeleteAllObjectsSucceeds()
    }
    
    func testDeleteAllObjectsWithPredicate() {
        self.verifyDeleteAllObjectsWithPredicateSucceeds()
    }
    
    func testDeleteAllObjectsUsingBatchDelete() throws {
        self.verifyDeleteAllObjectsUsingBatchDeleteSucceeds()
    }
}
