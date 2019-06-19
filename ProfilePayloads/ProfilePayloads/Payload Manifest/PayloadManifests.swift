//
//  PayloadManifestController.swift
//  ProfilePayloads
//
//  Created by Erik Berglund.
//  Copyright © 2017 Erik Berglund. All rights reserved.
//

import Foundation

// FIXME: This class name is misleading, both this AND PayloadManagedPreferenceController are manifests. ManagedPreferences is logical, just don't know what to call the Apple-defined payloads.
class PayloadManifestController {

    // MARK: -
    // MARK: Static Variables

    internal static let shared = PayloadManifestController()

    // MARK: -
    // MARK: Internal Variables

    internal var conditionalTargets = [(keyPath: String, domainIdentifier: String)]()

    // MARK: -
    // MARK: Private Variables

    private var manifestsSetApple = Set<PayloadManifest>()

    // MARK: -
    // MARK: Initialization

    private init() {}

    // MARK: -
    // MARK: Update

    public func updateAll() {
        self.update(type: .manifestsApple)
    }

    public func update(types: [PayloadType]) {
        for type in types {
            self.update(type: type)
        }
    }

    public func update(type: PayloadType) {
        switch type {
        case .managedPreferencesApple,
             .managedPreferencesApplications,
             .managedPreferencesApplicationsLocal,
             .managedPreferencesDeveloper,
             .custom:
            return
        case .all,
             .manifestsApple:
            self.updateManifests(forType: type, manifestSet: &self.manifestsSetApple)
        }

        // ---------------------------------------------------------------------
        //  Loop through all conditional targets and update their isConditionalTarget bool
        // ---------------------------------------------------------------------
        for target in self.conditionalTargets {
            if let payloadSubkey = ProfilePayloads.shared.payloadSubkey(forKeyPath: target.keyPath, domainIdentifier: target.domainIdentifier, type: type) {
                payloadSubkey.isConditionalTarget = true
            }
        }
    }

    private func updateManifests(forType type: PayloadType, manifestSet: inout Set<PayloadManifest>) {

        // ---------------------------------------------------------------------
        //  Reset manifests and conditional targets
        // ---------------------------------------------------------------------
        manifestSet = Set<PayloadManifest>()
        self.conditionalTargets = [(keyPath: String, domainIdentifier: String)]()

        // ---------------------------------------------------------------------
        //  Add manifests from /Library/Application Support/ProfilePayloads
        // ---------------------------------------------------------------------
        if let libraryApplicationsFolderURL = applicationFolder(root: .applicationSupport, payloadType: type, manifestType: .manifests) {
            self.addManagedPreferences(fromFolder: libraryApplicationsFolderURL,
                                       type: type,
                                       toManifests: &manifestSet)
        }

        // ---------------------------------------------------------------------
        //  Add manifests from bundle
        // ---------------------------------------------------------------------
        if let bundleFolderURL = applicationFolder(root: .bundle, payloadType: type, manifestType: .manifests) {
            self.addManagedPreferences(fromFolder: bundleFolderURL,
                                       type: type,
                                       toManifests: &manifestSet)
        }

    }

    private func addManagedPreferences(fromFolder folder: URL,
                                       type: PayloadType,
                                       toManifests manifestSet: inout Set<PayloadManifest>) {

        // ---------------------------------------------------------------------
        //  Get contents of manifest directory
        // ---------------------------------------------------------------------
        var manifestURLs = [URL]()
        do {
            manifestURLs = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        } catch {
            // FIXME: Proper Logging
            print("Class: \(self.self), Function: \(#function), Error: \(error)")
            return
        }

        // ---------------------------------------------------------------------
        //  Remove all items that doesn't have the "plist" file extension
        // ---------------------------------------------------------------------
        manifestURLs = manifestURLs.filter { $0.pathExtension == "plist" }

        // ---------------------------------------------------------------------
        //  Loop through all application files and add them to the internal store
        // ---------------------------------------------------------------------
        for manifestURL in manifestURLs {
            if let manifest = PayloadManifest(url: manifestURL, type: type) {

                // ---------------------------------------------------------------------
                //  Ignore manifests with a higher format version than currently supported
                // ---------------------------------------------------------------------
                if kFormatVersionSupported < manifest.formatVersion { continue }

                // ---------------------------------------------------------------------
                //  Only keep the latest version of a managed preference
                // ---------------------------------------------------------------------
                if let existingManifest = manifestSet.first(where: { $0.domainIdentifier == manifest.domainIdentifier }) {
                    if existingManifest.version < manifest.version || ( existingManifest.version == manifest.version && existingManifest.lastModified < manifest.lastModified ) {
                        manifestSet.remove(existingManifest)
                    } else {
                        // FIXME: Proper Logging
                        // Swift.print("A newer version of payload source for identifier: \(manifest.domainIdentifier) already exists.")
                        continue
                    }
                }

                // ---------------------------------------------------------------------
                //  Initialze the managed preference and add it to the internal store
                // ---------------------------------------------------------------------
                manifest.initializeComputedVariables()
                manifestSet.insert(manifest)

                // ---------------------------------------------------------------------
                //  Initialze any override as it's own manifest
                // ---------------------------------------------------------------------
                if manifest.hasOverride, !manifest.manifestOverrideDict.isEmpty {
                    guard
                        let overrideURL = PayloadOverrides.overrideManifestURL(forDomain: manifest.domain, paylaodType: manifest.type),
                        let overrideData = try? Data(contentsOf: overrideURL) else {
                            continue
                    }

                    let override = PayloadManifest(manifest: PayloadOverrides.addOverrides(forDomain: manifest.domain, payloadType: manifest.type, sourceManifest: manifest.manifestOverrideDict),
                                                   manifestURL: manifestURL,
                                                   hash: overrideData.md5,
                                                   type: manifest.type)
                    manifest.override = override
                }
            }
        }
    }

    // MARK: -
    // MARK: Manifest

    func manifest(forDomainIdentifier domainIdentifier: String, ofType type: PayloadType) -> PayloadManifest? {
        if type == .manifestsApple {
            return self.manifestsSetApple.first { $0.domainIdentifier == domainIdentifier }
        }
        return nil
    }

    // MARK: -
    // MARK: Manifests

    internal func manifests(forType type: PayloadType) -> [PayloadManifest]? {
        if type == .manifestsApple {
            return Array(self.manifestsSetApple)
        }
        return nil
    }

    func manifests(forDomain domain: String, ofType type: PayloadType) -> [PayloadManifest]? {
        if type == .manifestsApple {
            return Array(self.manifestsSetApple.filter { $0.domain == domain })
        }
        return nil
    }

    // MARK: -
    // MARK: Manifest Placeholders

    func manifestPlacehoders(forType type: PayloadType) -> [PayloadPlaceholder]? {
        if type == .manifestsApple {
            return self.manifestsSetApple.compactMap { $0.placeholder }
        }
        return nil
    }
}
