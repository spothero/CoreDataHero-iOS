// Copyright © 2021 SpotHero, Inc. All rights reserved.

import CoreData
@testable import CoreDataHero
import XCTest

final class CoreDataOperatorSQLiteTests: XCTestCase, CoreDataOperatorTesting {
    // MARK: Properties
    
    var coreDataOperator: CoreDataOperator = .mocked(name: "CoreDataHero", storeType: .sqlite, managedObjectModel: .mocked)
    
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

// MARK: - Utilities

private extension CoreDataOperatorSQLiteTests {
    enum SQLiteFileType: CaseIterable {
        /// Refers to the .sqlite file.
        case databaseFile
        /// Refers to the .sqlite-shm file.
        case sharedMemoryFile
        /// Refers to the .sqlite-wal file.
        case writeAheadLogFile
        
        var `extension`: String {
            switch self {
            case .databaseFile:
                return ".sqlite"
            case .sharedMemoryFile:
                return ".sqlite-shm"
            case .writeAheadLogFile:
                return ".sqlite-wal"
            }
        }
        
        /// The URL for the current file type.
        var url: URL {
            let modelName = CoreDataOperatorSQLiteTests.modelName
            return .temporary.appendingPathComponent("\(modelName)\(self.extension)")
        }
    }
}
