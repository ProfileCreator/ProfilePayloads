//
//  PayloadManagedPreferenceLocalController.swift
//  ProfilePayloads
//
//  Created by Erik Berglund.
//  Copyright © 2017 Erik Berglund. All rights reserved.
//

import Foundation

class PayloadManagedPreferenceLocalController {

    // MARK: -
    // MARK: Static Variables

    internal static let shared = PayloadManagedPreferenceLocalController()

    // MARK: -
    // MARK: Private Variables

    private var managedPreferencesSetApplicationsLocal = Set<PayloadManagedPreferenceLocal>()

    private var domains = Set<String>()
    private var libraryPreferencesURLs = [URL]()
    private var libraryPreferencesUserURLs = [URL]()
    private var libraryPreferencesUserByHostURLs = [URL]()
    private var libraryPreferencesUserSyncedURLs = [URL]()

    // MARK: -
    // MARK: Initialization

    private init() {}

    // MARK: -
    // MARK: Update

    public func updateAll() {
        self.update(type: .managedPreferencesApplicationsLocal)
    }

    public func update(types: [PayloadType]) {
        for type in types {
            self.update(type: type)
        }
    }

    public func update(type: PayloadType) {
        switch type {
        case .all:
            self.update(type: .managedPreferencesApplicationsLocal)
        case .managedPreferencesApplicationsLocal:
            self.updateManagedPreferencesLocal(forType: type,
                                               managedPreferencesSet: &self.managedPreferencesSetApplicationsLocal)
        case .manifestsApple,
             .managedPreferencesApple,
             .managedPreferencesApplications,
             .managedPreferencesDeveloper,
             .custom:
            return
        }
    }

    private func updateManagedPreferencesLocal(forType type: PayloadType,
                                               managedPreferencesSet: inout Set<PayloadManagedPreferenceLocal>) {

        // ---------------------------------------------------------------------
        //  Reset manifests and domains
        // ---------------------------------------------------------------------
        self.domains = Set<String>()
        managedPreferencesSet = Set<PayloadManagedPreferenceLocal>()

        // ---------------------------------------------------------------------
        //  Add domains from the 4 major preference domains
        // ---------------------------------------------------------------------
        // FIXME: This method only searches plist-file names. There might be more or better methods to find all current preference domains.

        self.libraryPreferencesURLs = self.preferenceDomains(at: URL(fileURLWithPath: "/Library/Preferences"))
        self.libraryPreferencesUserURLs = self.preferenceDomains(at: URL(fileURLWithPath: NSHomeDirectory() + "/Library/Preferences"))
        self.libraryPreferencesUserByHostURLs = self.preferenceDomains(at: URL(fileURLWithPath: NSHomeDirectory() + "/Library/Preferences/ByHost"))
        //self.libraryPreferencesUserSyncedURLs = self.preferenceDomains(at: URL(fileURLWithPath: NSHomeDirectory() + "/Library/SyncedPreferences"))

        // FIXME: Should get the parent bundles identifier and not hardcode
        self.addManagedPreferencesLocal(forDomains: self.domains.filter { $0 != "com.github.erikberglund.ProfileCreator" },
                                        toManagedPreferences: &managedPreferencesSet)
    }

    private func preferenceDomains(at url: URL) -> [URL] {
        let preferenceDomains = FileManager.default.contentsOfDirectory(at: url,
                                                                        withExtension: "plist",
                                                                        includingPropertiesForKeys: nil,
                                                                        options: [.skipsSubdirectoryDescendants]) ?? [URL]()
        if url.lastPathComponent == "ByHost" {
            self.domains.formUnion(preferenceDomains.map { $0.deletingPathExtension().deletingPathExtension().lastPathComponent })
        } else {
            self.domains.formUnion(preferenceDomains.map { $0.deletingPathExtension().lastPathComponent })
        }
        return preferenceDomains
    }

    private func addManagedPreferencesLocal(forDomains domains: Set<String>, toManagedPreferences managedPreferencesSet: inout Set<PayloadManagedPreferenceLocal>) {

        // ---------------------------------------------------------------------
        //  Loop through all application files and add them to the internal store
        // ---------------------------------------------------------------------
        for domain in domains {
            if let managedPreference = PayloadManagedPreferenceLocal(domain: domain, hash: "1") {
                managedPreferencesSet.insert(managedPreference)
            }
        }
    }

    // MARK: -
    // MARK: Managed Preference

    internal func managedPreference(forDomainIdentifier domainIdentifier: String, ofType type: PayloadType) -> PayloadManagedPreferenceLocal? {
        if type == .managedPreferencesApplicationsLocal {
            return self.managedPreferencesSetApplicationsLocal.first { $0.domainIdentifier == domainIdentifier }
        }
        return nil
    }

    // MARK: -
    // MARK: Managed Preferences

    internal func managedPreferences(forType type: PayloadType) -> [PayloadManagedPreferenceLocal]? {
        if type == .managedPreferencesApplicationsLocal {
            return Array(self.managedPreferencesSetApplicationsLocal)
        }
        return nil
    }

    internal func managedPreferences(forDomain domain: String, ofType type: PayloadType) -> [PayloadManagedPreferenceLocal]? {
        if type == .managedPreferencesApplicationsLocal {
            return Array(self.managedPreferencesSetApplicationsLocal.filter { $0.domain == domain })
        }
        return nil
    }

    // MARK: -
    // MARK: Managed Preference Placeholders

    internal func managedPreferencePlaceholders(forType type: PayloadType) -> [PayloadPlaceholder]? {
        if type == .managedPreferencesApplicationsLocal {
            return self.managedPreferencesSetApplicationsLocal.compactMap { $0.placeholder }
        }
        return nil
    }
}
