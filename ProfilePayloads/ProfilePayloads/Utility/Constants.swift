//
//  Constants.swift
//  ProfilePayloads
//
//  Created by Erik Berglund.
//  Copyright © 2017 Erik Berglund. All rights reserved.
//

import Foundation

let kURLGitHubUserContent = "https://raw.githubusercontent.com"
let kURLGitHubRepositoryProfileManifests = "https://github.com/erikberglund/ProfileManifests"
let kURLGitHubRepositoryProfileManifestsContent = "https://raw.githubusercontent.com/erikberglund/ProfileManifests/master"
let kURLGitHubRepositoryProfileManifestsIndex = kURLGitHubRepositoryProfileManifestsContent + "/Manifests/index"

let kFormatVersionSupported = 5

public let kManifestDomainConfiguration = "Configuration"
public let kManifestDomainAppleRoot = "com.apple.security.root"
public let kManifestDomainApplePKCS1 = "com.apple.security.pkcs1"
public let kManifestDomainApplePEM = "com.apple.security.pem"
public let kManifestDomainAppleWiFi = "com.apple.wifi.managed"

public let kPayloadKeysIgnored = [""]
public let kPayloadKeyPrefixesIgnored = ["ABT_"]

public let kProfileSubkeys = [PayloadKey.payloadDescription,
                              PayloadKey.payloadDisplayName,
                              PayloadKey.payloadIdentifier,
                              PayloadKey.payloadType,
                              PayloadKey.payloadUUID,
                              PayloadKey.payloadScope,
                              PayloadKey.payloadVersion,
                              PayloadKey.payloadOrganization]

public let kPayloadSubkeys = [PayloadKey.payloadDescription,
                              PayloadKey.payloadDisplayName,
                              PayloadKey.payloadIdentifier,
                              PayloadKey.payloadType,
                              PayloadKey.payloadUUID,
                              PayloadKey.payloadVersion,
                              PayloadKey.payloadOrganization]

public let kPreferenceKeysIgnored = ["NSNavLastRootDirectory",
                                     "NSNavPanelExpandedSizeForOpenMode",
                                     "NSNavPanelExpandedSizeForSaveMode"]

public let kPreferenceKeyPrefixesIgnored = ["NSSplitView Subview Frames",
                                            "NSTableView Columns",
                                            "NSTableView Hidden",
                                            "NSTableView Sort",
                                            "NSTableView Supports",
                                            "NSToolbar Configuration",
                                            "NSWindow Frame"]

extension Notification.Name {
    static let manifestIndexUpdated = Notification.Name("manifestIndexUpdated")
}

struct NotificationKey {
    static let manifestIndexRepository = "manifestIndexRepository"
    static let manifestDownloadUpdates = "manifestDownloadUpdates"
}

public struct Constants {
    public init() {}

    public static let payloadKeyPathSeparator = "."
    public static let payloadKeyPathDomainSeparator = ":" // FIXME: Unused, might remove?
}

public enum PreferenceDomain: String {
    case unknown
    case library
    case libraryGlobal
    case userLibrary
    case userLibraryByHost
    case userLibraryGlobal
    case userLibraryGlobalByHost
    case userLibrarySynced
    case managed
}

public enum PayloadType: String {
    case all
    case manifestsApple
    case managedPreferencesApple
    case managedPreferencesApplications
    case managedPreferencesApplicationsLocal
    case managedPreferencesDeveloper
    case custom

    init(payloadTypeInt: PayloadTypeInt) {
        switch payloadTypeInt {
        case .all:
            self = .all
        case .manifestsApple:
            self = .manifestsApple
        case .managedPreferencesApple:
            self = .managedPreferencesApple
        case .managedPreferencesDeveloper:
            self = .managedPreferencesDeveloper
        case .managedPreferencesApplications:
            self = .managedPreferencesApplications
        case .managedPreferencesApplicationsLocal:
            self = .managedPreferencesApplicationsLocal
        case .custom:
            self = .custom
        }
    }

    public init?(int: Int) {
        guard let payloadTypeInt = PayloadTypeInt(rawValue: int) else { return nil }
        self = PayloadType(payloadTypeInt: payloadTypeInt)
    }
}

