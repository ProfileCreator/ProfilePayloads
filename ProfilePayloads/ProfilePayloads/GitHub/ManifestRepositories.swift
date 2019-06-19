//
//  ManifestRepositories.swift
//  ProfilePayloads
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation

func += <K, V> (left: inout [K: V], right: [K: V]) {
    for (k, v) in right {
        left[k] = v
    }
}

public class ManifestRepositories {

    // MARK: -
    // MARK: Static Variables

    public static let shared = ManifestRepositories()

    // MARK: -
    // MARK: Public Variables

    public var repositories = Set<ManifestRepository>()

    // MARK: -
    // MARK: Initialization

    private init() {}

    // MARK: -
    // MARK: Configure

    public func configure(addRepository url: URL) {
        let newRepository = ManifestRepository(url: url)
        self.repositories.insert(newRepository)
    }

    // MARK: -
    // MARK: Fetch Index

    public func fetchIndexes(ignoreCache: Bool, completionHandler: @escaping (Result<[String: Any]>) -> Void) {
        self.fetchIndexes(repositoryURL: URL(string: kURLGitHubRepositoryProfileManifests)!, ignoreCache: ignoreCache, completionHandler: completionHandler)
    }

    public func fetchIndexes(repositoryURL url: URL, ignoreCache: Bool, completionHandler: @escaping (Result<[String: Any]>) -> Void) {
        if let repository = self.repositories.first(where: { $0.url == url }) {
            var updates = [String: Any]()
            repository.fetchIndex(forType: .manifests, ignoreCache: ignoreCache) { resultManifests in
                if case let .success(updatesManifests) = resultManifests {
                    updates += updatesManifests
                    repository.fetchIndex(forType: .icons, ignoreCache: ignoreCache) { resultIcons in
                        if case let .success(updatesIcons) = resultIcons {
                            updates += updatesIcons
                            completionHandler(.success(updates))
                        } else {
                            completionHandler(resultIcons)
                        }
                    }
                } else {
                    completionHandler(resultManifests)
                }
            }
        } else {
            completionHandler(.failure(ManifestRepositoryError.repositoryNotConfigured(url)))
        }
    }

    // MARK: -
    // MARK: Download Updates

    public func downloadUpdates(completionHandler: @escaping (Result<[URL]>) -> Void) {
        self.downloadUpdates(repositoryURL: URL(string: kURLGitHubRepositoryProfileManifests)!, completionHandler: completionHandler)
    }

    public func downloadUpdates(repositoryURL url: URL, completionHandler: @escaping (Result<[URL]>) -> Void) {
        if let repository = self.repositories.first(where: { $0.url == url }) {
            var downloadedUpdates = [URL]()
            repository.downloadUpdates(forType: .manifests) { resultManifests in
                if case let .success(downloadedUpdatesManifests) = resultManifests {
                    downloadedUpdates.append(contentsOf: downloadedUpdatesManifests)
                    repository.downloadUpdates(forType: .icons) { resultIcons in
                        if case let .success(downloadedUpdatesIcons) = resultManifests {
                            downloadedUpdates.append(contentsOf: downloadedUpdatesIcons)
                            completionHandler(.success(downloadedUpdates))
                        } else {
                            completionHandler(resultIcons)
                        }
                    }
                } else {
                    completionHandler(resultManifests)
                }
            }
        } else {
            completionHandler(.failure(ManifestRepositoryError.repositoryNotConfigured(url)))
        }
    }
}
