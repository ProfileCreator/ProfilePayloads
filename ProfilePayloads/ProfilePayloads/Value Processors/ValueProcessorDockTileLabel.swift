//
//  ValueProcessorWeekdaysBitmask2Int.swift
//  ProfilePayloads
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation

public class PayloadValueProcessorDockTileLabel: PayloadValueProcessor {

    override func string(fromString string: String) -> String? {
        guard !string.isEmpty else { return nil }
        let url = URL(fileURLWithPath: string)
        if url.pathExtension == "app" {
            return url.deletingPathExtension().lastPathComponent
        } else {
            return url.lastPathComponent
        }
    }

}
