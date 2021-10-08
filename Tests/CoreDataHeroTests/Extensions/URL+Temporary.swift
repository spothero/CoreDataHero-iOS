//
//  File.swift
//  
//
//  Created by Kyle Haptonstall on 10/8/21.
//

import Foundation

extension URL {
    
    /// A URL for a temporary directory.
    static var temporary: URL {
        return FileManager.default.temporaryDirectory
    }
    
}
