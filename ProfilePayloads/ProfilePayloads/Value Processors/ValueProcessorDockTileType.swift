//
//  ValueProcessorWeekdaysBitmask2Int.swift
//  ProfilePayloads
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation

public class PayloadValueProcessorDockTileType: PayloadValueProcessor {

    override func string(fromInteger integer: Int) -> String? {
        switch integer {
        case 1:
            return "file-tile"
        case 2:
            return "url-tile"
        case 3:
            return "directory-tile"
        default:
            return nil
        }
    }

    override func integer(fromString string: String) -> Int? {
        switch string {
        case "file-tile":
            return 1
        case "url-tile":
            return 2
        case "directory-tile":
            return 3
        default:
            return nil
        }
    }
}
