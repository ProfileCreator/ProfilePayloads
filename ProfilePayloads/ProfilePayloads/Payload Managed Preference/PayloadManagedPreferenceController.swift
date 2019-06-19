//
//  PayloadManagedPreferenceController.swift
//  ProfilePayloads
//
//  Created by Erik Berglund.
//  Copyright © 2017 Erik Berglund. All rights reserved.
//

import Foundation

class PayloadManagedPreferenceController {

    // MARK: -
    // MARK: Static Variables

    internal static let shared = PayloadManagedPreferenceController()

    // MARK: -
    // MARK: Internal Variables

    internal var conditionalTargets = [(keyPath: String, domainIdentifier: String)]()

    // MARK: -
    // MARK: Private Variables

    private var managedPreferencesSetApple = Set<PayloadManagedPreference>()
    private var managedPreferencesSetApplications = Set<PayloadManagedPreference>()
    private var managedPreferencesSetDeveloper = Set<PayloadManagedPreference>()

    // MARK: -
    // MARK: Initialization

    private init() {}

    // MARK: -
    // MARK: Update

    public func updateAll() {
        self.update(type: .managedPreferencesApple)
        self.update(type: .managedPreferencesApplications)
        self.update(type: .managedPreferencesDeveloper)
    }

    public func update(types: [PayloadType]) {
        for type in types {
            self.update(type: type)
        }
    }

    public func update(type: PayloadType) {
        switch type {
        case .all:
            self.update(type: .managedPreferencesApple)
            self.update(type: .managedPreferencesApplications)
            self.update(type: .managedPreferencesDeveloper)
        case .managedPreferencesApple:
            self.updateManagedPreferences(forType: type, managedPreferencesSet: &self.managedPreferencesSetApple)
        case .managedPreferencesApplications:
            self.updateManagedPreferences(forType: type, managedPreferencesSet: &self.managedPreferencesSetApplications)
        case .managedPreferencesDeveloper:
            self.updateManagedPreferences(forType: type, managedPreferencesSet: &self.managedPreferencesSetDeveloper)
        case .manifestsApple,
             .managedPreferencesApplicationsLocal,
             .custom:
            return
        }

        // ---------------------------------------------------------------------
        //  Loop through all conditional targets and update their isConditionalTarget bool
        // ---------------------------------------------------------------------
        for target in self.conditionalTargets {
            if let payloadSubkey = ProfilePayloads.shared.payloadSubkey(forKeyPath: target.keyPath, domainIdentifier: target.domainIdentifier, type: type) {
                payloadSubkey.isConditionalTarget = true
            }
            /*
             if let managedPreference = self.managedPreference(forDomain: target.domain, ofType: type) {
             if let payloadSubkey = ProfilePayloads.shared.payloadSubkey(keyPath: target.keyPath, parentKeyPath: nil, payloadSubkeys: managedPreference.subkeys) {
             payloadSubkey.isConditionalTarget = true
             }
             }
             */
        }
    }

    private func updateManagedPreferences(forType type: PayloadType, managedPreferencesSet: inout Set<PayloadManagedPreference>) {

        // ---------------------------------------------------------------------
        //  Reset manifests and conditional targets
        // ---------------------------------------------------------------------
        managedPreferencesSet = Set<PayloadManagedPreference>()
        self.conditionalTargets = [(keyPath: String, domainIdentifier: String)]()

        // ---------------------------------------------------------------------
        //  Add manifests from /Library/Application Support/ProfilePayloads
        // ---------------------------------------------------------------------
        if let libraryApplicationsFolderURL = applicationFolder(root: .applicationSupport, payloadType: type, manifestType: .manifests) {
            self.addManagedPreferences(fromFolder: libraryApplicationsFolderURL,
                                       type: type,
                                       toManagedPreferences: &managedPreferencesSet)
        }

        // ---------------------------------------------------------------------
        //  Add manifests from bundle
        // ---------------------------------------------------------------------
        if let bundleFolderURL = applicationFolder(root: .bundle, payloadType: type, manifestType: .manifests) {
            self.addManagedPreferences(fromFolder: bundleFolderURL,
                                       type: type,
                                       toManagedPreferences: &managedPreferencesSet)
        }
    }

