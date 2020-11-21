//
//  Sequence.swift
//  ProfilePayloads
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation

public func == (lhs: [String: Any], rhs: [String: Any] ) -> Bool {
    NSDictionary(dictionary: lhs).isEqual(to: rhs)
}

public func != (lhs: [String: Any], rhs: [String: Any] ) -> Bool {
    !NSDictionary(dictionary: lhs).isEqual(to: rhs)
}

// https://stackoverflow.com/a/47814003
extension Sequence where Element: Hashable {
    func contains(_ elements: [Element]) -> Bool {
        Set(elements).isSubset(of: Set(self))
    }

    func containsAny(_ elements: [Element]) -> Bool {
        !Set(elements).isDisjoint(with: Set(self))
    }
}
