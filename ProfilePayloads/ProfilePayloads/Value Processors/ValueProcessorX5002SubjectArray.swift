//
//  ValueProcessorStringHex2Data.swift
//  ProfilePayloads
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation

public class PayloadValueProcessorX5002SubjectArray: PayloadValueProcessor {

    override func array(fromString string: String) -> [Any] {
        var valueArray = [[[String]]]()
        for object in string.components(separatedBy: ",") {
            valueArray.append([object.components(separatedBy: "=")])
        }
        return valueArray
    }

    override func string(fromArray array: [Any]) -> String? {
        guard let valueArray = array as? [[[String]]] else { return nil }
        var string = ""
        for outerArray in valueArray {
            for innerArray in outerArray {
                if !string.isEmpty {
                    string += ","
                }
                guard 2 <= innerArray.count else {
                    if let innerString = innerArray.first {
                        string += innerString
                    }
                    continue
                }
                string += innerArray.prefix(upTo: 2).joined(separator: "=")
            }
        }
        return string
    }
}
