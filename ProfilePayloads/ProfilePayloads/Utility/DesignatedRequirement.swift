//
//  DesignatedRequirement.swift
//  ProfilePayloads
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation

public func SecRequirementCopyData(forURL url: URL) -> Data? {

    var osStatus = noErr
    var codeRef: SecStaticCode?

    osStatus = SecStaticCodeCreateWithPath(url as CFURL, [], &codeRef)
    guard osStatus == noErr, let code = codeRef else {
        Swift.print("Failed to create code with path: \(url.path)")
        if let osStatusError = SecCopyErrorMessageString(osStatus, nil) {
            Swift.print("Error: \(osStatusError)")
        }
        return nil
    }

    let flags: SecCSFlags = SecCSFlags(rawValue: 0)
    var requirementRef: SecRequirement?

    osStatus = SecCodeCopyDesignatedRequirement(code, flags, &requirementRef)
    guard osStatus == noErr, let requirement = requirementRef else {
        Swift.print("Failed to copy designated requirement.")
        if let osStatusError = SecCopyErrorMessageString(osStatus, nil) {
            Swift.print("Error: \(osStatusError)")
        }
        return nil
    }

    var requirementDataRef: CFData?
    osStatus = SecRequirementCopyData(requirement, flags, &requirementDataRef)
    guard osStatus == noErr, let requirementData = requirementDataRef as Data? else {
        Swift.print("Failed to copy requirement data.")
        if let osStatusError = SecCopyErrorMessageString(osStatus, nil) {
            Swift.print("Error: \(osStatusError)")
        }
        return nil
    }

    return requirementData
}
