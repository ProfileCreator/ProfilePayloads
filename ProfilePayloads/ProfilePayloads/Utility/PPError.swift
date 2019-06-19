//
//  PPError.swift
//  ProfilePayloads
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation

public enum PPError: Error {
    case unknownError
}

extension PPError: LocalizedError {
    public var localizedDescription: String {
        switch self {
        case .unknownError:
            return "Unknown error"
        }
    }
}
