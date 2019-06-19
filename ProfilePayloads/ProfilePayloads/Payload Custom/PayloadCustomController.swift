//
//  PayloadCustomController.swift
//  ProfilePayloads
//
//  Created by Erik Berglund.
//  Copyright © 2017 Erik Berglund. All rights reserved.
//

import Foundation

class PayloadCustomController {

    // MARK: -
    // MARK: Static Variables

    internal static let shared = PayloadCustomController()

    // MARK: -
    // MARK: Initialization

    private init() {}

    // MARK: -
    // MARK: Update

    public func updateAll() {
        return
    }

    public func update(type: PayloadType) {
        return
    }

    // MARK: -
    // MARK: Custom Manifest

    internal func customManifest(forDomainIdentifier domainIdentifier: String, ofType type: PayloadType, payloadContent: [[String: Any]]) -> PayloadCustom? {
        switch type {
        case .custom:
            return PayloadCustom(payloadContent: payloadContent, hash: "1")
        default:
            return nil
        }
    }

    // MARK: -
    // MARK: Custom Manifests

    internal func customManifests(forType type: PayloadType, typeSettings: [String: [[String: Any]]]) -> [PayloadCustom]? {
        switch type {
        case .custom:
            var manifests = [PayloadCustom]()
            for domainIdentifier in typeSettings.keys {
                if
                    let payloadContent = typeSettings[domainIdentifier],
                    let payload = ProfilePayloads.shared.customManifest(forDomainIdentifier: domainIdentifier, ofType: type, payloadContent: payloadContent) {
                    manifests.append(payload)
                }
            }
            return manifests
        default:
            return nil
        }
    }

    // MARK: -
    // MARK: Custom Manifest Placeholders

    internal func customManifestPlaceholders(forType type: PayloadType, typeSettings: [String: [[String: Any]]]) -> [PayloadPlaceholder]? {
        switch type {
        case .custom:
            var placeholders = [PayloadPlaceholder]()
            for domainIdentifier in typeSettings.keys {
                if
                    let payloadContent = typeSettings[domainIdentifier],
                    let payload = ProfilePayloads.shared.customManifest(forDomainIdentifier: domainIdentifier, ofType: type, payloadContent: payloadContent),
                    let payloadPlaceholder = payload.placeholder {
                    placeholders.append(payloadPlaceholder)
                }
            }
            return placeholders
        default:
            return nil
        }
    }
}
