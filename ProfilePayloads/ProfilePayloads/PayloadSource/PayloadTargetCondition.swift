//
//  PayloadTargetCondition.swift
//  ProfilePayloads
//
//  Created by Erik Berglund.
//  Copyright © 2017 Erik Berglund. All rights reserved.
//

import Foundation

public class PayloadTargetCondition {

    // MARK: -
    // MARK: PayloadKey

    let dictionary: [String: Any]

    // MARK: -
    // MARK: PayloadExclude

    public var containsAny: [Any]?
    public var notContainsAny: [Any]?
    public var rangeList: [Any]?
    public var notRangeList: [Any]?
    // swiftlint:disable:next discouraged_optional_boolean
    public var isPresent: Bool?
    // swiftlint:disable:next discouraged_optional_boolean
    public var isEmpty: Bool?
    public var platforms: Platforms?
    public var notPlatforms: Platforms?
    public var distribution: Distribution?
    public let targetKeyPath: String
    public let targetDomain: String
    public let targetDomainIdentifier: String
    public let identifier = UUID().uuidString

    private weak var targetPayloadSubkey: PayloadSubkey?
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
        //  Initialize required variables
        // ---------------------------------------------------------------------
        // Target
        if let targetKeyPath = condition[ManifestKey.target.rawValue] as? String {
            self.targetKeyPath = targetKeyPath
            self.ignoredKeys.removeValue(forKey: ManifestKey.target.rawValue)
        } else {
            self.targetKeyPath = payloadSubkey.keyPath
        }

        // Domain
        if let domain = condition[ManifestKey.domain.rawValue] as? String {
            self.targetDomain = domain
            self.ignoredKeys.removeValue(forKey: ManifestKey.domain.rawValue)
        } else { self.targetDomain = payloadSubkey.domain }

        // DomainIdentifier
        if let domainIdentifier = condition[ManifestKey.domain.rawValue] as? String {
            self.targetDomainIdentifier = domainIdentifier
            self.ignoredKeys.removeValue(forKey: ManifestKey.domain.rawValue)
        } else { self.targetDomainIdentifier = payloadSubkey.domainIdentifier }

        // Platforms
        if let platformsArray = condition[ManifestKey.platforms.rawValue] as? [String] {
            self.platforms = PayloadUtility.platforms(fromArray: platformsArray)
            self.ignoredKeys.removeValue(forKey: ManifestKey.platforms.rawValue)
        }

        // Not Platforms
        if let notPlatformsArray = condition[ManifestKey.notPlatforms.rawValue] as? [String] {
            self.notPlatforms = PayloadUtility.platforms(fromArray: notPlatformsArray)
            self.ignoredKeys.removeValue(forKey: ManifestKey.notPlatforms.rawValue)
        }

        // Distribution
        if let distributionArray = condition[ManifestKey.distribution.rawValue] as? [String] {
            self.distribution = PayloadUtility.distribution(fromArray: distributionArray)
            self.ignoredKeys.removeValue(forKey: ManifestKey.distribution.rawValue)
        }

        // Verify atleast one of target, distribution, platforms or notPlatforms is initialized
        if condition[ManifestKey.target.rawValue] == nil, self.platforms == nil, self.notPlatforms == nil, self.distribution == nil {
            return nil
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

        // Contains Any
        case .containsAny:
            if let containsAny = value as? [Any] {
                self.containsAny = containsAny
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type") }

        // Not Contains Any
        case .notContainsAny:
            if let notContainsAny = value as? [Any] {
                self.notContainsAny = notContainsAny
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type") }

        // Not Range List
        case .notRangeList:
            // FIXME: This doesn't check for the type. It probably should
            if let notRangeList = value as? [Any] {
                self.notRangeList = notRangeList
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type") }

        // Is Empty
        case .isEmpty:
            if let isEmpty = value as? Bool {
                self.isEmpty = isEmpty
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type Bool") }

        // Is Present
        case .isPresent:
            if let isPresent = value as? Bool {
                self.isPresent = isPresent
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type Bool") }

        // Range List
        case .rangeList:
            // FIXME: This doesn't check for the type. It probably should
            if let rangeList = value as? [Any] {
                self.rangeList = rangeList
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type Array") }

        default:
            Swift.print("Class: \(self.self), Function: \(#function), Key Not Implemented: \(manifestKey)")
            ignoreKey = true
        }

        if !ignoreKey {
            self.ignoredKeys.removeValue(forKey: key)
        }
    }

    public func targetSubkey() -> PayloadSubkey? {
        if self.targetPayloadSubkey == nil {

            // Get source
            guard let payloadSubkey = self.payloadSubkey else { return nil }
            if payloadSubkey.keyPath == self.targetKeyPath, payloadSubkey.domainIdentifier == self.targetDomainIdentifier {
                self.targetPayloadSubkey = payloadSubkey
            } else {
                self.targetPayloadSubkey = ProfilePayloads.shared.payloadSubkey(forKeyPath: self.targetKeyPath, domainIdentifier: self.targetDomainIdentifier, type: payloadSubkey.payloadType)
            }
        }
        return self.targetPayloadSubkey
    }
}
