//
//  ManifestRepositoryError.swift
//  ProfilePayloads
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation

public enum ManifestRepositoryError: Error {
    case unknownError
    case alreadyFetchingIndex
    case alreadyDownloadingUpdates
    case noIndex
    case noUpdates
    case repositoryNotConfigured(URL)
    case statusCodeError(Int, URLRequest)
}

extension ManifestRepositoryError: LocalizedError {
    public var localizedDescription: String {
        switch self {
        case .unknownError:
            return "Unknown error"
        case .alreadyFetchingIndex:
            return "Already fetching index"
        case .alreadyDownloadingUpdates:
            return "Already downloading updates"
        case .noIndex:
            return "No index available"
        case .noUpdates:
            return "No updates available"
        case .repositoryNotConfigured(let repositoryURL):
            return "No repository was configured for the url: \(repositoryURL)"
        case let .statusCodeError(statusCode, request):
            return "Unexpected HTTP status code \(statusCode) for \(request)"
        }
    }
}
