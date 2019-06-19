//
//  ManifestRepository.swift
//  ProfilePayloads
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation

public enum ManifestRepositoryType {
    case manifests
    case manifestOverrides
    case icons
    case iconOverrides
}

public class ManifestRepository: Hashable {

    // MARK: -
    // MARK: Public Variables

    public let url: URL
    public let indexURLManifests: URL
    public let indexURLIcons: URL

    public private(set) var lastUpdated: Date?

    public private(set) var indexManifests: [String: Any]?
    public private(set) var indexIcons: [String: Any]?

    public private(set) var updatesAvailableManifests: [String: Any]?
    public private(set) var updatesAvailableIcons: [String: Any]?

    // MARK: -
    // MARK: Internal Variables

    private var isFetchingIndexManifests = false
    private var isFetchingIndexIcons = false

    private var isDownloadingUpdates = false

    // MARK: -
    // MARK: Initialization

    init(url: URL) {
        self.url = url
        var indexURL = URL(string: kURLGitHubUserContent)!
        indexURL.appendPathComponent(url.relativePath)
        self.indexURLManifests = indexURL.appendingPathComponent("master/Manifests/index")
        self.indexURLIcons = indexURL.appendingPathComponent("master/Icons/index")
    }

    // MARK: -
    // MARK: Download

    internal func downloadURLFor(file: String, directory: String) -> URL {
        let baseURL = URL(string: kURLGitHubRepositoryProfileManifestsContent)!
        return baseURL.appendingPathComponent(directory).appendingPathComponent(file)
    }

    internal func downloadURLsForAvailableUpdates(forType type: ManifestRepositoryType) -> [URL] {
        guard let updatesAvailable = self.updatesAvailable(forType: type) else { return [] }

        var updateURLs = [URL]()
        for (_, typeValue) in updatesAvailable {
            guard let typeDict = typeValue as? [String: Any] else {
                continue
            }

            for (_, domainValue) in typeDict {
                guard
                    let domainUpdate = domainValue as? [String: Any],
                    let domainPath = domainUpdate["path"] as? String else {
                        continue
                }

                var domainPathArray = domainPath.components(separatedBy: "/")
                guard 2 <= domainPathArray.count else {
                    Swift.print("Invalid number of entries in domainPathArray: \(domainPathArray)")
                    continue
                }

                let domainFile = domainPathArray.removeLast()
                let domainDirectory = domainPathArray.joined(separator: "/")

                updateURLs.append(self.downloadURLFor(file: domainFile, directory: domainDirectory))
            }

        }
        return updateURLs
    }

    internal func downloadUpdates(forType type: ManifestRepositoryType, completionHandler: @escaping (Result<[URL]>) -> Void) {

        // Verify we're not already downloading updates
        if self.isDownloadingUpdates {
            completionHandler(.failure(ManifestRepositoryError.alreadyDownloadingUpdates))
            return
        }

        let updateURLs = self.downloadURLsForAvailableUpdates(forType: type)
        if updateURLs.isEmpty {
            completionHandler(.success([]))
            return
        }

        // Mark that we are downloading updates
        self.isDownloadingUpdates = true

        Swift.print("Downloading updateURLs: \(updateURLs)")
        DownloadManager.shared.downloadUpdates(fromURLs: updateURLs) { urls, error in
            self.isDownloadingUpdates = false
            Swift.print("Downloaded complete: \(String(describing: error))")
            ProfilePayloads.shared.updateManifests()
            completionHandler(.success(urls ?? [URL]()))
        }
    }

    internal func updatesAvailable(forType type: ManifestRepositoryType) -> [String: Any]? {
        switch type {
        case .manifests:
            return self.updatesAvailableManifests
        case .icons:
            return self.updatesAvailableIcons
        case .manifestOverrides,
             .iconOverrides:
            return nil
        }
    }

    internal func setUpdatesAvailable(_ updates: [String: Any], forType type: ManifestRepositoryType) {
        switch type {
        case .manifests:
            self.updatesAvailableManifests = updates
        case .icons:
            self.updatesAvailableIcons = updates
        case .manifestOverrides,
             .iconOverrides:
            return
        }
    }

    internal func isFetchingIndex(forType type: ManifestRepositoryType) -> Bool {
        switch type {
        case .manifests:
            return self.isFetchingIndexManifests
        case .icons:
            return self.isFetchingIndexIcons
        case .manifestOverrides,
             .iconOverrides:
            return false
        }
    }

    internal func setIsFetchingIndex(_ isFetching: Bool, forType type: ManifestRepositoryType) {
        switch type {
        case .manifests:
            self.isFetchingIndexManifests = isFetching
        case .icons:
            self.isFetchingIndexIcons = isFetching
        case .manifestOverrides,
             .iconOverrides:
            return
        }
    }

