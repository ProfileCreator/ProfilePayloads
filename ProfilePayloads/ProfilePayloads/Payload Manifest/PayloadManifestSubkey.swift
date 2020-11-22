//
//  PayloadKey.swift
//  ProfilePayloads
//
//  Created by Erik Berglund.
//  Copyright © 2017 Erik Berglund. All rights reserved.
//

import Foundation

public class PayloadManifestSubkey: PayloadSubkey {

    public weak var manifest: PayloadManifest?

    // MARK: -
    // MARK: Initialization

    init?(manifest: PayloadManifest, parentSubkey: PayloadSubkey?, subkey: [String: Any]) {
        super.init(payload: manifest, parentSubkey: parentSubkey, subkey: subkey)

        // ---------------------------------------------------------------------
        //  Store the passed variables
        // ---------------------------------------------------------------------
        self.manifest = manifest

        // ---------------------------------------------------------------------
        //  Initialize non-required variables
        // ---------------------------------------------------------------------
        for (key, value) in self.ignoredKeys {
            self.initialize(key: key, value: value)
        }

        // ---------------------------------------------------------------------
        //  Initialize computed variables
        // ---------------------------------------------------------------------
        self.isSingleContainer = ((self.type == .dictionary || self.type == .array || self.type == .integer) && self.subkeys.count == 1)
    }

    private func initialize(key: String, value: Any?) {
        guard let manifestKey = ManifestKey(rawValue: key) else {
            Swift.print("Class: \(self.self), Function: \(#function), Failed to create a ManifestKey from dictionary key: \(key)")
            return
        }

        switch manifestKey {

        // Subkeys
        case .subkeys:
            if let subkeySubkeys = value as? [[String: Any]], let manifest = self.manifest {
                for subkeySubkey in subkeySubkeys {
                    if let subkey = PayloadManifestSubkey(manifest: manifest, parentSubkey: self, subkey: subkeySubkey) {
                        self.subkeys.append(subkey)
                        self.allSubkeys.append(subkey)
                        self.allSubkeys.append(contentsOf: subkey.allSubkeys)
                    }
                }
            }

        default:
            Swift.print("Class: \(self.self), Function: \(#function), Domain: \(self.domain), Key Not Implemented: \(manifestKey)")
        }
    }
}
