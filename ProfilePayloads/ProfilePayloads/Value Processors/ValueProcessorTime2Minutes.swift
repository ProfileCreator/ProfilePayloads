//
//  ValueProcessorWeekdaysBitmask2Int.swift
//  ProfilePayloads
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation

public class PayloadValueProcessorTime2Minutes: PayloadValueProcessor {

    override func integer(fromDate date: Date) -> Int? {
        let midnight = Calendar.current.startOfDay(for: date)
        let timeInterval = date.timeIntervalSince(midnight)
        return Int(timeInterval / 60)
    }

    override func date(fromInteger integer: Int) -> Date? {
        let midnight = Calendar.current.startOfDay(for: Date())
        let timeInterval = TimeInterval(integer * 60)
        return midnight.addingTimeInterval(timeInterval)
    }
}
