//
//  PayloadCondition.swift
//  ProfilePayloads
//
//  Created by Erik Berglund.
//  Copyright © 2017 Erik Berglund. All rights reserved.
//

import Foundation

public class PayloadCondition {

    // MARK: -
    // MARK: PayloadKey

    let dictionary: [String: Any]
    public var conditions = [PayloadTargetCondition]()

    // MARK: -
    // MARK: PayloadConditionals

    public var require: PayloadKeyRequire = .never
    public weak var payload: Payload?
    public weak var payloadSubkey: PayloadSubkey?
    public var ignoredKeys: [String: Any]

    // MARK: -
    // MARK: Initialization

    init?(payload: Payload, payloadSubkey: PayloadSubkey, condition: [String: Any]) {

        // ---------------------------------------------------------------------
        //  Store the passed variables
        // ---------------------------------------------------------------------
        self.dictionary = condition
        self.payload = payload
        self.payloadSubkey = payloadSubkey

        // ---------------------------------------------------------------------
        //  Create a mutable dictionary to remove all initialized keys from
        // ---------------------------------------------------------------------
        self.ignoredKeys = condition

        // ---------------------------------------------------------------------
        //  Verify we got what we expected
        // ---------------------------------------------------------------------
        guard let targetConditions = condition[ManifestKey.targetConditions.rawValue] as? [[String: Any]] else {
            Swift.print("Class: \(self.self), Function: \(#function), Conditionals dict doesn't contain required key: \(ManifestKey.targetConditions.rawValue)")
            return nil
        }
        self.ignoredKeys.removeValue(forKey: ManifestKey.targetConditions.rawValue)

        // ---------------------------------------------------------------------
        //  Initialize required variables
        // ---------------------------------------------------------------------
        for targetCondition in targetConditions {
            if let condition = PayloadTargetCondition(payload: payload, payloadSubkey: payloadSubkey, condition: targetCondition) {
                self.conditions.append(condition)

                switch payloadSubkey.payloadType {
                case .manifestsApple:
                    PayloadManifestController.shared.conditionalTargets.append((condition.targetKeyPath, condition.targetDomainIdentifier))
                case .managedPreferencesApple,
                     .managedPreferencesApplications,
                     .managedPreferencesApplicationsLocal,
                     .managedPreferencesDeveloper:
                    PayloadManagedPreferenceController.shared.conditionalTargets.append((condition.targetKeyPath, condition.targetDomainIdentifier))
                case .all,
                     .custom:
                    Swift.print("Unhandled payload type: \(payloadSubkey.payloadType)")
                }
            }
        }

        // ---------------------------------------------------------------------
        //  Initialize non-required variables
        // ---------------------------------------------------------------------
        for (key, element) in self.ignoredKeys {
            self.initialize(key: key, value: element)
        }
    }

    private func initialize(key: String, value: Any?) {
        guard let manifestKey = ManifestKey(rawValue: key) else {
            Swift.print("Class: \(self.self), Function: \(#function), Failed to create a ManifesKey from dictionary key: \(key)")
            return
        }

        // ---------------------------------------------------------------------
        //  Set an internal variable to check if the key is matched or not
        // ---------------------------------------------------------------------
        var ignoreKey = false

        // ---------------------------------------------------------------------
        //  Check if the current key should be initialized, and that it's value is of the correct type
        // ---------------------------------------------------------------------
        switch manifestKey {

        // Require
        case .require, .required:
            if let requireString = value as? String {
                self.require = PayloadKeyRequire(keyValue: requireString)
            } else if let requireBool = value as? Bool, requireBool {
                self.require = .always
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type String or Bool") }

        default:
            Swift.print("Class: \(self.self), Function: \(#function), Key Not Implemented: \(manifestKey)")
            ignoreKey = true
        }

        if !ignoreKey {
            self.ignoredKeys.removeValue(forKey: key)
        }
    }
}
