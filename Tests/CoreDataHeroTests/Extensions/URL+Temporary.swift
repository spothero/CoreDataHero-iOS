// Copyright © 2021 SpotHero, Inc. All rights reserved.

import Foundation

extension URL {
    /// A URL for a temporary directory.
    static var temporary: URL {
        return FileManager.default.temporaryDirectory
    }
}
