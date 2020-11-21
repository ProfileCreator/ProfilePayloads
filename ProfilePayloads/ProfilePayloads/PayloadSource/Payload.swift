//
//  Payload.swift
//  ProfilePayloads
//
//  Created by Erik Berglund.
//  Copyright © 2017 Erik Berglund. All rights reserved.
//

import Cocoa

public class Payload: Hashable {

    // MARK: -
    // MARK: Required Variables

    public let description: String
    public let manifestDict: [String: Any]
    public let manifestOverrideDict: [String: Any]
    public let manifestURL: URL?
    public let distribution: Distribution
    public let domain: String
    public let domainIdentifier: String
    public var subdomain: String?
    public let interaction: Interaction
    public let supervised: Bool
    public let userApproved: Bool
    public let platforms: Platforms
    public let targets: Targets
    public let title: String
    public let type: PayloadType

    public var unique: Bool
    public var formatVersion: Int
    public var version: Int
    public var hash: String
    public var lastModified: Date
    public var override: Payload?

    // Used for custom payloads only
    public var payloadContent: [[String: Any]]?

    // MARK: -
    // MARK: Variables

    public var macOSMax: String?
    public var macOSMin: String?
    public var iOSMax: String?
    public var iOSMin: String?
    public var tvOSMax: String?
    public var tvOSMin: String?

    public var documentationURL: URL?
    public var note: String?
    public var substitutionVariables: [String: [String: String]]?

    public var icon: NSImage?

    public var allSubkeys = [PayloadSubkey]()
    public var allOverrideSubkeys = [PayloadSubkey]()

    public var subkeys = [PayloadSubkey]()
    public var overrideSubkeys = [PayloadSubkey]()

    public var payloadContentSubkeys = [PayloadSubkey]()

    public var updateAvailable: Bool = false
    public var updateIndex: [String: Any]?

    public var hasOverride: Bool = false

    // MARK: -
    // MARK: Lazy Variables

    public lazy var placeholder: PayloadPlaceholder? = { PayloadPlaceholder(payload: self) }()

    // MARK: -
    // MARK: Initialization

    convenience init?(url: URL, type: PayloadType) {
        guard
            let manifestData = try? Data(contentsOf: url),
            let manifest = manifest(fromData: manifestData) else {
                Swift.print("Failed to read manifest from at path: \(url)")
                return nil
        }
        self.init(manifest: manifest, manifestURL: url, hash: manifestData.md5, type: type)
    }

