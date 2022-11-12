//
//  ProfilePayloads.swift
//  ProfilePayloads
//
//  Created by Erik Berglund.
//  Copyright © 2017 Erik Berglund. All rights reserved.
//

import Foundation

public class ProfilePayloads {

    // ---------------------------------------------------------------------
    //  Variables
    // ---------------------------------------------------------------------
    public static let shared = ProfilePayloads()
    public static let platformsSupervised: Platforms = [.iOS, .tvOS, .macOS]
    public static let platformsUserApproved: Platforms = [.macOS]
    public static let rangeListConvertMax = 40

    public var currentPayloadTypes = [PayloadType]()

    // ---------------------------------------------------------------------
    //  Initialization
    // ---------------------------------------------------------------------
    private init() {}

    public func initializePayloads(ofType payloadTypes: [PayloadType]) {
        self.currentPayloadTypes = payloadTypes
        self.updateManifests(ofType: payloadTypes)
        ManifestRepositories.shared.configure(addRepository: URL(string: kURLGitHubRepositoryProfileManifests)!)
    }

    public func updateManifests() {
        self.updateManifests(ofType: currentPayloadTypes)
    }

    public func updateManifests(ofType payloadTypes: [PayloadType]) {
        PayloadManifestController.shared.update(types: payloadTypes)
        PayloadManagedPreferenceController.shared.update(types: payloadTypes)
        PayloadManagedPreferenceLocalController.shared.update(types: payloadTypes)
    }

    // ---------------------------------------------------------------------
    //  Payload Icon Functions
    // ---------------------------------------------------------------------
    public func icon(forDomainIdentifier domainIdentifier: String, domain: String, type: PayloadType) -> NSImage? {
        self.icon(forDomainIdentifier: domainIdentifier, type: type) ?? self.icon(forDomainIdentifier: domain, type: type)
    }

    internal func icon(forDomainIdentifier domainIdentifier: String, type: PayloadType) -> NSImage? {

        // ---------------------------------------------------------------------
        //  Read icon from /Library/Application Support/ProfilePayloads
        // ---------------------------------------------------------------------
        if let iconsFolderURL = applicationFolder(root: .applicationSupport, payloadType: type, manifestType: .icons) {
            if let icon = NSImage(contentsOf: iconsFolderURL.appendingPathComponent(domainIdentifier + ".png")) {
                return icon
            }
        }

        // ---------------------------------------------------------------------
        //  Read icon from from bundle
        // ---------------------------------------------------------------------
        if let iconsFolderURL = applicationFolder(root: .bundle, payloadType: type, manifestType: .icons) {
            if let icon = NSImage(contentsOf: iconsFolderURL.appendingPathComponent(domainIdentifier + ".png")) {
                return icon
            }
        }

        if let applicationPath = NSWorkspace.shared.absolutePathForApplication(withBundleIdentifier: domainIdentifier) {
            return NSWorkspace.shared.icon(forFile: applicationPath)
        }

        return nil
    }

    // ---------------------------------------------------------------------
    //  Payload Source Functions
    // ---------------------------------------------------------------------
    public func payload(forDomainIdentifier domainIdentifier: String, type: PayloadType, payloadContent content: [[String: Any]]? = nil) -> Payload? {
        switch type {
        case .manifestsApple:
            return self.appleManifest(forDomainIdentifier: domainIdentifier, ofType: type)
        case .managedPreferencesApple,
             .managedPreferencesApplications,
             .managedPreferencesDeveloper:
            return self.managedPreference(forDomainIdentifier: domainIdentifier, ofType: type)
        case .managedPreferencesApplicationsLocal:
            return self.managedPreferenceLocal(forDomainIdentifier: domainIdentifier, ofType: type)
        case .custom:
            guard let payloadContent = content else { return nil }
            return self.customManifest(forDomainIdentifier: domainIdentifier, ofType: type, payloadContent: payloadContent)
        case .all:
            Swift.print("Unhandled payload type: \(type)")
            return nil
        }
    }

