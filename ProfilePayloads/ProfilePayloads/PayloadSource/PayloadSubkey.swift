//
//  PayloadSubkey.swift
//  ProfilePayloads
//
//  Created by Erik Berglund.
//  Copyright © 2017 Erik Berglund. All rights reserved.
//

import Foundation

// Compare Dictionaries
public func == (lhs: PayloadSubkey, rhs: PayloadSubkey ) -> Bool {
    return lhs.identifier == rhs.identifier
}

public class PayloadSubkey {

    // MARK: -
    // MARK: PayloadKey

    public let dictionary: [String: Any]

    // MARK: -
    // MARK: PayloadSubkey

    public var allowedFileTypes: [String]?
    public var allSubkeys = [PayloadSubkey]()
    public var conditionals = [PayloadCondition]()
    public var containsAny: [Any]? // Only seen once, review this key in the subkey context closely. It's in the vpn payload.
    public var dateStyle: DateStyle?
    public var dateAllowPast: Bool = false
    public var description: String?
    public var descriptionExtended: String?
    public var descriptionReference: String?
    public var domain: String
    public var domainIdentifier: String
    public var documentationURL: URL?
    public var documentationSource: String?
    public var enabledDefault: Bool = false
    public var excluded: Bool = false
    public var excludes = [PayloadExclude]()
    public var format: String?
    public var hidden: Hidden
    public var key: String
    public var keyPath: String
    public var note: String?
    public var parentSubkey: PayloadSubkey?
    public var parentSubkeys: [PayloadSubkey]?
    public var payloadType: PayloadType
    public var platformsManifest: Platforms?
    public var platformsNotManifest: Platforms?
    public let platforms: Platforms
    public var rangeList: [Any]?
    public var rangeListAllowCustomValue: Bool = false
    public var rangeListTitles: [String]?
    public var rangeMax: Any?
    public var rangeMin: Any?
    public var require: PayloadKeyRequire = .never
    public var repetitionMax: Int?
    public var repetitionMin: Int?
    public var rootSubkey: PayloadSubkey?
    public var segments: [String: [String]]?
    public var sensitive = false
    public var sensitiveMessage: String?
    public var subkeys = [PayloadSubkey]()
    public var substitutionVariables: [String: [String: String]]?
    public var supervised = false
    public var targets: Targets?
    public var title: String?
    public var type: PayloadValueType
    public var typeInput: PayloadValueType
    public var userApproved: Bool = false
    public var valueCopy: String?
    public var valueDecimalPlaces: Int?
    public var valueDefault: Any?
    public var valueDefaultCopy: String?
    public var valuePlaceholder: Any?
    public var valueProcessor: String?
    public var valueInfoProcessor: String?
    public var valueImportProcessor: String?
    public var valueInverted = false
    public var valueKeyPath: String
    public var valueUnit: String?
    public var valueUnique = false
    public var view: String?
    public var isConditionalTarget = false

    public var platformsDeprecated: Platforms = .none
    public var appDeprecated: String?
    public var appMax: String?
    public var appMin: String?
    public var macOSDeprecated: String?
    public var macOSMax: String?
    public var macOSMin: String?
    public var iOSDeprecated: String?
    public var iOSMax: String?
    public var iOSMin: String?
    public var tvOSDeprecated: String?
    public var tvOSMax: String?
    public var tvOSMin: String?

    // Only applicable to container types (dict or array)
    // Defines wether it only holds
    public var isSingleContainer: Bool = false
    public var isSinglePayloadContent: Bool = false

    public weak var payload: Payload?
    public var ignoredKeys: [String: Any]

    public var identifier = UUID()

    // Special Variables
    public var isParentArrayOfDictionaries: Bool = false

    // MARK: -
    // MARK: Initialization

