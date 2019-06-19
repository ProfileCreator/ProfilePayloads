//
//  Utility.swift
//  ProfilePayloads
//
//  Created by Erik Berglund.
//  Copyright © 2017 Erik Berglund. All rights reserved.
//

import Foundation

public class PayloadUtility {

    // FIXME: This REALLY needs cleanup.

    public class func expandKeyPath(_ keyPath: String, withRootKeyPath rootKeyPath: String) -> String {

        var newKeyPath = ""
        var tmpKeyPath2 = keyPath.components(separatedBy: ".")

        for key in rootKeyPath.components(separatedBy: ".") {
            if key.isNumber {
                newKeyPath.append(".\(key)")
                if let newKey = tmpKeyPath2.first, newKey.isNumber {
                    tmpKeyPath2.remove(at: 0)
                }
            } else if let tmpKey2 = tmpKeyPath2.first, key == tmpKey2 {
                newKeyPath.append("\(newKeyPath.isEmpty ? "" : ".")\(key)")
                tmpKeyPath2.remove(at: 0)
            }
        }

        if tmpKeyPath2.isEmpty {
            return newKeyPath
        } else {
            return newKeyPath + "." + tmpKeyPath2.joined(separator: ".")
        }
    }

    public class func profilePayloadsCacheFolder() -> URL? {
        guard let bundleIdentifier = Bundle(for: self).bundleIdentifier else { return nil }
        let profilePayloadsCacheFolder: URL
        do {
            let cacheFolder = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            profilePayloadsCacheFolder = cacheFolder.appendingPathComponent(bundleIdentifier)
        } catch {
            Swift.print(error)
            return nil
        }

        do {
            try FileManager.default.createDirectory(at: profilePayloadsCacheFolder, withIntermediateDirectories: false, attributes: nil)
        } catch let error as NSError {
            if error.code != 516 {
                Swift.print(error)
                return nil
            }
        }

        return profilePayloadsCacheFolder
    }

    public class func profilePayloadsCacheIndex(forType type: ManifestRepositoryType) -> URL? {
        if let cacheFolder = self.profilePayloadsCacheFolder() {
            switch type {
            case .manifests:
                return cacheFolder.appendingPathComponent("indexManifests")
            case .icons:
                return cacheFolder.appendingPathComponent("indexIcons")
            case .manifestOverrides,
                 .iconOverrides:
                return nil
            }
        }
        return nil
    }

    public class func valueType(value: Any?) -> PayloadValueType {
        if value is String {
            return PayloadValueType.string
        } else if value is Bool && String(cString: object_getClassName(value)) == "__NSCFBoolean" {
            return PayloadValueType.bool
        } else if value is Int { // This needs to be checked before Float and Double, as even numbers might be mistaken for either. Might be true the other way around aswell, need more testing
            return PayloadValueType.integer
        } else if value is Float || value is Double {
            return PayloadValueType.float
        } else if value is [Any] {
            return PayloadValueType.array
        } else if value is Date {
            return PayloadValueType.date
        } else if value is Data {
            return PayloadValueType.data
        } else if value is NSDictionary || value is [String: AnyHashable] || (value as? [String: Any]) != nil {
            return PayloadValueType.dictionary
        } else if String(cString: object_getClassName(value)) == "__NSCFNumber", let valueNumber = value as? NSNumber {
            if CFNumberIsFloatType(valueNumber) {
                return PayloadValueType.float
            } else {
                return PayloadValueType.integer
            }
        } else {
            //Swift.print("Class: \(self.self), Function: \(#function), Unknown Value Type: \(Swift.type(of: value))")
            //Swift.print("String(cString: object_getClassName(value)): \(String(cString: object_getClassName(value)))")
            return PayloadValueType.undefined
        }
    }

    public class func valueType(value: Any?, type: PayloadValueType) -> PayloadValueType {
        switch type {
        case .array:
            if value is [Any] { return PayloadValueType.array }
        case .bool:
            if value is Bool { return PayloadValueType.bool }
        case .data:
            if value is Data { return PayloadValueType.data }
        case .date:
            if value is Date { return PayloadValueType.date }
        case .dictionary:
            if value is [String: AnyHashable] || (value as? [String: Any]) != nil { return PayloadValueType.dictionary }
        case .float:
            if value is Float || value is Double { return PayloadValueType.float }
        case .integer:
            if value is Int { return PayloadValueType.integer }
        case .string:
            if value is String { return PayloadValueType.string }
        case .undefined:
            return PayloadUtility.valueType(value: value)
        }

