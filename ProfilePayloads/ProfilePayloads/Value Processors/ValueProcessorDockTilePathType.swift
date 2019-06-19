//
//  ValueProcessorDockTilePathType.swift
//  ProfilePayloads
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation

public class PayloadValueProcessorDockTilePathType: PayloadValueProcessor {

    override func string(fromInteger integer: Int) -> String? {
        switch integer {
        case 0:
            return "/"
        case 15:
            return "file://"
        default:
            return nil
        }
    }

    override func integer(fromString string: String) -> Int? {
        if string.hasPrefix("/") {
            return 0
        } else if string.contains("://") {
            return 15
        }
        return nil
    }
}