    init?(payload: Payload, parentSubkey pSubkey: PayloadSubkey?, subkey: [String: Any]) {

        // ---------------------------------------------------------------------
        //  Store the passed variables
        // ---------------------------------------------------------------------
        self.dictionary = subkey
        self.domain = payload.domain
        self.domainIdentifier = payload.domainIdentifier
        self.payload = payload
        self.payloadType = payload.type

        // ---------------------------------------------------------------------
        //  Create a mutable dictionary to remove all initialized keys from
        // ---------------------------------------------------------------------
        self.ignoredKeys = subkey

        // ---------------------------------------------------------------------
        //  Initialize required variables
        // ---------------------------------------------------------------------
        // Type
        //let type: PayloadValueType
        if let subkeyType = subkey[ManifestKey.type.rawValue] as? String {
            let valueType = PayloadValueType(stringValue: subkeyType)
            if valueType != .undefined {
                //type = valueType
                self.type = valueType
                self.ignoredKeys.removeValue(forKey: ManifestKey.type.rawValue)
            } else { return nil }
        } else { return nil }

        // Key
        if let key = subkey[ManifestKey.name.rawValue] as? String {
            self.key = key
            self.ignoredKeys.removeValue(forKey: ManifestKey.name.rawValue)
        } else if let parentSubkey = pSubkey, parentSubkey.type == .array { // , ( type != .dictionary && type != .array )
            self.key = parentSubkey.key + "Item"
        } else {
            return nil
        }

        // Value KeyPath
        // Parent Subkeys
        // Root Subkeys
        if let parentSubkey = pSubkey {
            self.parentSubkey = parentSubkey
            self.rootSubkey = parentSubkey.rootSubkey ?? parentSubkey
            var parentSubkeys: [PayloadSubkey]
            if var pSubkeys = parentSubkey.parentSubkeys {
                pSubkeys.append(parentSubkey)
                parentSubkeys = pSubkeys
            } else {
                parentSubkeys = [parentSubkey]
            }
            self.parentSubkeys = parentSubkeys

            if parentSubkey.typeInput == .array {
                self.valueKeyPath = parentSubkey.valueKeyPath + Constants.payloadKeyPathSeparator + "0"
            } else if parentSubkey.type == .dictionary, let grandparentSubkey = parentSubkey.parentSubkey, grandparentSubkey.typeInput == .array {
                if grandparentSubkey.rangeMax as? Int == 1 {
                    self.valueKeyPath = grandparentSubkey.valueKeyPath + Constants.payloadKeyPathSeparator + "0" + Constants.payloadKeyPathSeparator + self.key
                } else {
                    self.valueKeyPath = grandparentSubkey.valueKeyPath + Constants.payloadKeyPathSeparator + self.key
                }
            } else {
                self.valueKeyPath = parentSubkey.valueKeyPath + Constants.payloadKeyPathSeparator + self.key
            }
        } else {
            self.valueKeyPath = self.key
        }

        // KeyPath
        if let parentKeyPath = parentSubkey?.keyPath {
            self.keyPath = "\(parentKeyPath)\(Constants.payloadKeyPathSeparator)\(self.key)"
        } else {
            self.keyPath = self.key
        }

        // Not required itself, but dependency requires

        // Type Input
        if let typeInput = subkey[ManifestKey.typeInput.rawValue] as? String {
            let valueType = PayloadValueType(stringValue: typeInput)
            if valueType != .undefined {
                self.typeInput = valueType
                self.ignoredKeys.removeValue(forKey: ManifestKey.typeInput.rawValue)
            } else { self.typeInput = self.type }
        } else { self.typeInput = self.type }

        // Platforms Manifest
        if let platformsManifestArray = subkey[ManifestKey.platforms.rawValue] as? [String] {
            self.platformsManifest = PayloadUtility.platforms(fromArray: platformsManifestArray)
            self.ignoredKeys.removeValue(forKey: ManifestKey.platforms.rawValue)
        }

        // Platforms Not Manifest
        if let platformsNotManifestArray = subkey[ManifestKey.notPlatforms.rawValue] as? [String] {
            self.platformsNotManifest = PayloadUtility.platforms(fromArray: platformsNotManifestArray)
            self.ignoredKeys.removeValue(forKey: ManifestKey.notPlatforms.rawValue)
        }

        // Calculate actual platforms for subkey
        if let platformsManifest = self.platformsManifest {
            self.platforms = platformsManifest
        } else if let platformsNotManifest = self.platformsNotManifest {
            self.platforms = payload.platforms.subtracting(platformsNotManifest)
        } else {
            self.platforms = payload.platforms
        }

        // Hidden
        if let hidden = subkey[ManifestKey.hidden.rawValue] as? String {
            self.hidden = Hidden(keyValue: hidden)
            self.ignoredKeys.removeValue(forKey: ManifestKey.hidden.rawValue)
        } else {
            self.hidden = Hidden.no
        }

        // ---------------------------------------------------------------------
        //  Initialize optional variables
        // ---------------------------------------------------------------------
        for (key, element) in self.ignoredKeys {
            self.initialize(key: key, value: element, payload: payload)
        }

        // ---------------------------------------------------------------------
        //  If rangeList is not set, and both rangeMin and rangeMax is set and the range between them is less than 20, then create a range list for convenience
        // ---------------------------------------------------------------------
        if
            self.type == .integer,
            self.rangeList == nil,
            let rangeMin = self.rangeMin as? Int,
            let rangeMax = self.rangeMax as? Int,
            ((rangeMax - rangeMin) + 1) <= ProfilePayloads.rangeListConvertMax {
            var rangeList = [Any]()
            for value in rangeMin...rangeMax {
                rangeList.append(value)
            }
            self.rangeList = rangeList
        }

        // ---------------------------------------------------------------------
        //  If rangeList IS set, check if rangeListTitles are available and are the exact same length as the rangeList
        // ---------------------------------------------------------------------
        if let rangeListTitles = subkey[ManifestKey.rangeListTitles.rawValue] as? [String] {
            if let rangeList = self.rangeList {
                if rangeList.count == rangeListTitles.count {
                    self.rangeListTitles = rangeListTitles
                    self.ignoredKeys.removeValue(forKey: ManifestKey.rangeListTitles.rawValue)
                } else { Swift.print("Class: \(self.self), Function: \(#function), RangeListTitles and RangeList does not contain the same number of items, titles will be ignored.") }
            } else {
                self.rangeListTitles = rangeListTitles
                self.ignoredKeys.removeValue(forKey: ManifestKey.rangeListTitles.rawValue)
            }
        }

        // ---------------------------------------------------------------------
        //  Update Special Variables
        // ---------------------------------------------------------------------
        // isParentArrayOfDictionaries
        if let parentSubkeys = self.parentSubkeys {
            if Set(parentSubkeys.compactMap({ $0.type })).isSuperset(of: [PayloadValueType.array, PayloadValueType.dictionary]), let lastArray = parentSubkeys.reversed().first(where: { $0.type == PayloadValueType.array }) {
                // Ignore arrays of dictionaries that have the rangeMax key set to 1, as that will not be show as an array
                self.isParentArrayOfDictionaries = !(lastArray.rangeMax as? Int == 1)
            }
        }
    }