        Swift.print("Class: \(self.self), Function: \(#function), Unknown Type: \(Swift.type(of: value)), Expected Type: \(type)")
        return PayloadValueType.undefined
    }

    public class func value(string: String, type: PayloadValueType) -> Any? {
        switch type {
        case .float:
            if let valueFloat = Float(string) { return valueFloat }
        case .integer:
            if let valueInt = Int(string) { return valueInt }
        case .string:
            return string
        case .undefined:
            return nil
        default:
            Swift.print("Class: \(self.self), Function: \(#function), Unknown Type: \(type)")
        }

        return nil
    }

    public class func emptyValue(valueType: PayloadValueType) -> Any? {
        switch valueType {
        case .array:
            return []
        case .bool:
            return false
        case .data:
            return Data()
        case .date:
            return Date()
        case .dictionary:
            return [String: Any]()
        case .float:
            return Float(0)
        case .integer:
            return Int(0)
        case .string:
            return String()
        case .undefined:
            return nil
        }
    }

    public class func valueIsEmpty(_ value: Any, valueType: PayloadValueType) -> Bool {
        switch self.valueType(value: value, type: valueType) {
        case .array:
            if let arrayValue = value as? [Any] {
                return arrayValue.isEmpty
            }
        case .bool:
            return !(value is Bool)
        case .data:
            if let dataValue = value as? Data {
                return dataValue.isEmpty
            }
        case .date:
            return !(value is Date)
        case .dictionary:
            if let dictionaryValue = value as? [String: Any] {
                return dictionaryValue.isEmpty
            }
        case .float:
            return !(value is Float) || !(value is Double)
        case .integer:
            return !(value is Int)
        case .string:
            if let stringValue = value as? String {
                return stringValue.isEmpty
            }
        case .undefined:
            return false
        }
        return true
    }

    // MARK: -
    // MARK: RangeList Title/Value

    public class func value(forRangeListTitle title: String, subkey: PayloadSubkey) -> Any? {
        if let rangeList = subkey.rangeList {
            if
                let rangeListTitles = subkey.rangeListTitles,
                let titleIndex = rangeListTitles.index(of: title),
                titleIndex < rangeList.count {
                return rangeList[titleIndex]
            }
        }
        return self.value(string: title, type: subkey.type)
    }

    public class func title(forRangeListValue value: Any, subkey: PayloadSubkey) -> String? {
        switch subkey.type {
        case .bool:
            if let rangeList = subkey.rangeList as? [Bool], let boolValue = value as? Bool {
                if let rangeListTitles = subkey.rangeListTitles, let index = rangeList.index(of: boolValue), index < rangeListTitles.count {
                    return rangeListTitles[index]
                } else {
                    return String(describing: boolValue)
                }
            }
        case .date:
            if let rangeList = subkey.rangeList as? [Date], let dateValue = value as? Date {
                if let rangeListTitles = subkey.rangeListTitles, let index = rangeList.index(of: dateValue), index < rangeListTitles.count {
                    return rangeListTitles[index]
                } else {
                    return String(describing: dateValue)
                }
            }
        case .data:
            if let rangeList = subkey.rangeList as? [Data], let dataValue = value as? Data {
                if let rangeListTitles = subkey.rangeListTitles, let index = rangeList.index(of: dataValue), index < rangeListTitles.count {
                    return rangeListTitles[index]
                } else {
                    return String(describing: dataValue)
                }
            }
        case .string:
            if let rangeList = subkey.rangeList as? [String], let stringValue = value as? String {
                if let rangeListTitles = subkey.rangeListTitles, let index = rangeList.index(of: stringValue), index < rangeListTitles.count {
                    return rangeListTitles[index]
                } else {
                    return String(describing: stringValue)
                }
            }
        case .integer:
            if let rangeList = subkey.rangeList as? [Int], let intValue = value as? Int {
                if let rangeListTitles = subkey.rangeListTitles, let index = rangeList.index(of: intValue), index < rangeListTitles.count {
                    return rangeListTitles[index]
                } else {
                    return String(describing: intValue)
                }
            }
        case .float:
            if let rangeList = subkey.rangeList as? [Float], let floatValue = value as? Float {
                if let rangeListTitles = subkey.rangeListTitles, let index = rangeList.index(of: floatValue), index < rangeListTitles.count {
                    return rangeListTitles[index]
                } else {
                    return String(describing: floatValue)
                }
            } else if let rangeList = subkey.rangeList as? [Double], let doubleValue = value as? Double {
                if let rangeListTitles = subkey.rangeListTitles, let index = rangeList.index(of: doubleValue), index < rangeListTitles.count {
                    return rangeListTitles[index]
                } else {
                    return String(describing: doubleValue)
                }
            }
        default:
            Swift.print("Class: \(self.self), Function: \(#function), Value Type: \(String(describing: subkey.type)) is not currently supported")
        }