public enum PayloadTypeInt: Int {
    case all
    case manifestsApple
    case managedPreferencesApple
    case managedPreferencesApplications
    case managedPreferencesApplicationsLocal
    case managedPreferencesDeveloper
    case custom

    init(payloadType: PayloadType) {
        switch payloadType {
        case .all:
            self = .all
        case .manifestsApple:
            self = .manifestsApple
        case .managedPreferencesApple:
            self = .managedPreferencesApple
        case .managedPreferencesDeveloper:
            self = .managedPreferencesDeveloper
        case .managedPreferencesApplications:
            self = .managedPreferencesApplications
        case .managedPreferencesApplicationsLocal:
            self = .managedPreferencesApplicationsLocal
        case .custom:
            self = .custom
        }
    }
}

public enum ManagedPreferenceType: Int {
    case apple
    case application
    case applicationLocal
    case developer
}

enum PayloadFolderRoot {
    case applicationSupport
    case bundle
}

struct PayloadFolderName {
    static let managedPreferencesApple = "ManagedPreferencesApple"
    static let managedPreferencesApplications = "ManagedPreferencesApplications"
    static let managedPreferencesDeveloper = "ManagedPreferencesDeveloper"
    static let manifestsApple = "ManifestsApple"
}

public struct PayloadValueProcessorIdentifier {
    public static let hex2data = "hex2data"
    public static let base642data = "base642data"
    public static let designatedCodeRequirement2Data = "designatedCodeRequirement2Data"
    public static let plist2dict = "plist2dict"
    public static let weekdaysBitmask2Int = "weekdaysBitmask2Int"
    public static let time2minutes = "time2minutes"
    public static let x5002subjectArray = "x5002subjectArray"
    public static let dockTileType = "dockTileType"
    public static let dockTileLabel = "dockTileLabel"
    public static let dockTilePathType = "dockTilePathType"
}

// MARK: -
// MARK: Scope

public struct Targets: OptionSet {
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public init?(string: String) {
        switch string.lowercased() {
        case TargetString.system:
            self.rawValue = Targets.system.rawValue
        case TargetString.systemManaged:
            self.rawValue = Targets.systemManaged.rawValue
        case TargetString.user:
            self.rawValue = Targets.user.rawValue
        case TargetString.userManaged:
            self.rawValue = Targets.userManaged.rawValue
        default:
            return nil
        }
    }

    public let rawValue: Int
    public static let system = Targets(rawValue: 1 << 0)
    public static let systemManaged = Targets(rawValue: 1 << 1)
    public static let user = Targets(rawValue: 1 << 2)
    public static let userManaged = Targets(rawValue: 1 << 3)

    // IMPORTANT: Update all when adding more options
    public static let none: Targets = []
    public static let all: Targets = [.system, .systemManaged, user, userManaged]
}

public struct TargetString {
    public static let system = "system"
    public static let systemManaged = "system-managed"
    public static let user = "user"
    public static let userManaged = "user-managed"
}

// MARK: -
// MARK: Distribution

public struct Distribution: OptionSet {
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public init(string: String) {
        switch string.capitalized {
        case DistributionString.manual:
            self.rawValue = Distribution.manual.rawValue
        case DistributionString.push:
            self.rawValue = Distribution.push.rawValue
        case DistributionString.any:
            self.rawValue = Distribution.all.rawValue
        default:
            self.rawValue = Distribution.none.rawValue
        }
    }

    public let rawValue: Int
    public static let manual = Distribution(rawValue: 1 << 0)
    public static let push = Distribution(rawValue: 1 << 1)

    // IMPORTANT: Update all when adding more options
    public static let none: Distribution = []
    public static let all: Distribution = [.manual, .push]
}

public struct DistributionString {
    public static let any = "Any"
    public static let manual = "Manual"
    public static let push = "Push"
}

// MARK: -
// MARK: Platform

public struct Platforms: OptionSet {
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public let rawValue: Int
    public static let macOS = Platforms(rawValue: 1 << 0)
    public static let iOS = Platforms(rawValue: 1 << 1)
    public static let tvOS = Platforms(rawValue: 1 << 2)