    private func initialize(key: String, value: Any?, payload: Payload) {
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

        // Allowed File Types
        case .allowedFileTypes:
            if let allowedFileTypes = value as? [String] {
                self.allowedFileTypes = allowedFileTypes
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type Array") }

        // Contains Any
        case .containsAny:
            if let containsAny = value as? [Any] {
                self.containsAny = containsAny
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type") }

        // Conditionals
        case .conditionals:
            if let conditionalsDicts = value as? [[String: Any]], let payload = self.payload {
                for conditionDict in conditionalsDicts {
                    if let condition = PayloadCondition(payload: payload, payloadSubkey: self, condition: conditionDict) {
                        self.conditionals.append(condition)
                    } else { Swift.print("Class: \(self.self), Function: \(#function), Failed to create a PayloadCondition from conditionDict: \(conditionDict)") }
                }
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type Array") }

        // Date Allow Past
        case .dateAllowPast:
            if let dateAllowPast = value as? Bool {
                self.dateAllowPast = dateAllowPast
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type Boolean") }

        // Date Style
        case .dateStyle:
            if let dateStyle = value as? String {
                self.dateStyle = DateStyle(keyValue: dateStyle)
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type String") }

        // Description
        case .description:
            if let description = value as? String {
                self.description = description.replacingOccurrences(of: "\\n", with: "\n")
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type String") }

        // Description Extended
        case .descriptionExtended:
            if let descriptionExtended = value as? String {
                self.descriptionExtended = descriptionExtended.replacingOccurrences(of: "\\n", with: "\n")
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type String") }

        // Description Reference
        case .descriptionReference:
            if let descriptionReference = value as? String {
                self.descriptionReference = descriptionReference.replacingOccurrences(of: "\\n", with: "\n")
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type String") }

        // Documentation Source
        case .documentationSource:
            if let documentationSource = value as? String {
                self.documentationSource = documentationSource
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type String") }

        // Documentation URL
        case .documentationURL:
            if let urlString = value as? String, let url = URL(string: urlString) {
                self.documentationURL = url
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type String") }

        // Enabled
        case .enabled:
            if let enabled = value as? Bool {
                self.enabledDefault = enabled
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type Bool") }

        // Exclude
        case .exclude:
            if let excludeDicts = value as? [[String: Any]], let payload = self.payload {
                for excludeDict in excludeDicts {
                    if let exclude = PayloadExclude(payload: payload, payloadSubkey: self, exclude: excludeDict) {
                        self.excludes.append(exclude)
                    }
                }
            }

        // Excluded
        case .excluded:
            if let excluded = value as? Bool {
                self.excluded = excluded
            }

        // Format
        case .format:
            if let format = value as? String {
                self.format = format
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type String") }

        // iOS Deprecated
        case .iOSDeprecated:
            if let iOSDeprecated = value as? String {
                self.iOSDeprecated = iOSDeprecated
                self.platformsDeprecated.insert(.iOS)
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type String") }

        // iOS Max
        case .iOSMax:
            if let iOSMax = value as? String {
                self.iOSMax = iOSMax
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type String") }

        // iOS Min
        case .iOSMin:
            if let iOSMin = value as? String {
                self.iOSMin = iOSMin
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type String") }

        // macOS Deprecated
        case .macOSDeprecated:
            if let macOSDeprecated = value as? String {
                self.macOSDeprecated = macOSDeprecated
                self.platformsDeprecated.insert(.macOS)
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type String") }

        // macOS Max
        case .macOSMax:
            if let macOSMax = value as? String {
                self.macOSMax = macOSMax
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type String") }

        // macOS Min
        case .macOSMin:
            if let macOSMin = value as? String {
                self.macOSMin = macOSMin
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type String") }

        // Note
        case .note:
            if let note = value as? String {
                self.note = note
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type String") }

        // Range List
        case .rangeList:
            // FIXME: There are probably more efficient methods to check that the array contains the payloads "Type"
            if let rangeList = value as? [Any], 0 == rangeList.filter({
                if self.type == .integer {
                    return PayloadUtility.valueType(value: Int(String(describing: $0))) != self.type
                } else if self.type == .float {
                    return PayloadUtility.valueType(value: Float(String(describing: $0))) != self.type
                } else {
                    return PayloadUtility.valueType(value: $0) != self.type
                }
            }).count {
                self.rangeList = rangeList
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type \(self.type)") }

        // Range List Allow
        case .rangeListAllowCustomValue:
            if let rangeListAllowCustomValue = value as? Bool {
                self.rangeListAllowCustomValue = rangeListAllowCustomValue
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type Bool") }

        // Require
        case .require, .required:
            if let requireString = value as? String {
                self.require = PayloadKeyRequire(keyValue: requireString)
            } else if let requireBool = value as? Bool, requireBool {
                self.require = .always
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type String or Bool") }

        // Repetition Max
        case .repetitionMax:
            if let repetitionMax = value as? Int {
                self.repetitionMax = repetitionMax
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type Int") }

        // Repetition Min
        case .repetitionMin:
            if let repetitionMin = value as? Int {
                self.repetitionMin = repetitionMin
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type Int") }

        // Segments
        case .segments:
            if let segments = value as? [String: [String]] {
                self.segments = segments
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type Dictionary") }

        // Sensitive
        case .sensitive:
            if let sensitive = value as? Bool {
                self.sensitive = sensitive
                self.sensitiveMessage = NSLocalizedString("This value is stored in the clear in the profile, it is recommended that the profile be encrypted for the device if it's not delivered by an MDM.", comment: "")
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type Bool") }

        // Substitution Variables
        case .substitutionVariables:
            if let substitutionVariables = value as? [String: [String: String]] {
                self.substitutionVariables = substitutionVariables
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type Dictionary") }

        // Supervised
        case .supervised:
            if let supervised = value as? Bool {
                self.supervised = supervised
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type Bool") }

        // Targets
        case .targets:
            if let targetsArray = value as? [String] {
                self.targets = PayloadUtility.targets(fromArray: targetsArray)
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type Array") }

        // Title
        case .title:
            if let title = value as? String {
                self.title = title
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type String") }

        // tvOS Deprecated
        case .tvOSDeprecated:
            if let tvOSDeprecated = value as? String {
                self.tvOSDeprecated = tvOSDeprecated
                self.platformsDeprecated.insert(.tvOS)
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type String") }

        // tvOS Max
        case .tvOSMax:
            if let tvOSMax = value as? String {
                self.tvOSMax = tvOSMax
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type String") }

        // tvOS Min
        case .tvOSMin:
            if let tvOSMin = value as? String {
                self.tvOSMin = tvOSMin
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type String") }

        // User Approved
        case .userApproved:
            if let userApproved = value as? Bool {
                self.userApproved = userApproved
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type Bool") }

        // Value Copy
        case .valueCopy:
            if let valueCopy = value as? String {
                self.valueCopy = valueCopy
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type String") }

        // Value Decimal Places
        case .valueDecimalPlaces:
            if let valueDecimalPlaces = value as? Int {
                self.valueDecimalPlaces = valueDecimalPlaces
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type Integer") }

        // Value Default
        case .valueDefault:
            if let valueDefault = value {
                self.valueDefault = valueDefault
            }

        // Value Default Copy
        case .valueDefaultCopy:
            if let valueDefaultCopy = value as? String {
                self.valueDefaultCopy = valueDefaultCopy
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type String") }

        // Value Max
        case .rangeMax:
            if let rangeMax = value {
                self.rangeMax = rangeMax
            }

        // Value Min
        case .rangeMin:
            if let rangeMin = value {
                self.rangeMin = rangeMin
            }

        // Value Inverted
        case .valueInverted:
            if let valueInverted = value as? Bool {
                self.valueInverted = valueInverted
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type Bool") }

        // Value Placeholder
        case .valuePlaceholder:
            if let valuePlaceholder = value {
                self.valuePlaceholder = valuePlaceholder
            }

        // Value Processor
        case .valueProcessor:
            if let valueProcessor = value as? String {
                self.valueProcessor = valueProcessor
            }

        // Value Info Processor
        case .valueInfoProcessor:
            if let valueInfoProcessor = value as? String {
                self.valueInfoProcessor = valueInfoProcessor
            }

        // Value Import Processor
        case .valueImportProcessor:
            if let valueImportProcessor = value as? String {
                self.valueImportProcessor = valueImportProcessor
            }

        // Value Unit
        case .valueUnit:
            if let valueUnit = value as? String {
                self.valueUnit = valueUnit
            }

        // Value Unique
        case .valueUnique:
            if let valueUnique = value as? Bool {
                self.valueUnique = valueUnique
            } else { Swift.print("Class: \(self.self), Function: \(#function), Value: \(String(describing: value)) for key: \(manifestKey) is not of expected type Bool") }

        // View
        case .view:
            if let view = value as? String {
                self.view = view
            }

        default:
            ignoreKey = true
        }

        if !ignoreKey {
            self.ignoredKeys.removeValue(forKey: key)
        }
    }
}