        return String(describing: value)
    }

    // MARK: -
    // MARK: Distribution

    public class func distribution(fromArray: [String]) -> Distribution {
        var distribution: Distribution = []
        for distributionString in fromArray {
            switch distributionString.capitalized { // FIXME: This is again terrible, to have to remember to capitalize. Must fix.
            case DistributionString.manual:
                distribution.insert(.manual)
            case DistributionString.push:
                distribution.insert(.push)
            default:
                Swift.print("Unknown distribution string: \(distributionString)")
            }
        }
        return distribution
    }

    public class func string(fromDistribution distribution: Distribution, separator: String) -> String {
        return self.strings(fromDistribution: distribution).joined(separator: separator)
    }

    public class func strings(fromDistribution distribution: Distribution) -> [String] {
        var distributionStrings = [String]()
        if distribution.contains(.manual) {
            distributionStrings.append(DistributionString.manual)
        }
        if distribution.contains(.push) {
            distributionStrings.append(DistributionString.push)
        }
        return distributionStrings
    }

    // MARK: -
    // MARK: Platform

    public class func platforms(fromArray: [String]) -> Platforms {
        var platforms: Platforms = []
        for platformString in fromArray {
            switch platformString {
            case PlatformString.macOS:
                platforms.insert(.macOS)
            case PlatformString.iOS:
                platforms.insert(.iOS)
            case PlatformString.tvOS:
                platforms.insert(.tvOS)
            default:
                Swift.print("Unknown platform string: \(platformString)")
            }
        }
        return platforms
    }

    public class func string(fromPlatforms platforms: Platforms, separator: String) -> String {
        return self.strings(fromPlatforms: platforms).joined(separator: separator)
    }

    public class func strings(fromPlatforms platforms: Platforms) -> [String] {
        var platformStrings = [String]()
        if platforms.contains(.macOS) {
            platformStrings.append(PlatformString.macOS)
        }
        if platforms.contains(.iOS) {
            platformStrings.append(PlatformString.iOS)
        }
        if platforms.contains(.tvOS) {
            platformStrings.append(PlatformString.tvOS)
        }
        return platformStrings
    }

    // MARK: -
    // MARK: Targets

    public class func targets(fromArray: [String]) -> Targets {
        var targets: Targets = []
        for targetString in fromArray {
            switch targetString {
            case TargetString.system:
                targets.insert(.system)
            case TargetString.systemManaged:
                targets.insert(.systemManaged)
            case TargetString.user:
                targets.insert(.user)
            case TargetString.userManaged:
                targets.insert(.userManaged)
            default:
                Swift.print("Unknown target string: \(targetString)")
            }
        }
        return targets
    }

    public class func string(fromTargets targets: Targets, separator: String) -> String {
        return self.strings(fromTargets: targets).joined(separator: separator)
    }

    public class func strings(fromTargets targets: Targets) -> [String] {
        var targetStrings = [String]()
        if targets.contains(.user) {
            targetStrings.append(TargetString.user.capitalized)
        }
        if targets.contains(.system) {
            targetStrings.append(TargetString.system.capitalized)
        }
        return targetStrings
    }
}