    init?(manifest: [String: Any], manifestURL: URL?, hash: String, type: PayloadType) {

        // ---------------------------------------------------------------------
        //  Store the passed manifest dict
        // ---------------------------------------------------------------------
        self.hash = hash
        self.type = type
        self.manifestDict = manifest
        self.manifestURL = manifestURL

        // Domain
        guard let domain = manifest[ManifestKey.domain.rawValue] as? String else { return nil }
        self.domain = domain

        // Subdomain + Identifier
        if let subdomain = manifest[ManifestKey.subdomain.rawValue] as? String {
            self.subdomain = subdomain
            self.domainIdentifier = domain + "-" + subdomain
        } else {
            self.domainIdentifier = domain
        }

        // Overrides
        let overrideManifest = PayloadOverrides.addOverrides(forDomain: self.domain, payloadType: type, sourceManifest: manifest)
        self.manifestOverrideDict = overrideManifest
        self.hasOverride = manifest != overrideManifest

        // ---------------------------------------------------------------------
        //  Initialize required variables
        // ---------------------------------------------------------------------
        // Title
        if let title = manifest[ManifestKey.title.rawValue] as? String { self.title = title } else { return nil }

        // Description
        if let description = manifest[ManifestKey.description.rawValue] as? String { self.description = description } else { return nil }

        // Format Version
        if let formatVersion = manifest[ManifestKey.formatVersion.rawValue] as? Int { self.formatVersion = formatVersion } else { return nil }

        // Version
        if let version = manifest[ManifestKey.version.rawValue] as? Int { self.version = version } else { return nil }

        // Unique
        if let unique = manifest[ManifestKey.unique.rawValue] as? Bool { self.unique = unique } else { return nil }

        // Last Modified
        if let lastModified = manifest[ManifestKey.lastModified.rawValue] as? Date { self.lastModified = lastModified } else { return nil }

        // Platforms
        if type == .manifestsApple {
            if let platformsArray = manifest[ManifestKey.platforms.rawValue] as? [String] { self.platforms = PayloadUtility.platforms(fromArray: platformsArray) } else { return nil }
        } else {
            self.platforms = [.macOS]
        }

        // Targets
        if type == .manifestsApple {
            if let targetsArray = manifest[ManifestKey.targets.rawValue] as? [String] { self.targets = PayloadUtility.targets(fromArray: targetsArray) } else { return nil }
        } else {
            if let targetsArray = manifest[ManifestKey.targets.rawValue] as? [String] {
                self.targets = PayloadUtility.targets(fromArray: targetsArray)
            } else {
                self.targets = [.user, .system]
            }
        }

        // Distribution
        if type == .manifestsApple {
            if let distributionArray = manifest[ManifestKey.distribution.rawValue] as? [String] { self.distribution = PayloadUtility.distribution(fromArray: distributionArray) } else { self.distribution = Distribution.all }
        } else {
            self.distribution = Distribution.all
        }

        // Supervised
        if type == .manifestsApple {
            if let supervised = manifest[ManifestKey.supervised.rawValue] as? Bool { self.supervised = supervised } else { self.supervised = false }
        } else {
            self.supervised = false
        }

        // Substitution Variables
        if let substitutionVariables = manifest[ManifestKey.substitutionVariables.rawValue] as? [String: [String: String]] {
            self.substitutionVariables = substitutionVariables
        }

        // User Approved
        if type == .manifestsApple {
            if let userApproved = manifest[ManifestKey.userApproved.rawValue] as? Bool { self.userApproved = userApproved } else { self.userApproved = false }
        } else {
            self.userApproved = false
        }

        // Interaction
        if type == .manifestsApple, let interactionString = manifest[ManifestKey.interaction.rawValue] as? String {
            self.interaction = Interaction(keyValue: interactionString)
        } else {
            self.interaction = .undefined
        }

        // iOS Max
        if let iOSMax = manifest[ManifestKey.iOSMax.rawValue] as? String { self.iOSMax = iOSMax }

        // iOS Min
        if let iOSMin = manifest[ManifestKey.iOSMin.rawValue] as? String { self.iOSMin = iOSMin }

        // macOS Max
        if let macOSMax = manifest[ManifestKey.macOSMax.rawValue] as? String { self.macOSMax = macOSMax }

        // macOS Min
        if let macOSMin = manifest[ManifestKey.macOSMin.rawValue] as? String { self.macOSMin = macOSMin }

        // tvOS Max
        if let tvOSMax = manifest[ManifestKey.tvOSMax.rawValue] as? String { self.tvOSMax = tvOSMax }

        // tvOS Min
        if let tvOSMin = manifest[ManifestKey.tvOSMin.rawValue] as? String { self.tvOSMin = tvOSMin }

        // Documentation URL
        if let documentationURLString = manifest[ManifestKey.documentationURL.rawValue] as? String, let documentationURL = URL(string: documentationURLString) {
            self.documentationURL = documentationURL
        }

        // Note
        if let note = manifest[ManifestKey.note.rawValue] as? String {
            self.note = note
        }
    }

    func initializeComputedVariables() {
        self.payloadContentSubkeys = self.subkeys.filter { !kPayloadSubkeys.contains($0.key) }
        if self.payloadContentSubkeys.count == 1, let payloadSubkey = self.payloadContentSubkeys.first {
            payloadSubkey.isSinglePayloadContent = true
        }
    }

    func verifyProfileSubkeys() {
        for key in kProfileSubkeys {
            self.verifySharedSubkey(key: key)
        }
    }

    func verifyPayloadSubkeys() {
        for key in kPayloadSubkeys {
            self.verifySharedSubkey(key: key)
        }
    }

    private func verifySharedSubkey(key: String) {
        if !self.subkeys.contains(where: { $0.key == key }) {
            if let subkey = PayloadSubkey(payload: self, parentSubkey: nil, subkey: self.subkeyDict(forKey: key)) {
                self.subkeys.append(subkey)
                self.allSubkeys.append(subkey)
            }
        }
    }

    private func subkeyDict(forKey key: String) -> [String: Any] {
        switch key {
        case PayloadKey.payloadScope:
            return kSubkeyPayloadScope
        default:
            return [String: Any]()
        }
    }

    // MARK: -
    // MARK: Hashable

    public var hashValue: Int { ObjectIdentifier(self).hashValue }

    public static func == (lhs: Payload, rhs: Payload) -> Bool {
        lhs.domainIdentifier == rhs.domainIdentifier && lhs.type == rhs.type
    }

}
