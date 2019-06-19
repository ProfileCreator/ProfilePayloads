//
//  ValueProcessorPlist2Dict.swift
//  ProfilePayloads
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation

public class PayloadValueProcessorPlist2Dict: PayloadValueProcessor {

    override func dictionary(fromData data: Data) -> [String: Any]? {

        var plist: [String: Any]?
        do {
            if let propertyList = try PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil) as? [String: Any] {
                plist = propertyList
            }
        } catch {
            Swift.print("Failed to create property list from data with error: \(error)")
        }

        return plist
    }
}
