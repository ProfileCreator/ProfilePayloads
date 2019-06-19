//
//  PayloadManagedPreferenceSubkey.swift
//  ProfilePayloads
//
//  Created by Erik Berglund.
//  Copyright © 2017 Erik Berglund. All rights reserved.
//

import Foundation

public class PayloadManagedPreferenceSubkey: PayloadSubkey {

    public weak var managedPreference: PayloadManagedPreference?

    // MARK: -
    // MARK: Initialization

    init?(managedPreference: PayloadManagedPreference, parentSubkey: PayloadSubkey?, subkey: [String: Any]) {
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
    }

    private func initialize(key: String, value: Any?, managedPreference: PayloadManagedPreference) {
        guard let manifestKey = ManifestKey(rawValue: key) else {
            Swift.print("Class: \(self.self), Function: \(#function), Failed to create a ManifesKey from dictionary key: \(key)")
            return
        }

        switch manifestKey {

        // Subkeys
        case .subkeys:
            if let subkeySubkeys = value as? [[String: Any]], let managedPreference = self.managedPreference {
                for subkeySubkey in subkeySubkeys {
                    if let subkey = PayloadManagedPreferenceSubkey(managedPreference: managedPreference, parentSubkey: self, subkey: subkeySubkey) {
                        self.allSubkeys.append(contentsOf: subkey.allSubkeys)
                        self.subkeys.append(subkey)
                    }
                }
            }
            self.allSubkeys.append(contentsOf: self.subkeys)
            managedPreference.allSubkeys.append(contentsOf: self.subkeys)

        // App Deprecated
        case .appDeprecated:
            if let appDeprecated = value as? String {
                self.appDeprecated = appDeprecated
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type String") }

        // App Max
        case .appMax:
            if let appMax = value as? String {
                self.appMax = appMax
                managedPreference.add(appVersion: appMax)
            }

        // App Min
        case .appMin:
            if let appMin = value as? String {
                self.appMin = appMin
                managedPreference.add(appVersion: appMin)
            }

        default:
            Swift.print("Class: \(self.self), Function: \(#function), Domain: \(self.domain), Key Not Implemented: \(manifestKey)")
        }
    }
}
