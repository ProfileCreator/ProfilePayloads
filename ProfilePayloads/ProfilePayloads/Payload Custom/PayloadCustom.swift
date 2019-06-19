//
//  PayloadCustom.swift
//  ProfilePayloads
//
//  Created by Erik Berglund.
//  Copyright © 2017 Erik Berglund. All rights reserved.
//

import Cocoa

public class PayloadCustom: Payload {

    // MARK: -
    // MARK: Initialization

    init?(payloadContent: [[String: Any]], hash: String) {

        guard let firstPayloadContent = payloadContent.first else { return nil }

        let manifest = PayloadCustom.manifest(forPayloadContent: firstPayloadContent)

        super.init(manifest: manifest, manifestURL: nil, hash: hash, type: .custom)

        self.payloadContent = payloadContent

        if let icon = Bundle(for: ProfilePayloads.self).image(forResource: NSImage.Name("PlaceholderSquare")) {
            self.icon = icon
        }
    }

    public class func manifest(forPayloadContent payloadContent: [String: Any]) -> [String: Any] {

        var manifest = [String: Any]()
        var manifestSubkeys = [[String: Any]]()

        guard let payloadType = payloadContent[PayloadKey.payloadType] as? String else { return manifest }
        manifest[ManifestKey.domain.rawValue] = payloadType
        manifest[ManifestKey.title.rawValue] = payloadType
        manifest[ManifestKey.description.rawValue] = NSLocalizedString("\(payloadType) settings", comment: "")
        manifestSubkeys.append(self.manifestDict(forKey: .type, value: payloadType, type: .string))

        // Add Constants
        manifest[ManifestKey.formatVersion.rawValue] = 1
        manifest[ManifestKey.version.rawValue] = 1
        manifest[ManifestKey.unique.rawValue] = false
        manifest[ManifestKey.lastModified.rawValue] = Date()
        manifest[ManifestKey.platforms.rawValue] = PayloadUtility.strings(fromPlatforms: .all)
        manifest[ManifestKey.target.rawValue] = PayloadUtility.strings(fromTargets: .all)
        manifest[ManifestKey.distribution.rawValue] = PayloadUtility.strings(fromDistribution: .all)
        manifest[ManifestKey.supervised.rawValue] = false
        manifest[ManifestKey.userApproved.rawValue] = false
        manifest[ManifestKey.interaction.rawValue] = Interaction.undefined

        // Add Subkeys
        manifest[ManifestKey.subkeys.rawValue] = manifestSubkeys

        return manifest
    }

    public class func manifestDict(forKey key: ManifestKey, value: Any?, type: PayloadValueType) -> [String: Any] {
        var manifestDict = [String: Any]()
        manifestDict[ManifestKey.name.rawValue] = key.rawValue
        if let valueDefault = value {
            manifestDict[ManifestKey.valueDefault.rawValue] = valueDefault
        }
        manifestDict[ManifestKey.type.rawValue] = type.rawValue
        return manifestDict
    }

    override init?(manifest: [String: Any], manifestURL: URL?, hash: String, type: PayloadType) {
        fatalError("This class cannot be initialized with a manifest. use init?(payloadContent:hash:)")
        return nil
    }
}
