//
//  PayloadManagedPreferenceSubkey.swift
//  ProfilePayloads
//
//  Created by Erik Berglund.
//  Copyright © 2017 Erik Berglund. All rights reserved.
//

import Foundation

func valuesAreEqual(_ value1: Any, _ v2: Any?) -> Bool {
    guard let value2 = v2 else {
        return false
    }

    let value1Type = String(cString: object_getClassName(value1))
    let value2Type = String(cString: object_getClassName(value2))

    guard value1Type == value2Type else {
        Swift.print("value1Type: \(value1Type) is not equal to: \(value2Type)")
        return false
    }

    return valuesAreEqual(value1, value2, type: value1Type)
}

func valuesAreEqual(_ value1: Any, _ value2: Any, type: String) -> Bool {
    switch type {
    case "__NSCFData":
        if
            let value1Data = value1 as? Data,
            let value2Data = value2 as? Data {
            return value1Data == value2Data
        } else {
            Swift.print("Failed to get value: \(value1) or: \(value2) with type: \(type)")
        }
    case "__NSCFBoolean":
        if
            let value1Bool = value1 as? Bool,
            let value2Bool = value2 as? Bool {
            return value1Bool == value2Bool
        } else {
            Swift.print("Failed to get value: \(value1) or: \(value2) with type: \(type)")
        }
    case "__NSCFString", "__NSCFConstantString", "NSTaggedPointerString":
        if
            let value1String = value1 as? String,
            let value2String = value2 as? String {
            return value1String == value2String
        } else {
            Swift.print("Failed to get value: \(value1) or: \(value2) with type: \(type)")
        }
    case "__NSCFNumber":
        if
            let value1Number = value1 as? NSNumber,
            let value2Number = value2 as? NSNumber {
            return value1Number == value2Number
        } else {
            Swift.print("Failed to get value: \(value1) or: \(value2) with type: \(type)")
        }
    case "__NSCFDictionary":
        if
        let value1Dict = value1 as? [String: AnyHashable],
        let value2Dict = value2 as? [String: AnyHashable] {
            return value1Dict == value2Dict
        } else {
            Swift.print("Failed to get value: \(value1) or: \(value2) with type: \(type)")
        }
    case "__NSDate", "__NSTaggedDate":
        if
            let value1Date = value1 as? Date,
            let value2Date = value2 as? Date {
            return value1Date == value2Date
        } else {
            Swift.print("Failed to get value: \(value1) or: \(value2) with type: \(type)")
        }
    case "__NSCFArray", "__NSArrayM", "__NSArrayI", "__NSArray0":
        if
            let value1Array = value1 as? [Any],
            let value2Array = value2 as? [Any] {

            guard !value1Array.isEmpty && !value2Array.isEmpty else {
                return true
            }

            if
                let value1Value = value1Array.first,
                let value2Value = value2Array.first {

                let value1TypePayload = PayloadUtility.valueType(value: value1Value)
                let value1Type = String(cString: object_getClassName(value1Value))

                let value2TypePayload = PayloadUtility.valueType(value: value2Value)
                let value2Type = String(cString: object_getClassName(value2Value))

                if value1TypePayload != value2TypePayload || value1Type != value2Type {
                    Swift.print("value1TypePayload: \(value1TypePayload)")
                    Swift.print("value2TypePayload: \(value2TypePayload)")
                    Swift.print("value1Type: \(value1Type)")
                    Swift.print("value2Type: \(value2Type)")
                }

                return value1Array.contains(values: value2Array, ofType: value1TypePayload)
            }
        } else {
            Swift.print("Failed to get value: \(value1) or: \(value2) with type: \(type)")
        }
    default:
        Swift.print("Unknown type: \(type)")
    }
    return false
}

public class PayloadManagedPreferenceLocalSubkey: PayloadSubkey {

    public weak var managedPreference: PayloadManagedPreferenceLocal?

    // MARK: -
    // MARK: PayloadApplicationSubkey

    public var preferenceDomain: PreferenceDomain = .unknown

    // MARK: -
    // MARK: Initialization