    internal func index(ofType type: ManifestRepositoryType) -> [String: Any]? {
        switch type {
        case .manifests:
            return self.indexManifests
        case .icons:
            return self.indexIcons
        case .manifestOverrides,
             .iconOverrides:
            return nil
        }
    }

    internal func setIndex(_ index: [String: Any]?, ofType type: ManifestRepositoryType) {
        switch type {
        case .manifests:
            self.indexManifests = index
        case .icons:
            self.indexIcons = index
        case .manifestOverrides,
             .iconOverrides:
            return
        }
    }

    // MARK: -
    // MARK: Fetch

    internal func fetchIndex(forType type: ManifestRepositoryType, ignoreCache: Bool, completionHandler: @escaping (Result<[String: Any]>) -> Void) {

        // Verify we're not already fetching indexes
        if self.isFetchingIndex(forType: type) {
            completionHandler(.failure(ManifestRepositoryError.alreadyFetchingIndex))
            return
        }

        // Mark that we are fetching index
        self.setIsFetchingIndex(true, forType: type)

        let request: URLRequest
        switch type {
        case .manifests:
            request = URLRequest(url: self.indexURLManifests)
        case .icons:
            request = URLRequest(url: self.indexURLIcons)
        case .manifestOverrides,
             .iconOverrides:
            completionHandler(.failure(ManifestRepositoryError.unknownError))
            return
        }
        let task = URLSession.shared.dataTask(with: request) { [weak self] taskData, taskResponse, taskError in

            // Mark that we have finished fetching the index
            self?.setIsFetchingIndex(false, forType: type)

            var failureError: Error?

            DispatchQueue.main.sync {
                if let error = taskError {
                    failureError = error

                } else if let httpResponse = taskResponse as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    failureError = ManifestRepositoryError.statusCodeError(httpResponse.statusCode, request)

                } else if let data = taskData {

                    var format = PropertyListSerialization.PropertyListFormat.xml
                    do {
                        if let indexDictionary = try PropertyListSerialization.propertyList(from: data,
                                                                                            options: PropertyListSerialization.ReadOptions(),
                                                                                            format: &format) as? [String: Any] {
                            self?.saveIndex(indexDictionary, ofType: type)
                            self?.setIndex(indexDictionary, ofType: type)
                            self?.checkUpdates(forType: type, completionHandler: completionHandler)
                            return
                        } else {
                            failureError = ManifestRepositoryError.unknownError
                        }
                    } catch {
                        failureError = error
                    }
                }

                Swift.print("Failed to download index with error: \(failureError ?? ManifestRepositoryError.unknownError)")

                if !ignoreCache, let indexDictionary = self?.getIndexCache(forType: type) {
                    self?.setIndex(indexDictionary, ofType: type)
                    self?.checkUpdates(forType: type, completionHandler: completionHandler)
                    return
                }

                completionHandler(.failure(failureError ?? ManifestRepositoryError.unknownError))
            }
        }
        task.resume()
    }

    internal func saveIndex(_ index: [String: Any], ofType type: ManifestRepositoryType) {
        guard let indexSaveURL = PayloadUtility.profilePayloadsCacheIndex(forType: type) else { return }
        var error: NSError?
        if let stream = OutputStream(url: indexSaveURL, append: false) {
            stream.open()
            PropertyListSerialization.writePropertyList(index, to: stream, format: .binary, options: 0, error: &error)
            stream.close()
        }
        if error != nil {
            Swift.print("Saving index failed with error: \(String(describing: error?.localizedDescription))")
        }
    }

    internal func getIndexCache(forType type: ManifestRepositoryType) -> [String: Any]? {
        guard
            let indexURL = PayloadUtility.profilePayloadsCacheIndex(forType: type),
            let indexData = try? Data(contentsOf: indexURL),
            let index = manifest(fromData: indexData) else {
                Swift.print("Failed to read index from path: \(String(describing: PayloadUtility.profilePayloadsCacheIndex(forType: type)))")
                return nil
        }
        return index
    }

    // MARK: -
    // MARK: Verify

    internal func checkUpdates(forType type: ManifestRepositoryType, completionHandler: @escaping (Result<[String: Any]>) -> Void) {
        guard let index = self.index(ofType: type) else {
            completionHandler(.failure(ManifestRepositoryError.noIndex))
            return
        }

        var updatesAvailable = [String: Any]()

        for (typeString, typeValue) in index {
            guard
                let typeDict = typeValue as? [String: Any],
                let payloadType = payloadType(forString: typeString) else {
                    continue
            }

            var typeUpdates = [String: Any]()

            for (domain, domainValue) in typeDict {
                guard let domainIndex = domainValue as? [String: Any] else {
                    continue
                }
                if let domainUpdates = self.updatesAvailable(forType: type, domainIdentifier: domain, payloadType: payloadType, domainIndex: domainIndex) {
                    typeUpdates[domain] = domainUpdates
                }
            }

            if !typeUpdates.isEmpty {
                updatesAvailable[typeString] = typeUpdates
            }
        }

        self.setUpdatesAvailable(updatesAvailable, forType: type)

        completionHandler(.success(updatesAvailable))
    }

    internal func updatesAvailable(forType type: ManifestRepositoryType, domainIdentifier: String, payloadType: PayloadType, domainIndex: [String: Any]) -> [String: Any]? {
        switch type {
        case .manifests:
            return manifestUpdatesAvailable(forDomainIdentifier: domainIdentifier, payloadType: payloadType, domainIndex: domainIndex)
        case .icons:
            return iconUpdatesAvailable(forDomainIdentifier: domainIdentifier, ofType: payloadType, domainIndex: domainIndex)
        case .manifestOverrides,
             .iconOverrides:
            return nil
        }
    }

    internal func iconExists(withHash hash: String, forDomainIdentifier domainIdentifier: String, payloadType: PayloadType) -> Bool {
        do {
            // ---------------------------------------------------------------------
            //  Read icon from /Library/Application Support/ProfilePayloads
            // ---------------------------------------------------------------------
            if let iconsFolderURL = applicationFolder(root: .applicationSupport, payloadType: payloadType, manifestType: .icons) {
                let iconURL = iconsFolderURL.appendingPathComponent(domainIdentifier + ".png")
                if FileManager.default.fileExists(atPath: iconURL.path) {
                    let icon = try Data(contentsOf: iconURL)
                    if icon.md5 == hash {
                        return true
                    }
                }
            }

            // ---------------------------------------------------------------------
            //  Read icon from from bundle
            // ---------------------------------------------------------------------
            if let iconsFolderURL = applicationFolder(root: .bundle, payloadType: payloadType, manifestType: .icons) {
                let iconURL = iconsFolderURL.appendingPathComponent(domainIdentifier + ".png")
                if FileManager.default.fileExists(atPath: iconURL.path) {
                    let icon = try Data(contentsOf: iconURL)
                    if icon.md5 == hash {
                        return true
                    }
                }
            }
        } catch {
            Swift.print("Failed to read data for icon...")
        }
        return false
    }

    internal func iconUpdatesAvailable(forDomainIdentifier domainIdentifier: String, ofType payloadType: PayloadType, domainIndex: [String: Any]) -> [String: Any]? {

        guard let indexHash = domainIndex["hash"] as? String else { return nil }

        if let payload = ProfilePayloads.shared.payload(forDomainIdentifier: domainIdentifier, type: payloadType) {
            if !self.iconExists(withHash: indexHash, forDomainIdentifier: domainIdentifier, payloadType: payloadType) {
                return self.addUpdate(domainIndex, toPayload: payload)
            }
        } else {
            if !self.iconExists(withHash: indexHash, forDomainIdentifier: domainIdentifier, payloadType: payloadType) {
                return domainIndex
            }
        }
        return nil
    }

    internal func addUpdate(_ domainIndex: [String: Any], toPayload payload: Payload) -> [String: Any] {
        payload.updateAvailable = true
        var updateIndex = payload.updateIndex ?? [String: Any]()
        updateIndex += domainIndex
        payload.updateIndex = updateIndex
        return domainIndex
    }

    internal func manifestUpdatesAvailable(forDomainIdentifier domainIdentifier: String, payloadType: PayloadType, domainIndex: [String: Any]) -> [String: Any]? {

        guard
            let indexVersion = domainIndex["version"] as? Int,
            let indexLastModified = domainIndex["modified"] as? Date else { return nil }

        if let payload = ProfilePayloads.shared.payload(forDomainIdentifier: domainIdentifier, type: payloadType) {

            // New version
            if payload.version < indexVersion || ( payload.version == indexVersion && payload.lastModified < indexLastModified ) {
                return self.addUpdate(domainIndex, toPayload: payload)
            }
        } else {
            // New domain
            return domainIndex
        }
        return nil
    }

    // MARK: -
    // MARK: Hashable

    public var hashValue: Int { return url.hashValue }

    static public func == (lhs: ManifestRepository, rhs: ManifestRepository) -> Bool {
        return lhs.url == rhs.url
    }
}
