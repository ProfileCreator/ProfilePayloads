//
//  ExtensionString.swift
//  ProfilePayloads
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation

extension String {
    var isNumber: Bool {
        return !isEmpty && rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }
}

extension Bool {
    var intValue: Int { return self ? 1 : 0 }
}

extension Int {
    var boolValue: Bool { return self != 0 }
}