    init?(managedPreference: PayloadManagedPreferenceLocal, parentSubkey: PayloadSubkey?, subkey: [String: Any]) {
        super.init(payload: managedPreference, parentSubkey: parentSubkey, subkey: subkey)

        // ---------------------------------------------------------------------
        //  Store the passed variables
        // ---------------------------------------------------------------------
        self.managedPreference = managedPreference

        // ---------------------------------------------------------------------
        //  Initialize non-required variables
        // ---------------------------------------------------------------------
        for (key, element) in self.ignoredKeys {
            self.initialize(key: key, value: element, managedPreference: managedPreference)
        }

        // ---------------------------------------------------------------------
        //  Initialize computed variables
        // ---------------------------------------------------------------------
        self.isSingleContainer = ((self.type == .dictionary || self.type == .array || self.type == .integer) && self.subkeys.count == 1)

        if parentSubkey == nil, !kPayloadSubkeys.contains(self.key), let value = self.valueDefault {
            self.preferenceDomain = self.preferenceDomain(forKey: self.key, value: value)
            self.description = self.preferenceDomain.rawValue
        }
    }

    private func preferenceDomain(forKey key: String, value: Any) -> PreferenceDomain {
        if UserDefaults.standard.objectIsForced(forKey: key, inDomain: self.domain) {
            return .managed
        } else {

            // User ByHost
            if valuesAreEqual(value, CFPreferencesCopyValue(key as CFString, self.domain as CFString, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost)) {
                //Swift.print("Item: \(key): \(value) is set in: CURRENT USER BYHOST")
                return .userLibraryByHost

                // User Library
            } else if valuesAreEqual(value, CFPreferencesCopyValue(key as CFString, self.domain as CFString, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)) {
                //Swift.print("Item: \(key): \(value) is set in: CURRENT USER LIBRARY")
                return .userLibrary

                // User Library Global ByHost
            } else if valuesAreEqual(value, CFPreferencesCopyValue(key as CFString, kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost)) {
                //Swift.print("Item: \(key): \(value) is set in: CURRENT USER GLOBAL BYHOST")
                return .userLibraryGlobalByHost

                // User Library Global
            } else if valuesAreEqual(value, CFPreferencesCopyValue(key as CFString, kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)) {
                //Swift.print("Item: \(key): \(value) is set in: CURRENT USER GLOBAL")
                return .userLibraryGlobal

                // Library
            } else if valuesAreEqual(value, CFPreferencesCopyValue(key as CFString, self.domain as CFString, kCFPreferencesAnyUser, kCFPreferencesCurrentHost)) {
                //Swift.print("Item: \(key): \(value) is set in: LIBRARY")
                return .library

                // Library Global
            } else if valuesAreEqual(value, CFPreferencesCopyValue(key as CFString, kCFPreferencesAnyApplication, kCFPreferencesAnyUser, kCFPreferencesAnyHost)) {
                //Swift.print("Item: \(key): \(value) is set in: LIBRARY GLOBAL")
                return .libraryGlobal

            }

            // FIXME: Add SyncedPreferences ?
        }
        // Swift.print("\(self.domain): Item: \(key): \(value) was not found in any preference domain")
        return .unknown
    }

    private func initialize(key: String, value: Any?, managedPreference: PayloadManagedPreferenceLocal) {
        guard let manifestKey = ManifestKey(rawValue: key) else {
            Swift.print("Class: \(self.self), Function: \(#function), Failed to create a ManifesKey from dictionary key: \(key)")
            return
        }

        switch manifestKey {

        // Subkeys
        case .subkeys:
            if let subkeySubkeys = value as? [[String: Any]], let managedPreference = self.managedPreference {
                for subkeySubkey in subkeySubkeys {
                    if let subkey = PayloadManagedPreferenceLocalSubkey(managedPreference: managedPreference, parentSubkey: self, subkey: subkeySubkey) {
                        self.allSubkeys.append(contentsOf: subkey.allSubkeys)
                        self.subkeys.append(subkey)
                    }
                }
            }
            self.allSubkeys.append(contentsOf: self.subkeys)
            managedPreference.allSubkeys.append(contentsOf: self.subkeys)

        default:
            Swift.print("Class: \(self.self), Function: \(#function), Domain: \(self.domain), Key Not Implemented: \(manifestKey)")
        }
    }
}
