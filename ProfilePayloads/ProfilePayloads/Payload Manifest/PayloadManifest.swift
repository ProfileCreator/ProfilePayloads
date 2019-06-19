//
//  Manifest.swift
//  ProfilePayloads
//
//  Created by Erik Berglund.
//  Copyright © 2017 Erik Berglund. All rights reserved.
//

import Cocoa

let kSubkeyPayloadScope: [String: Any] = [ManifestKey.name.rawValue: PayloadKey.payloadScope,
                                          ManifestKey.title.rawValue: "Payload Scope",
                                          ManifestKey.enabled.rawValue: true,
                                          ManifestKey.valueDefault.rawValue: "User",
                                          ManifestKey.rangeList.rawValue: ["User", "System"],
                                          ManifestKey.description.rawValue: "Scope of the Profile. (This choice might change when exporting if a payload is unavailable in the selected scope).",
                                          ManifestKey.type.rawValue: "string"]

public class PayloadManifest: Payload {

    // MARK: -
    // MARK: Initialization

    override init?(manifest: [String: Any], manifestURL: URL?, hash: String, type: PayloadType) {
        super.init(manifest: manifest, manifestURL: manifestURL, hash: hash, type: type)

        if
            let iconData = self.manifestDict[ManifestKey.icon.rawValue] as? Data,
            let icon = NSImage(data: iconData) {

            self.icon = icon
        } else if let icon = ProfilePayloads.shared.icon(forDomainIdentifier: self.domainIdentifier, domain: self.domain, type: type) {
            self.icon = icon
        } else if let icon = Bundle(for: ProfilePayloads.self).image(forResource: NSImage.Name("PlaceholderSquare")) {
            self.icon = icon
        }

        // Subkeys
        if let manifestSubkeys = self.manifestDict[ManifestKey.subkeys.rawValue] as? [[String: Any]] {
            for manifestSubkey in manifestSubkeys {
                if let subkey = PayloadManifestSubkey(manifest: self, parentSubkey: nil, subkey: manifestSubkey) {
                    self.subkeys.append(subkey)
                    self.allSubkeys.append(subkey)
                    self.allSubkeys.append(contentsOf: subkey.allSubkeys)
                }
            }
        }
        if self.subkeys.isEmpty { return nil }

        if self.domain == kManifestDomainConfiguration {
            self.verifyProfileSubkeys()
        } else {
            self.verifyPayloadSubkeys()
        }
    }
}
