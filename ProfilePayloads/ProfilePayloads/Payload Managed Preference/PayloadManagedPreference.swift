//
//  PayloadManagedPreference.swift
//  ProfilePayloads
//
//  Created by Erik Berglund.
//  Copyright © 2017 Erik Berglund. All rights reserved.
//

import Cocoa

public class PayloadManagedPreference: Payload {

    // MARK: -
    // MARK: Variables

    public var appDocumentationURL: URL?
    public var appURL: URL?
    public var appVersions: [String]?

    // MARK: -
    // MARK: Initialization

    override init?(manifest: [String: Any], manifestURL: URL?, hash: String, type: PayloadType) {
        super.init(manifest: manifest, manifestURL: manifestURL, hash: hash, type: type)

        // Subkeys
        if let applicationSubkeys = self.manifestDict[ManifestKey.subkeys.rawValue] as? [[String: Any]] {
            for applicationSubkey in applicationSubkeys {
                if let subkey = PayloadManagedPreferenceSubkey(managedPreference: self, parentSubkey: nil, subkey: applicationSubkey) {
                    self.subkeys.append(subkey)
                }
            }
        }
        if self.subkeys.isEmpty { return nil }
        self.allSubkeys.append(contentsOf: self.subkeys)
        self.verifyPayloadSubkeys()

        // ---------------------------------------------------------------------
        //  Initialize optional variables
        // ---------------------------------------------------------------------
        if
            let iconData = self.manifestDict[ManifestKey.icon.rawValue] as? Data,
            let icon = NSImage(data: iconData) {

            self.icon = icon
        } else if let icon = ProfilePayloads.shared.icon(forDomainIdentifier: self.domainIdentifier, domain: self.domain, type: type) {
            self.icon = icon
        } else if let icon = Bundle(for: ProfilePayloads.self).image(forResource: NSImage.Name("PlaceholderSquare")) {
            self.icon = icon
        }

        // App Documentation URL
        if
            let appDocumentationURLString = self.manifestDict[ManifestKey.documentationURL.rawValue] as? String,
            let appDocumentationURL = URL(string: appDocumentationURLString) {
            self.appDocumentationURL = appDocumentationURL
        }

        // App URL
        if
            let appURLString = self.manifestDict[ManifestKey.appURL.rawValue] as? String,
            let appURL = URL(string: appURLString) {
            self.appURL = appURL
        }

        // App Versions
        if let appVersions = self.appVersions {
            self.appVersions = Array(Set(appVersions)).sorted()
        }
    }

    func add(appVersion: String) {
        if appVersions == nil {
            self.appVersions = [appVersion]
        } else {
            self.appVersions?.append(appVersion)
        }
    }
}
