//
//  PayloadManagedPreferenceLocal.swift
//  ProfilePayloads
//
//  Created by Erik Berglund.
//  Copyright © 2017 Erik Berglund. All rights reserved.
//

import Cocoa

public class PayloadManagedPreferenceLocal: Payload {

    // MARK: -
    // MARK: Variables

    public var appURL: URL?
    public var appPath: String?
    public var appVersion: String?
    public var appShortVersion: String?
    public var appBuildVersion: String?
    public var appBundle: Bundle?

    // MARK: -
    // MARK: Initialization

    // MARK: -
    // MARK: Initialization

    init?(domain: String, hash: String) {

        var bundle: Bundle?
        let bundlePath = NSWorkspace.shared.absolutePathForApplication(withBundleIdentifier: domain)
        if let path = bundlePath {
            bundle = Bundle(path: path)
        }

        let manifest = PayloadManagedPreferenceLocal.manifest(forDomain: domain, bundle: bundle)

        super.init(manifest: manifest, manifestURL: nil, hash: hash, type: .managedPreferencesApplicationsLocal)

        // Subkeys
        if let applicationSubkeys = self.manifestDict[ManifestKey.subkeys.rawValue] as? [[String: Any]] {
            for applicationSubkey in applicationSubkeys {
                if let subkey = PayloadManagedPreferenceLocalSubkey(managedPreference: self, parentSubkey: nil, subkey: applicationSubkey) {
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

        // App Bundle, Version, Build
        if let appBundle = bundle {
            self.appBundle = appBundle
            self.appVersion = appBundle.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String
            self.appShortVersion = appBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            self.appBuildVersion = appBundle.object(forInfoDictionaryKey: "CFBundleBuildVersion") as? String
        }

        // Icon
        if let bundlePath = bundlePath {
            self.appPath = bundlePath
            self.icon = NSWorkspace.shared.icon(forFile: bundlePath)
        } else if let icon = Bundle(for: ProfilePayloads.self).image(forResource: NSImage.Name("PlaceholderSquare")) {
            self.icon = icon
        }
    }

    public class func manifest(forDomain domain: String, bundle: Bundle?) -> [String: Any] {

        var manifest = [String: Any]()
        var manifestSubkeys = [[String: Any]]()

        guard let globalPreferencesKeys = UserDefaults(suiteName: "GlobalPreferences")?.dictionaryRepresentation().keys else { return manifest }

        let bundleName = bundle?.object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String ?? domain
        guard let domainPreferencesGlobal = UserDefaults(suiteName: domain)?.dictionaryRepresentation() else { return manifest }
        let domainPreferences: [String: Any]

        if domain == ".GlobalPreferences" {
            domainPreferences = domainPreferencesGlobal
        } else {
            domainPreferences = domainPreferencesGlobal.filter { !globalPreferencesKeys.contains($0.key) }
        }

        manifest[ManifestKey.domain.rawValue] = domain
        manifest[ManifestKey.title.rawValue] = bundleName
        manifest[ManifestKey.description.rawValue] = "Configures \(bundleName) settings"
        manifestSubkeys.append(self.manifestDict(forKey: PayloadKey.payloadType, value: domain, type: .string))

        // Add Constants
        manifest[ManifestKey.formatVersion.rawValue] = 1
        manifest[ManifestKey.version.rawValue] = 1
        manifest[ManifestKey.unique.rawValue] = false
        manifest[ManifestKey.lastModified.rawValue] = Date()
        manifest[ManifestKey.platforms.rawValue] = PayloadUtility.strings(fromPlatforms: .macOS)
        manifest[ManifestKey.target.rawValue] = PayloadUtility.strings(fromTargets: .all)
        manifest[ManifestKey.distribution.rawValue] = PayloadUtility.strings(fromDistribution: .all)
        manifest[ManifestKey.supervised.rawValue] = false
        manifest[ManifestKey.userApproved.rawValue] = false
        manifest[ManifestKey.interaction.rawValue] = Interaction.undefined.rawValue

        // Add Subkeys
        manifestSubkeys.append(contentsOf: self.manifestSubkeysRequired(forDomain: domain))
        manifestSubkeys.append(contentsOf: self.manifestSubkeys(forPreferences: domainPreferences, parentKey: nil))
        manifest[ManifestKey.subkeys.rawValue] = manifestSubkeys

        return manifest
    }

    public class func manifestSubkeysRequired(forDomain domain: String) -> [[String: Any]] {
        var manifestSubkeys = [[String: Any]]()

        // PayloadDescription
        manifestSubkeys.append(
            [
                ManifestKey.valueDefault.rawValue: "Configures \(domain) settings",
                ManifestKey.description.rawValue: "Description of the payload.",
                ManifestKey.name.rawValue: PayloadKey.payloadDescription,
                ManifestKey.title.rawValue: "Payload Description",
                ManifestKey.type.rawValue: PayloadValueType.string.rawValue
            ])

        // PayloadDisplayName
        manifestSubkeys.append(
            [
                ManifestKey.valueDefault.rawValue: domain,
                ManifestKey.description.rawValue: "Name of the payload.",
                ManifestKey.name.rawValue: PayloadKey.payloadDisplayName,
                ManifestKey.require.rawValue: PayloadKeyRequire.always.rawValue,
                ManifestKey.title.rawValue: "Payload Display Name",
                ManifestKey.type.rawValue: PayloadValueType.string.rawValue
            ])

        // PayloadIdentifier
        manifestSubkeys.append(
            [
                ManifestKey.valueDefault.rawValue: domain,
                ManifestKey.description.rawValue: "A unique identifier for the payload, dot-delimited.  Usually root PayloadIdentifier+subidentifier.",
                ManifestKey.name.rawValue: PayloadKey.payloadIdentifier,
                ManifestKey.require.rawValue: PayloadKeyRequire.always.rawValue,
                ManifestKey.title.rawValue: "Payload Identifier",
                ManifestKey.type.rawValue: PayloadValueType.string.rawValue
            ])

        // PayloadType
        manifestSubkeys.append(
            [
                ManifestKey.valueDefault.rawValue: domain,
                ManifestKey.description.rawValue: "The type of the payload, a reverse dns string.",
                ManifestKey.name.rawValue: PayloadKey.payloadType,
                ManifestKey.require.rawValue: PayloadKeyRequire.always.rawValue,
                ManifestKey.title.rawValue: "Payload Type",
                ManifestKey.type.rawValue: PayloadValueType.string.rawValue
            ])

        // PayloadUUID
        manifestSubkeys.append(
            [
                ManifestKey.description.rawValue: "Unique identifier for the payload (format 01234567-89AB-CDEF-0123-456789ABCDEF).",
                ManifestKey.format.rawValue: "^[0-9A-Za-z]{8}-[0-9A-Za-z]{4}-[0-9A-Za-z]{4}-[0-9A-Za-z]{4}-[0-9A-Za-z]{12}$",
                ManifestKey.name.rawValue: PayloadKey.payloadUUID,
                ManifestKey.require.rawValue: PayloadKeyRequire.always.rawValue,
                ManifestKey.title.rawValue: "Payload UUID",
                ManifestKey.type.rawValue: PayloadValueType.string.rawValue
            ])

        // PayloadVersion
        manifestSubkeys.append(
            [
                ManifestKey.valueDefault.rawValue: 1,
                ManifestKey.description.rawValue: "The version of the whole configuration profile.",
                ManifestKey.name.rawValue: PayloadKey.payloadVersion,
                ManifestKey.require.rawValue: PayloadKeyRequire.always.rawValue,
                ManifestKey.title.rawValue: "Payload Version",
                ManifestKey.type.rawValue: PayloadValueType.integer.rawValue
            ])

        // PayloadOrganization
        manifestSubkeys.append(
            [
                ManifestKey.description.rawValue: "This value describes the issuing organization of the profile, as displayed to the user.",
                ManifestKey.name.rawValue: PayloadKey.payloadOrganization,
                ManifestKey.title.rawValue: "Payload Organization",
                ManifestKey.type.rawValue: PayloadValueType.string.rawValue
            ])

        return manifestSubkeys
    }

    public class func manifestSubkeys(forPreferences preferences: [String: Any], parentKey: String?) -> [[String: Any]] {
        var manifestSubkeys = [[String: Any]]()
        for (key, value) in preferences {
            let valueType = PayloadUtility.valueType(value: value)
            manifestSubkeys.append(self.manifestDict(forKey: key, value: value, type: valueType))
        }

        return manifestSubkeys
    }

    public class func manifestDict(forKey key: String, value: Any?, type: PayloadValueType) -> [String: Any] {
        var manifestDict = [String: Any]()

        manifestDict[ManifestKey.name.rawValue] = key
        manifestDict[ManifestKey.type.rawValue] = type.rawValue

        if let valueDefault = value {
            manifestDict[ManifestKey.valueDefault.rawValue] = valueDefault
        }

        if kPreferenceKeysIgnored.contains(key) || kPreferenceKeyPrefixesIgnored.contains(where: { key.hasPrefix($0) }) {
            manifestDict[ManifestKey.hidden.rawValue] = Hidden.all.rawValue
        }

        if type == .array, let valueArray = value as? [Any] {
            manifestDict[ManifestKey.subkeys.rawValue] = self.manifestArraySubkeys(forPreferences: valueArray, parentKey: key)
        } else if type == .dictionary, let valueDictionary = value as? [String: Any] {
            manifestDict[ManifestKey.subkeys.rawValue] = self.manifestDictionarySubkeys(forPreferences: valueDictionary, parentKey: key)
        }

        return manifestDict
    }

    // Subkeys when parent is a dictionary
    public class func manifestDictionarySubkeys(forPreferences preferences: [String: Any], parentKey: String?) -> [[String: Any]] {
        var manifestDictionarySubkeys = [[String: Any]]()

        var dynamicDict = true

        // Loop through all keys and values
        for (key, value) in preferences {

            //Swift.print("Checking: \(key): \(value)")

            let valueType = PayloadUtility.valueType(value: value)
            let manifestDict = self.manifestDict(forKey: key, value: value, type: valueType)

            //Swift.print("dynamicDict: \(dynamicDict)")

            if dynamicDict, !manifestDictionarySubkeys.isEmpty {
                let existingKeys = manifestDictionarySubkeys.flatMap { $0.keys }
                //Swift.print("existingKeys: \(existingKeys)")
                //Swift.print("Set(existingKeys).isDisjoint(with: newKeys): \(!Set(existingKeys).isDisjoint(with: manifestDict.keys))")
                dynamicDict = !Set(existingKeys).isDisjoint(with: manifestDict.keys)
            }

            manifestDictionarySubkeys.append(manifestDict)
        }

        if 2 <= preferences.count, dynamicDict {

            var manifestDynamicDictionarySubkeys = [[String: Any]]()
            var manifestDynamicDictionaryValueType: PayloadValueType = .string
            var manifestDynamicDictionaryValueSubkeys: [[String: Any]]?

            for dictionary in manifestDictionarySubkeys {

                guard let typeString = dictionary[ManifestKey.type.rawValue] as? String else { continue }

                let type = PayloadValueType(stringValue: typeString)
                guard type != .undefined else { continue }

                manifestDynamicDictionaryValueType = type

                guard let subkeys = dictionary[ManifestKey.subkeys.rawValue] as? [[String: Any]] else { continue }

                switch type {
                case .array:
                    if
                        let subkeySubkey = subkeys.first,
                        let subkeySubkeyTypeString = subkeySubkey[ManifestKey.type.rawValue] as? String {
                        let subkeySubkeyType = PayloadValueType(stringValue: subkeySubkeyTypeString)
                        manifestDynamicDictionaryValueSubkeys = [self.manifestDict(forKey: "ArrayItem", value: nil, type: subkeySubkeyType)]
                        break
                    }
                case .dictionary:
                    // FIXME: This must be handled, both here and in the main app to pull all dict keys out of subkeys and just add them after the key, removing the dict wrapper.
                    continue
                default:
                    continue
                }

            }

            var manifestDynamicKey = self.manifestDict(forKey: ManifestKeyPlaceholder.key, value: nil, type: .string)
            manifestDynamicKey[ManifestKey.title.rawValue] = "Key"
            manifestDynamicDictionarySubkeys.append(manifestDynamicKey)

            var manifestDynamicValue = self.manifestDict(forKey: ManifestKeyPlaceholder.value, value: nil, type: manifestDynamicDictionaryValueType)
            manifestDynamicValue[ManifestKey.title.rawValue] = "Value"
            if let valueSubkeys = manifestDynamicDictionaryValueSubkeys {
                manifestDynamicValue[ManifestKey.subkeys.rawValue] = valueSubkeys
            }
            manifestDynamicDictionarySubkeys.append(manifestDynamicValue)

            manifestDictionarySubkeys = manifestDynamicDictionarySubkeys
        }

        return manifestDictionarySubkeys
    }

    // Subkeys when parent is an array
    public class func manifestArraySubkeys(forPreferences preferences: [Any], parentKey: String?) -> [[String: Any]] {

        var manifestSubkeys = [[String: Any]]()

        guard let valueFirst = preferences.first else { return manifestSubkeys }

        let valueType = PayloadUtility.valueType(value: valueFirst)
        var manifestSubkey = self.manifestDict(forKey: parentKey ?? "" + "Item", value: nil, type: valueType)

        if valueType == .array {
            //Swift.print("Array in array")
            var manifestArraySubkeys = [[String: Any]]()
            for value in preferences {
                //Swift.print("Checking value: \(value)")
                guard let valueArray = value as? [Any] else { continue }
                //Swift.print("Checking valueArray: \(valueArray)")
                let subkeys = self.manifestArraySubkeys(forPreferences: valueArray, parentKey: parentKey ?? "" + "Item")
                let newSubkeys = subkeys.filter {
                    if let key = $0[ManifestKey.name.rawValue] as? String {
                        return !manifestArraySubkeys.contains { $0[ManifestKey.name.rawValue] as? String == key }
                    } else { return false }
                }
                //Swift.print("manifestSubkeys BEFORE: \(manifestArraySubkeys)")
                manifestArraySubkeys.append(contentsOf: newSubkeys)
                //Swift.print("manifestSubkeys AFTER: \(manifestArraySubkeys)")
            }
            manifestSubkey[ManifestKey.subkeys.rawValue] = manifestArraySubkeys
        } else if valueType == .dictionary {

            var manifestDictionarySubkeys = [[String: Any]]()
            for value in preferences {

                guard let valueDictionary = value as? [String: Any] else { continue }

                let subkeys = self.manifestSubkeys(forPreferences: valueDictionary, parentKey: parentKey ?? "" + "Item")
                let newSubkeys = subkeys.filter {
                    if let key = $0[ManifestKey.name.rawValue] as? String {
                        return !manifestDictionarySubkeys.contains { $0[ManifestKey.name.rawValue] as? String == key }
                    } else { return false }
                }
                manifestDictionarySubkeys.append(contentsOf: newSubkeys)
            }
            manifestSubkey[ManifestKey.subkeys.rawValue] = manifestDictionarySubkeys
        } else if valueType == .undefined {
            Swift.print("Unhandled subkey type: \(valueType)")
        }

        //Swift.print("manifestSubkeys: \(manifestSubkeys)")
        manifestSubkeys.append(manifestSubkey)
        return manifestSubkeys
    }

    override init?(manifest: [String: Any], manifestURL: URL?, hash: String, type: PayloadType) {
        fatalError("This class cannot be initialized with a manifest. use init?(domain:preferences:hash:)")
        return nil
    }
}