    private func addManagedPreferences(fromFolder folder: URL,
                                       type: PayloadType,
                                       toManagedPreferences managedPreferencesSet: inout Set<PayloadManagedPreference>) {

        // ---------------------------------------------------------------------
        //  Get contents of manifest directory
        // ---------------------------------------------------------------------
        var managedPreferencesURLs = [URL]()
        do {
            managedPreferencesURLs = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        } catch {
            // FIXME: Proper Logging
            print("Class: \(self.self), Function: \(#function), Error: \(error)")
            return
        }

        // ---------------------------------------------------------------------
        //  Remove all items that doesn't have the "plist" file extension
        // ---------------------------------------------------------------------
        managedPreferencesURLs = managedPreferencesURLs.filter { $0.pathExtension == "plist" }

        // ---------------------------------------------------------------------
        //  Loop through all application files and add them to the internal store
        // ---------------------------------------------------------------------
        for managedPreferenceURL in managedPreferencesURLs {
            if let managedPreference = PayloadManagedPreference(url: managedPreferenceURL, type: type) {

                // ---------------------------------------------------------------------
                //  Ignore manifests with a higher format version than currently supported
                // ---------------------------------------------------------------------
                if kFormatVersionSupported < managedPreference.formatVersion { continue }

                // ---------------------------------------------------------------------
                //  Only keep the latest version of a managed preference
                // ---------------------------------------------------------------------
                if let existingManagedPreference = managedPreferencesSet.first(where: { $0.domainIdentifier == managedPreference.domainIdentifier }) {
                    if existingManagedPreference.version < managedPreference.version || ( existingManagedPreference.version == managedPreference.version && existingManagedPreference.lastModified < managedPreference.lastModified ) {
                        managedPreferencesSet.remove(existingManagedPreference)
                    } else {
                        // FIXME: Proper Logging
                        Swift.print("A newer version of payload source for domain: \(managedPreference.domain) already exists.")
                        continue
                    }
                }

                // ---------------------------------------------------------------------
                //  Initialze the managed preference and add it to the internal store
                // ---------------------------------------------------------------------
                managedPreference.initializeComputedVariables()
                managedPreferencesSet.insert(managedPreference)
            }
        }
    }

    // MARK: -
    // MARK: Managed Preference

    internal func managedPreference(forDomainIdentifier domainIdentifier: String, ofType type: PayloadType) -> PayloadManagedPreference? {
        switch type {
        case .managedPreferencesApple:
            return self.managedPreferencesSetApple.first { $0.domainIdentifier == domainIdentifier }
        case .managedPreferencesApplications:
            return self.managedPreferencesSetApplications.first { $0.domainIdentifier == domainIdentifier }
        case .managedPreferencesDeveloper:
            return self.managedPreferencesSetDeveloper.first { $0.domainIdentifier == domainIdentifier }
        default:
            return nil
        }
    }

    // MARK: -
    // MARK: Managed Preferences

    internal func managedPreferences(forType type: PayloadType) -> [PayloadManagedPreference]? {
        switch type {
        case .managedPreferencesApple:
            return Array(self.managedPreferencesSetApple)
        case .managedPreferencesApplications:
            return Array(self.managedPreferencesSetApplications)
        case .managedPreferencesDeveloper:
            return Array(self.managedPreferencesSetDeveloper)
        default:
            return nil
        }
    }

    internal func managedPreferences(forDomain domain: String, ofType type: PayloadType) -> [PayloadManagedPreference]? {
        switch type {
        case .managedPreferencesApple:
            return Array(self.managedPreferencesSetApple.filter { $0.domain == domain })
        case .managedPreferencesApplications:
            return Array(self.managedPreferencesSetApplications.filter { $0.domain == domain })
        case .managedPreferencesDeveloper:
            return Array(self.managedPreferencesSetDeveloper.filter { $0.domain == domain })
        default:
            return nil
        }
    }

    // MARK: -
    // MARK: Managed Preference Placeholders

    internal func managedPreferencePlaceholders(forType type: PayloadType) -> [PayloadPlaceholder]? {
        switch type {
        case .managedPreferencesApple:
            return self.managedPreferencesSetApple.compactMap { $0.placeholder }
        case .managedPreferencesApplications:
            return self.managedPreferencesSetApplications.compactMap { $0.placeholder }
        case .managedPreferencesDeveloper:
            return self.managedPreferencesSetDeveloper.compactMap { $0.placeholder }
        case .all,
             .manifestsApple,
             .managedPreferencesApplicationsLocal,
             .custom:
            return nil
        }
    }
}
