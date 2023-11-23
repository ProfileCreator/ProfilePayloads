//
//  PayloadPlaceholder.swift
//  ProfilePayloads
//
//  Created by Erik Berglund.
//  Copyright © 2017 Erik Berglund. All rights reserved.
//

import Foundation

public class PayloadPlaceholder: Hashable, Encodable, Decodable {

    // MARK: -
    // MARK: Variables

    public let title: String
    public let description: String
    public let domain: String
    public let domainIdentifier: String
    public var icon: NSImage?
    public let payload: Payload
    public let payloadType: PayloadType
    public let payloadContent: [[String: Any]]?

    // MARK: -
    // MARK: Initialization

    init(payload: Payload) {
        self.payload = payload
        self.payloadType = payload.type
        self.title = payload.title
        self.description = payload.description
        self.domain = payload.domain
        self.icon = payload.icon
        self.domainIdentifier = payload.domainIdentifier
        self.payloadContent = payload.payloadContent
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Title
        self.title = try container.decode(String.self, forKey: .title)

        // Description
        self.description = try container.decode(String.self, forKey: .description)

        // Domain
        self.domain = try container.decode(String.self, forKey: .domain)

        // Identifier
        self.domainIdentifier = try container.decode(String.self, forKey: .domainIdentifier)

        // Icon
        if let iconData = try? container.decode(Data.self, forKey: .iconData) {
            self.icon = NSKeyedUnarchiver.unarchiveObject(with: iconData) as? NSImage
        }

        // PayloadType
        let typeRawValue = try container.decode(String.self, forKey: .payloadType)
        self.payloadType = PayloadType(rawValue: typeRawValue)! // This needs to be fixed!

        // Payload
        if self.payloadType != .custom {
            if let payload = ProfilePayloads.shared.payload(forDomainIdentifier: self.domainIdentifier, type: self.payloadType) {
                self.payload = payload
                self.payloadContent = nil
            } else {
                // TODO: Fix This
                throw NSError(domain: "test", code: 1, userInfo: nil)
            }
        } else {
            if
                let payloadContentData = try? container.decode(Data.self, forKey: .payloadContent),
                let payloadContent = NSKeyedUnarchiver.unarchiveObject(with: payloadContentData) as? [[String: Any]],
                let payload = ProfilePayloads.shared.customManifest(forDomainIdentifier: self.domainIdentifier, ofType: self.payloadType, payloadContent: payloadContent) {
                self.payload = payload
                self.payloadContent = payloadContent
            } else {
                // TODO: Fix This
                throw NSError(domain: "test", code: 1, userInfo: nil)
            }
        }
    }

    // MARK: -
    // MARK: Encodable

    enum CodingKeys: String, CodingKey {
        case title
        case description
        case domain
        case iconData
        case domainIdentifier
        case payloadType
        case payloadContent
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // Title
        try container.encode(self.title, forKey: .title)

        // Description
        try container.encode(self.description, forKey: .description)

        // Domain
        try container.encode(self.domain, forKey: .domain)

        // Icon
        if let icon = self.icon {
            try container.encode(NSKeyedArchiver.archivedData(withRootObject: icon), forKey: .iconData)
        }

        // Identifier
        try container.encode(self.domainIdentifier, forKey: .domainIdentifier)

        // PayloadType
        try container.encode(self.payloadType.rawValue, forKey: .payloadType)

        // PayloadContent
        if let content = self.payloadContent {
            try container.encode(NSKeyedArchiver.archivedData(withRootObject: content), forKey: .payloadContent)
        }
    }

    // MARK: -
    // MARK: Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
    public static func == (lhs: PayloadPlaceholder, rhs: PayloadPlaceholder) -> Bool {
        lhs.domainIdentifier == rhs.domainIdentifier && lhs.payloadType == rhs.payloadType
    }
}