    // IMPORTANT: Update all when adding more options
    public static let none: Platforms = []
    public static let all: Platforms = [.macOS, .iOS, tvOS]
}

public struct PlatformString {
    public static let macOS = "macOS"
    public static let iOS = "iOS"
    public static let tvOS = "tvOS"
}

public enum DateStyle: String {
    case dateAndTime
    case time

    init(keyValue: String) {
        self = DateStyle(rawValue: keyValue) ?? .dateAndTime
    }
}

public enum Hidden: String {
    case no
    case all
    case container

    init(keyValue: String) {
        self = Hidden(rawValue: keyValue) ?? .no
    }
}

// MARK: -
// MARK: Interaction

public enum Interaction: String {
    case combined
    case exclusive
    case undefined

    init(keyValue: String) {
        self = Interaction(rawValue: keyValue) ?? .undefined
    }
}

public struct PayloadKey {
    public init() {}

    public static let consentText = "ConsentText"
    public static let durationUntilRemoval = "DurationUntilRemoval"
    public static let mcxPreferenceSettings = "mcx_preference_settings"
    public static let payloadContent = "PayloadContent"
    public static let payloadDescription = "PayloadDescription"
    public static let payloadDisplayName = "PayloadDisplayName"
    public static let payloadEnabled = "PayloadEnabled" // Custom key
    public static let payloadExpirationDate = "PayloadExpirationDate"
    public static let payloadIdentifier = "PayloadIdentifier"
    public static let payloadOrganization = "PayloadOrganization"
    public static let payloadRemovalDisallowed = "PayloadRemovalDisallowed"
    public static let payloadScope = "PayloadScope"
    public static let payloadType = "PayloadType"
    public static let payloadUUID = "PayloadUUID"
    public static let payloadVersion = "PayloadVersion"
    public static let removalDate = "RemovalDate"
}

// FIXME: Terrible name, need to change to something more fitting
public struct ManifestKeyPlaceholder {
    public init() {}

    public static let key = "{{key}}"
    public static let value = "{{value}}"
    public static let type = "{{type}}"
}

public enum PayloadKeyRequire: String {
    case never = "never" // This doesn't exist in the manifests, it's just a default state if nothing is set in the manifest
    case always = "always"
    case alwaysNested = "always-nested"
    case push = "push"

    init(keyValue: String) {
        self = PayloadKeyRequire(rawValue: keyValue) ?? .never
    }
}

public enum PayloadValueType: String {
    case undefined = "Unknown" // Unsure about this name. In the case that it's either unknown, somethings not supported or can't figure out
    case array = "Array"
    case bool = "Boolean"
    case date = "Date"
    case data = "Data"
    case dictionary = "Dictionary"
    case float = "Float"
    case integer = "Integer"
    case string = "String"

    init(stringValue: String) {
        if stringValue.capitalized == "Real" {
            self = .float
        } else {
            self = PayloadValueType(rawValue: stringValue.capitalized) ?? .undefined
        }
    }
}

public enum ManifestKey: String {

    //*
    // Apple Preference Manifest Keys
    //*

    /**
     **Array of Dictionaries**

     Indicates the conditions whether this key should be required.
     */
    case conditionals = "pfm_conditionals"

    /**
     **Array**

     *Important*: The array must be of the same type as the target key's `pfm_type`.

     Evaluates whether the target key value is set to any values from this key.

     _Note_: Only available in `pfm_target_conditions` dictionaries.
     */
    case containsAny = "pfm_contains_any"

    /**
     **String**

     Description of the key or payload.
     */
    case description = "pfm_description"

    /**
     **String**

     Domain of the payload.
     */
    case domain = "pfm_domain"

    /**
     **String**

     Indicates the conditions whether this key should be included in the payload.
     */
    case exclude = "pfm_exclude"

    /**
     **String**

     A regular expression that the value must match.
     */
    case format = "pfm_format"

    /**
     **Integer**

     The preference manifest format version.
     */
    case formatVersion = "pfm_format_version"