    public func payloads(forDomain domain: String, type: PayloadType, payloadContent content: [[String: Any]]? = nil) -> [Payload]? {
        switch type {
        case .manifestsApple:
            return self.appleManifests(forDomain: domain, ofType: type)
        case .managedPreferencesApple,
             .managedPreferencesApplications,
             .managedPreferencesDeveloper:
            return self.managedPreferences(forDomain: domain, ofType: type)
        case .managedPreferencesApplicationsLocal:
            return self.managedPreferencesLocal(forDomain: domain, ofType: type)
        case .custom:
            guard
                let payloadContent = content,
                let customManifest = self.customManifest(forDomainIdentifier: domain, ofType: type, payloadContent: payloadContent) else { return nil }
            return [customManifest]
        case .all:
            Swift.print("Unhandled payload type: \(type)")
            return nil
        }
    }

    // ---------------------------------------------------------------------
    //  Payload Placeholder Functions
    // ---------------------------------------------------------------------
    public func payloadPlaceholders(type: PayloadType, typeSettings settings: [String: [[String: Any]]]? = nil) -> [PayloadPlaceholder]? {
        switch type {
        case .manifestsApple:
            return self.appleManifestPlaceholders(forType: type)
        case .managedPreferencesApple,
             .managedPreferencesApplications,
             .managedPreferencesDeveloper:

            return self.managedPreferencePlaceholders(forType: type)
        case .managedPreferencesApplicationsLocal:
            return self.managedPreferenceLocalPlaceholders(forType: type)
        case .custom:
            guard let typeSettings = settings else { return nil }
            return self.customManifestPlaceholders(forType: type, typeSettings: typeSettings)
        case .all:
            Swift.print("Unhandled payload type: \(type)")
            return nil
        }
    }

    // ---------------------------------------------------------------------
    //  Payload Subkey Functions
    // ---------------------------------------------------------------------
    public func payloadSubkey(forKeyPath keyPath: String, domainIdentifier: String, type: PayloadType) -> PayloadSubkey? {
        self.payload(forDomainIdentifier: domainIdentifier, type: type)?.allSubkeys.first { $0.keyPath == keyPath }
    }

    public func payloadSubkey(forKeyPath keyPath: String, domain: String, type: PayloadType) -> PayloadSubkey? {
        guard let payloads = self.payloads(forDomain: domain, type: type) else { return nil }
        return payloads.flatMap { $0.allSubkeys }.first { $0.keyPath == keyPath }
    }

    public func payloadSubkeys(forKeyPath keyPath: String, domain: String, type: PayloadType) -> [PayloadSubkey]? {
        guard let payloads = self.payloads(forDomain: domain, type: type) else { return nil }
        return payloads.flatMap { $0.allSubkeys }.filter { $0.keyPath == keyPath }
    }

    // ---------------------------------------------------------------------
    //  Apple Manifest Payload Functions
    // ---------------------------------------------------------------------
    public func appleManifests(forType type: PayloadType) -> [PayloadManifest]? {
        PayloadManifestController.shared.manifests(forType: type)
    }

    public func appleManifest(forDomainIdentifier domainIdentifier: String, ofType type: PayloadType) -> PayloadManifest? {
        /*
        if domainIdentifier == kManifestDomainAppleRoot || domainIdentifier == kManifestDomainApplePEM {
            return PayloadManifestController.shared.manifest(forDomainIdentifier: kManifestDomainApplePKCS1, ofType: type)
        }
        */
        return PayloadManifestController.shared.manifest(forDomainIdentifier: domainIdentifier, ofType: type)
    }

    public func appleManifests(forDomain domain: String, ofType type: PayloadType) -> [PayloadManifest]? {
        /*
        if domain == kManifestDomainAppleRoot || domain == kManifestDomainApplePEM {
            return PayloadManifestController.shared.manifests(forDomain: kManifestDomainApplePKCS1, ofType: type)
        }
        */
        return PayloadManifestController.shared.manifests(forDomain: domain, ofType: type)
    }

