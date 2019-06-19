//
//  ValueProcessorWeekdaysBitmask2Int.swift
//  ProfilePayloads
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation

public class PayloadValueProcessorWeekdaysBitmask2Int: PayloadValueProcessor {

    // FIXME: Untested and not currently used
    func split(bitmask: Int) -> [Int] {
        var results = Set<Int>()

        var value = bitmask
        var mask = 1
        while value > 0 {
            if value % 2 == 1 {
                results.insert(mask)
            }

            value /= 2
            mask = mask &* 2
        }

        return results.sorted()
    }

    override func integer(fromArray array: [Any]) -> Int? {
        guard let intArray = array as? [Int] else { return nil }
        return intArray.reduce(0, +)
    }

    override func array(fromInteger integer: Int) -> [Any]? {
        return self.split(bitmask: integer)
    }
}