    /**
     **Bool**

     Evaluates whether the target key exists in the exported payload.

     _Note_: Only available in `pfm_target_conditions` dictionaries.
     */
    case isPresent = "pfm_present"

    /**
     **String**

     The name of the key.
     */
    case name = "pfm_name"

    /**
     **Array**

     *Important*: The array must be of the same type as the target key's `pfm_type`.

     Evaluates whether the target key value is NOT set to any value from this key.

     _Note_: Only available in `pfm_target_conditions` dictionaries.
     */
    case notContainsAny = "pfm_n_contains_any"

    /**
     **Array**

     *Important*: The array must be of the same type as the target key's `pfm_type`.

     Evaluates whether the target key value does NOT match the value of this key.

     _Note_: Only available in `pfm_target_conditions` dictionaries.
     */
    case notRangeList = "pfm_n_range_list"

    /**
     **Array**

     *Important*: The array must be of the same type as the target key's `pfm_type`.

     An array of legal values for this key.

     _Note_: When used in `pfm_conditionals` dictionaries:

     -  Evaluates whether the target key value matches the value of this key.
     */
    case rangeList = "pfm_range_list"

    /**
     **Any**

     *Important*: Must be the same type as the key's `pfm_type`.

     The maximum value for this key.
     */
    case rangeMax = "pfm_range_max"

    /**
     **Any**

     *Important*: Must be the same type as the key's `pfm_type`.

     The minimum value for this key.
     */
    case rangeMin = "pfm_range_min"

    /**
     **Integer**

     The maximum number of items allowed in an array.
     */
    case repetitionMax = "pfm_repetition_max"

    /**
     **Integer**

     The minimum number of items allowed in an array.
     */
    case repetitionMin = "pfm_repetition_min"

    /**
     **String**

     Indicates whether this key is required to be present in the payload.

     Supported values:

     - always = The key is always required
     - always-nested = The key is always required even if it is in a nested dictionary
     - push = The key is only required when installed via an MDM
     */
    case require = "pfm_require"

    /**
     **Bool**

     Indicates whether this key is required to be present in the payload.

     If set to `true` it's equal to `pfm_require=always`.
     */
    case required = "pfm_required"

    /**
     **Array of Dictionaries**

     This key describes keys nested under the current key.
     */
    case subkeys = "pfm_subkeys"

    /**
     **String**

     The target key to evaluate. For nested keys the key names can be separated by a dot "."

     _Note_: Only available in `pfm_target_conditions` dictionaries.
     */
    case target = "pfm_target"

    /**
     **Array of Dictionaries**

     Specifies conditions that this key has a dependency with.

     _Note_: Only available in `pfm_conditionals` dictionaries.
     */
    case targetConditions = "pfm_target_conditions"

    /**
     **Array of Strings**

     The scope where the key or payload is valid.

     Supported values:

     - user
     - user-managed
     - system
     - system-managed
     */
    case targets = "pfm_targets"

    /**
     **String**

     The title of the key or payload.
     */
    case title = "pfm_title"

    /**
     **String**

     The data type of the value for this key.
     */
    case type = "pfm_type"

    /**
     **Any**

     *Important*: Must be the same type as the key's `pfm_type`.

     The key's default value.
     */
    case valueDefault = "pfm_default"

    /**
     **Integer**

     Version of the manifest file.
     */
    case version = "pfm_version"

    //*
    //*
    //*
    //*
    // Extended Manifest Format Keys
    //*
    //*
    //*
    //*

    /**
     **Array of Strings**

     File extensions or UTIs allowed when using a file as value for a `Data` key.
     */
    case allowedFileTypes = "pfm_allowed_file_types"

    /**
     **String**

     Version of the Application that started deprecating the key or payload
     */
    case appDeprecated = "pfm_app_deprecated"

    /**
     **String**

     Version of the Application that started supporting the key or payload
     */
    case appMax = "pfm_app_max"

    /**
     **String**

     Version of the Application that stopped supporting the key or payload.
     */
    case appMin = "pfm_app_min"

    /**
     **String**

     URL to the Application homepage.
     */
    case appURL = "pfm_app_url"