    public func appleManifestPlaceholders(forType type: PayloadType) -> [PayloadPlaceholder]? {
        PayloadManifestController.shared.manifestPlacehoders(forType: type)
    }

    // ---------------------------------------------------------------------
    //  Managed Preferences Functions
    // ---------------------------------------------------------------------
    public func managedPreferences(forType type: PayloadType) -> [PayloadManagedPreference]? {
        PayloadManagedPreferenceController.shared.managedPreferences(forType: type)
    }

    public func managedPreference(forDomainIdentifier domainIdentifier: String, ofType type: PayloadType) -> PayloadManagedPreference? {
        PayloadManagedPreferenceController.shared.managedPreference(forDomainIdentifier: domainIdentifier, ofType: type)
    }

    public func managedPreferences(forDomain domain: String, ofType type: PayloadType) -> [PayloadManagedPreference]? {
        PayloadManagedPreferenceController.shared.managedPreferences(forDomain: domain, ofType: type)
    }

    public func managedPreferencePlaceholders(forType type: PayloadType) -> [PayloadPlaceholder]? {
        PayloadManagedPreferenceController.shared.managedPreferencePlaceholders(forType: type)
    }

    // ---------------------------------------------------------------------
    //  Managed Preferences Local Functions
    // ---------------------------------------------------------------------
    public func managedPreferencesLocal(forType type: PayloadType) -> [PayloadManagedPreferenceLocal]? {
        PayloadManagedPreferenceLocalController.shared.managedPreferences(forType: type)
    }

    public func managedPreferenceLocal(forDomainIdentifier domainIdentifier: String, ofType type: PayloadType) -> PayloadManagedPreferenceLocal? {
        PayloadManagedPreferenceLocalController.shared.managedPreference(forDomainIdentifier: domainIdentifier, ofType: type)
    }

    public func managedPreferencesLocal(forDomain domain: String, ofType type: PayloadType) -> [PayloadManagedPreferenceLocal]? {
        PayloadManagedPreferenceLocalController.shared.managedPreferences(forDomain: domain, ofType: type)
    }

    public func managedPreferenceLocalPlaceholders(forType type: PayloadType) -> [PayloadPlaceholder]? {
        PayloadManagedPreferenceLocalController.shared.managedPreferencePlaceholders(forType: type)
    }

    // ---------------------------------------------------------------------
    //  Custom Payload Functions
    // ---------------------------------------------------------------------
    public func customManifests(forType type: PayloadType, typeSettings: [String: [[String: Any]]]) -> [PayloadCustom]? {
        PayloadCustomController.shared.customManifests(forType: type, typeSettings: typeSettings)
    }

    public func customManifest(forDomainIdentifier domainIdentifier: String, ofType type: PayloadType, payloadContent: [[String: Any]]) -> PayloadCustom? {
        PayloadCustomController.shared.customManifest(forDomainIdentifier: domainIdentifier, ofType: type, payloadContent: payloadContent)
    }

    public func customManifestPlaceholders(forType type: PayloadType, typeSettings: [String: [[String: Any]]]) -> [PayloadPlaceholder]? {
        PayloadCustomController.shared.customManifestPlaceholders(forType: type, typeSettings: typeSettings)
    }

    // ---------------------------------------------------------------------
    //  Payload Types
    // ---------------------------------------------------------------------
    public func payloadTypes(forDomain domain: String) -> [PayloadType]? {
        var types = [PayloadType]()

        // Manifests
        if appleManifest(forDomainIdentifier: domain, ofType: .manifestsApple) != nil {
            types.append(.manifestsApple)
        }

        // Managed Preferences
        for type in [.managedPreferencesApple, .managedPreferencesApplications, .managedPreferencesApplicationsLocal] as [PayloadType] {
            if managedPreference(forDomainIdentifier: domain, ofType: type) != nil {
                types.append(type)
            }
        }

        return types.isEmpty ? nil : types
    }
}
