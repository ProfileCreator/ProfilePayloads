//
//  AppResources.swift
//  ProfilePayloads
//
//  Created by Erik Berglund.
//  Copyright © 2017 Erik Berglund. All rights reserved.
//

import Foundation

func manifest(fromData data: Data) -> [String: Any]? {

    // Specify the PropertyListFormat to use
    var format = PropertyListSerialization.PropertyListFormat.xml

    do {
        return try PropertyListSerialization.propertyList(from: data, options: .mutableContainersAndLeaves, format: &format) as? [String: Any]
    } catch {
        // FIXME: Proper logging
        print("Function: \(#function), Error: \(error)")
        return nil
    }
}

func applicationFolderName(forType type: PayloadType) -> String {
    switch type {
    case .managedPreferencesApple:
        return PayloadFolderName.managedPreferencesApple
    case .manifestsApple:
        return PayloadFolderName.manifestsApple
    case .managedPreferencesApplications:
        return PayloadFolderName.managedPreferencesApplications
    case .managedPreferencesDeveloper:
        return PayloadFolderName.managedPreferencesDeveloper
    case .managedPreferencesApplicationsLocal:
        return "Preferences"
    case .all,
         .custom:
        Swift.print("Unhandled payload type: \(type)")
        return ""
    }
}

public func payloadType(forString string: String) -> PayloadType? {
    switch string {
    case PayloadFolderName.manifestsApple:
        return .manifestsApple
    case PayloadFolderName.managedPreferencesApple:
        return .managedPreferencesApple
    case PayloadFolderName.managedPreferencesApplications:
        return .managedPreferencesApplications
    case PayloadFolderName.managedPreferencesDeveloper:
        return .managedPreferencesDeveloper
    default:
        Swift.print("Unknown source type string: \(string)")
    }
    return nil
}

func manifestType(forString string: String) -> ManifestRepositoryType? {
    switch string.capitalized {
    case "Manifests":
        return .manifests
    case "Icons":
        return .icons
    default:
        Swift.print("Unknown manifest type string: \(string)")
    }
    return nil
}

func applicationFolder(root: PayloadFolderRoot, payloadType: PayloadType, manifestType: ManifestRepositoryType) -> URL? {

    // Get Root Folder
    let rootFolderURL: URL
    switch root {
    case .applicationSupport:
        do {
            let userApplicationSupport = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            rootFolderURL = userApplicationSupport.appendingPathComponent("ProfilePayloads", isDirectory: true)
        } catch {
            print("Function: \(#function), Error: \(error)")
            return nil
        }
    case .bundle:
        rootFolderURL = Bundle(for: ProfilePayloads.self).bundleURL.appendingPathComponent("Resources", isDirectory: true)
    }

    let manifestFolderName: String
    switch manifestType {
    case .manifests:
        manifestFolderName = "Manifests"
    case .manifestOverrides:
        manifestFolderName = "ManifestOverrides"
    case .icons:
        manifestFolderName = "Icons"
    case .iconOverrides:
        manifestFolderName = "IconOverrides"
    }

    let manifestsFolder = rootFolderURL.appendingPathComponent(manifestFolderName)
    let applicationFolder = manifestsFolder.appendingPathComponent(applicationFolderName(forType: payloadType), isDirectory: true)

    switch root {
    case .applicationSupport:
        do {
            try FileManager.default.createDirectoryIfNotExists(at: applicationFolder, withIntermediateDirectories: true)
        } catch {
            print("Function: \(#function), Error: \(error)")
            return nil
        }
    case .bundle:
        if !FileManager.default.fileExists(atPath: applicationFolder.path, isDirectory: nil) { return nil }
    }

    return applicationFolder
}