    /**
     **String**

     Extended description of the key or payload.
     */
    case descriptionExtended = "pfm_description_extended"

    /**
     **String**

     Reference description of the key or payload.
     */
    case descriptionReference = "pfm_description_reference"

    /**
     **String**

     The style of the datepicker.

     Supported values:

     - dateAndTime (default)
     - time
     */
    case dateStyle = "pfm_date_style"

    /**
     **Boolean**
     
     Determines if the datepicker should allow selecting past dates.
     */
    case dateAllowPast = "pfm_date_allow_past"

    /**
     **Array of Strings**

     The distribution method supported for the key or payload.

     Supported values:
     
     - manual
     - push
     */
    case distribution = "pfm_distribution"

    /**
     **String**

     URL to additional documentation for the key or payload.
     */
    case documentationURL = "pfm_documentation_url"

    /**
     **String**

     Information about where the information for this key was found.
     Note: Only used when the information was NOT found in Apple's profile documentation.
     */
    case documentationSource = "pfm_documentation_source"

    /**
     **Bool**

     If the key should be included in the payload content by default.
     */
    case enabled = "pfm_enabled"

    /**
     **Bool**

     If the key should be excluded from the exported payload.
     */
    case excluded = "pfm_excluded"

    /**
     **String**

     If the key or container should be hidden from the user by default.

     Supported values:

     - all
     - container
     */
    case hidden = "pfm_hidden"

    /**
     **Data**

     Bsse64 encoded data of an image resource in 64x64 pixels.
     */
    case icon = "pfm_icon"

    /**
     **String**

     How payload settings will interact when multiple payloads of the same type are installed on a device.

     Supported values:

     - combined
     - exclusive
     - undefined

     More Information under "Interaction": https://help.apple.com/deployment/mdm/#/mdm5370d089
     */
    case interaction = "pfm_interaction"

    /**
     **String**

     Version of iOS that started deprecating the key or payload.
     */
    case iOSDeprecated = "pfm_ios_deprecated"

    /**
     **String**

     Version of iOS that stopped supporting the key or payload.
     */
    case iOSMax = "pfm_ios_max"

    /**
     **String**

     Version of iOS that started supporting the key or payload.
     */
    case iOSMin = "pfm_ios_min"

    /**
     **Bool**

     Evaluates whether the target key has an empty value in the exported payload.

     _Note_: Only available in `pfm_target_conditions` dictionaries.
     */
    case isEmpty = "pfm_value_empty"

    /**
     **Date**

     Date the manifest file was last modified.
     */
    case lastModified = "pfm_last_modified"

    /**
     **String**

     Version of macOS that started deprecating the key or payload.
     */
    case macOSDeprecated = "pfm_macos_deprecated"

    /**
     **String**

     Version of macOS that stopped supporting the key or payload.
     */
    case macOSMax = "pfm_macos_max"

    /**
     **String**

     Version of macOS that started supporting the key or payload.
     */
    case macOSMin = "pfm_macos_min"

    /**
     **String**

     A note to emphasize or bring something specific to the user's attention about the key.
     */
    case note = "pfm_note"

    /**
     **Array of Strings**

     Platforms that don't support the key or payload.
     */
    case notPlatforms = "pfm_n_platforms"

    /**
     **Array of Strings**

     Platforms that support the key or payload.
     */
    case platforms = "pfm_platforms"

    /**
     **String**

     NOTE: Only internal, not set in manifest file. Domain where the current key/value was set in.
     */
    case preferenceDomain = "pfm_preference_domain"

    /**
     **Bool**
     
     Allow the user to provide custom value for a range list.
     */
    case rangeListAllowCustomValue = "pfm_range_list_allow_custom_value"

    /**
     **Array of Strings**

     Titles matching the values in the `pfm_range_list` key.

     **Important**: If this key is used together with `pfm_range_list` it must contain equal number of items.

     _ProfileCreator_: This key can be used to show a radio button to represent a boolean value if the following is true:
     * The key `pfm_type` is set to `boolean`
     * No `pfm_range_list` is set.
     * This key contains exactly 2 values.
     */
    case rangeListTitles = "pfm_range_list_titles"

