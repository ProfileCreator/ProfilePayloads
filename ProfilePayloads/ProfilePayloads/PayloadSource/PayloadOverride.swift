//
//  PayloadOverride.swift
//  ProfilePayloads
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation

class PayloadOverrides {

    static func overrideManifestURL(forDomain domain: String, paylaodType: PayloadType) -> URL? {
        guard let overridesFolderURL = applicationFolder(root: .applicationSupport, payloadType: paylaodType, manifestType: .manifestOverrides) else {
            return nil
        }
        return overridesFolderURL.appendingPathComponent(domain).appendingPathExtension("plist")
    }

    static func overrideManifest(forDomain domain: String, payloadType: PayloadType) -> [String: Any]? {
        guard
            let overrideManifestURL = self.overrideManifestURL(forDomain: domain, paylaodType: payloadType),
            let overrideManifestData = try? Data(contentsOf: overrideManifestURL),
            let overrideManifest = manifest(fromData: overrideManifestData) else {
                return nil
        }
        return overrideManifest
    }

    static func addOverrides(forDomain domain: String, payloadType: PayloadType, sourceManifest: [String: Any]) -> [String: Any] {

        guard let overrideManifest = self.overrideManifest(forDomain: domain, payloadType: payloadType) else {
            return sourceManifest
        }

        return self.mergeDictionaries(source: sourceManifest, override: overrideManifest)
    }

    static func mergeDictionaries(source sourceDict: [String: Any], override overrideDict: [String: Any]) -> [String: Any] {
        return sourceDict.merging(overrideDict) { source, override -> Any in
            switch PayloadUtility.valueType(value: source) {
            case .array:
                guard
                    let sourceArray = source as? [Any],
                    let overrideArray = override as? [Any] else {
                        return source
                }
                return self.mergeArrays(source: sourceArray, override: overrideArray)
            case .dictionary:
                guard
                    let sourceDict = source as? [String: Any],
                    let overrideDict = override as? [String: Any] else {
                        return source
                }
                return self.mergeDictionaries(source: sourceDict, override: overrideDict)
            default:
                return override
            }
        }
    }

    static func mergeArrays(source sourceArray: [Any], override overrideArray: [Any]) -> [Any] {

        guard let sourceItem = sourceArray.first else {
            return overrideArray
        }

        switch PayloadUtility.valueType(value: sourceItem) {
        case .array:

            // Unsure if there is a good way to go through each array of arrays?
            // For now just return the override, but this might need solving, at least for array of arrays that only has one contained in the other.
            return overrideArray
        case .dictionary:
            var mergedArray = [Any]()
            guard
                let sourceArrayDict = sourceArray as? [[String: Any]],
                var overrideArrayDict = overrideArray as? [[String: Any]] else {
                    Swift.print("Failed to cast array content to Dictionary")
                    return sourceArray
            }

            for dict in sourceArrayDict {
                guard let key = dict[ManifestKey.name.rawValue] as? String else { continue }
                if let overrideDictIndex = overrideArrayDict.firstIndex(where: { $0[ManifestKey.name.rawValue] as? String == key }) {
                    let overrideDict = overrideArrayDict[overrideDictIndex]
                    let mergedDict = self.mergeDictionaries(source: dict, override: overrideDict)
                    mergedArray.append(mergedDict)
                    overrideArrayDict.remove(at: overrideDictIndex)
                } else {
                    mergedArray.append(dict)
                }
            }

            mergedArray.append(contentsOf: overrideArrayDict)

            return mergedArray
        default:
            return overrideArray
        }
    }

}
