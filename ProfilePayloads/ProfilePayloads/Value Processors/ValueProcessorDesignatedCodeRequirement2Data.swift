//
//  ValueProcessorDesignatedCodeRequirement2Data.swift
//  ProfilePayloads
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation

public class PayloadValueProcessorDesignatedCodeRequirement2Data: PayloadValueProcessor {

    override func string(fromData data: Data) -> String? {

        var osStatus = noErr
        let flags: SecCSFlags = SecCSFlags(rawValue: 0)
        var requirementRef: SecRequirement?

        osStatus = SecRequirementCreateWithData(data as CFData, flags, &requirementRef)
        guard osStatus == noErr, let requirement = requirementRef else {
            Swift.print("Failed to copy designated requirement.")
            if let osStatusError = SecCopyErrorMessageString(osStatus, nil) {
                Swift.print("Error: \(osStatusError)")
            }
            return nil
        }

        var requirementStringRef: CFString?
        osStatus = SecRequirementCopyString(requirement, flags, &requirementStringRef)
        guard osStatus == noErr, let requirementString = requirementStringRef as String? else {
            Swift.print("Failed to copy requirement data.")
            if let osStatusError = SecCopyErrorMessageString(osStatus, nil) {
                Swift.print("Error: \(osStatusError)")
            }
            return nil
        }

        return requirementString
    }

    override func data(fromString string: String) -> Data? {

        var osStatus = noErr
        let flags: SecCSFlags = SecCSFlags(rawValue: 0)
        var requirementRef: SecRequirement?

        osStatus = SecRequirementCreateWithString(string as CFString, flags, &requirementRef)
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
}