    /**
     **Dictionary of Arrays of Strings**

     _ProfileCreator_: This key can be used show a segmented control:

     * The keys in the dictionary will be set as the segment titles.
     * The value is an array of strings where each string is the KeyPath for each key to show under the selected segment.
     */
    case segments = "pfm_segments"

    /**
     **Bool**

     Indication that the value for this key might be sensitive and that encrypting the profile might be neccessary to protect the value.
     */
    case sensitive = "pfm_sensitive"

    /**
     **String**

     Unique identifier used to allow a domain to be separated into separate files.
     */
    case subdomain = "pfm_subdomain"

    /**
     **Bool**

     Requires the device to be supervised for this key or payload to work.
     */
    case supervised = "pfm_supervised"

    /**
     **String**

     _ProfileCreator_: The data type of the input value for this key.

     This is used when it makes sense for the user to input another value type than the `pfm_type` specifies.

     See also: `pfm_value_processor`
     */
    case typeInput = "pfm_type_input"

    /**
     **String**

     Version of tvOS that started deprecating the key or payload.
     */
    case tvOSDeprecated = "pfm_tvos_deprecated"

    /**
     **String**

     Version of tvOS that stopped supporting the key or payload.
     */
    case tvOSMax = "pfm_tvos_max"

    /**
     **String**

     Version of tvOS that started supporting the key or payload.
     */
    case tvOSMin = "pfm_tvos_min"

    /**
     **Bool**

     Indicates if multiple payloads of this type can be installed on a device.

     More Information under "Duplicates": https://help.apple.com/deployment/mdm/#/mdm5370d089
     */
    case unique = "pfm_unique" // To tell if there can be multiple instances of this payload domain

    /**
     **Bool**

     Requires the device to be user approved, or enrolled using DEP for this key or payload to work.

     _Note_: macOS only
     */
    case userApproved = "pfm_user_approved"

    /**
     **String**

     KeyPath to another key which value to copy as the value for this key.

     _Note_: This will disable user input for this key.
     */
    case valueCopy = "pfm_value_copy"

    /**
     **String**

     KeyPath to another key which value to copy as the default for this key.
     */
    case valueDefaultCopy = "pfm_default_copy"

    /**
     **Dictionary**

     Dictionary with key/value where key is the variable and the string value is the description of the variable.
     */
    case substitutionVariables = "pfm_substitution_variables"

    /**
     **String**

     Source of the substitution variable.

     Supported values are: local, mdm
     */
    case substitutionSource = "pfm_substitution_source"

    /**
     **Integer**
     
     Number of decimal places to be used when setting and exporting the value.
     */
    case valueDecimalPlaces = "pfm_value_decimal_places"

    /**
     **Bool**

     Only available for `pfm_type`: `boolean`.

     Indicates that the user entered value should be inverted.

     This key is used when the `pfm_title` or `pfm_description` is worded in such a way that the value must be inverted to work as expected for the key.
     */
    case valueInverted = "pfm_value_inverted"

    /**
     **Any**

     Placeholder value for the key.

     Placeholder value is never included in the exported payload, it's only used to show an example value.
     */
    case valuePlaceholder = "pfm_value_placeholder"

    /**
     **String**

     Name of the value processor to use when converting a user entered value.

     See also: `pfm_type_input`.
     */
    case valueProcessor = "pfm_value_processor"

    /**
     **String**

     Name of the value info processor to use when displaying the information for a `Data` value.
     */
    case valueInfoProcessor = "pfm_value_info_processor"

    /**
     **String**

     Name of the value import processor to use when converting an item dropped on the cellview to valid settings.

     See also: `pfm_allowed_file_types`.
     */
    case valueImportProcessor = "pfm_value_import_processor"

    /**
     **String**

     Unit that the value represents.

     Example: milliseconds, hours, characters etc.
     */
    case valueUnit = "pfm_value_unit"

    /**
     **Bool**
     
     Require all values in an array to be unique.
     */
    case valueUnique = "pfm_value_unique"

    /**
     **String**
     
     _ProfileCreator_: The view used to represent the payload key.
     */
    case view = "pfm_view"

}
