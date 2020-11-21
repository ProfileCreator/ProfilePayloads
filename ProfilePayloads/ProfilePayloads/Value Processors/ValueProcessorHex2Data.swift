//
//  ValueProcessorStringHex2Data.swift
//  ProfilePayloads
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

public class PayloadValueProcessorHex2Data: PayloadValueProcessor {

    // From: https://stackoverflow.com/a/26503955
    func dataWithHexString(hex: String) -> Data {
        var hex = hex.filter { "0123456789abcdefABCDEF".contains($0) }
        var data = Data()
        while 2 <= hex.count {
            let subIndex = hex.index(hex.startIndex, offsetBy: 2)
            let c = String(hex[..<subIndex])
            hex = String(hex[subIndex...])
            var ch: UInt32 = 0
            Scanner(string: c).scanHexInt32(&ch)
            var char = UInt8(ch)
            data.append(&char, count: 1)
        }
        return data
    }

    override func data(fromString string: String) -> Data? {
        dataWithHexString(hex: string)
    }

    override func string(fromData data: Data) -> String? {
        data.map { String(format: "%02x", $0) }.joined()
    }
}
