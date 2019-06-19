//
//  ValueProcessor.swift
//  ProfilePayloads
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation

public class PayloadValueProcessor {

    // MARK: -
    // MARK: Variables

    let inputType: PayloadValueType
    let outputType: PayloadValueType
    let subkey: PayloadSubkey

    // MARK: -
    // MARK: Initialization

    init(subkey: PayloadSubkey, inputType: PayloadValueType, outputType: PayloadValueType) {
        self.inputType = inputType
        self.outputType = outputType
        self.subkey = subkey
    }

    // MARK: -
    // MARK: Main Functions

    public func process(value: Any) -> Any? {

        // Verify Input Type
        if !(PayloadUtility.valueType(value: value, type: self.inputType) == self.inputType) {
            Swift.print("Value: \(value) is not of the expected type: \(self.inputType)")
            return nil
        }

        if self.subkey.typeInput == .bool, let rangeList = self.subkey.rangeList, rangeList.count == 2 {
            if self.inputType == .bool {
                if let boolValue = value as? Bool, let rangeList = subkey.rangeList, rangeList.count == 2 {
                    return rangeList[boolValue.intValue]
                }
                return nil
            } else {
                if let rangeList = subkey.rangeList, rangeList.count == 2 {
                    if let index = rangeList.index(ofValue: value, ofType: self.subkey.type), 0 <= index, index <= 1 {
                        return index.boolValue
                    }
                }
                return nil
            }
        }

        // Process Item
        switch self.inputType {
        case .array:
            if let array = value as? [Any] { return self.process(array: array) }
        case .bool:
            if let bool = value as? Bool { return self.process(bool: bool) }
        case .data:
            if let data = value as? Data { return self.process(data: data) }
        case .date:
            if let date = value as? Date { return self.process(date: date) }
        case .dictionary:
            if let dictionary = value as? [String: Any] { return self.process(dictionary: dictionary) }
        case .integer:
            if let integer = value as? Int { return self.process(integer: integer) }
        case .string:
            if let string = value as? String { return self.process(string: string) }
        case .undefined:
            let processor = PayloadValueProcessors.shared.processor(subkey: self.subkey, inputType: PayloadUtility.valueType(value: value), outputType: self.outputType)
            return processor.process(value: value)
        default:
            Swift.print("Unhandled input type: \(self.inputType)")
        }
        return nil
    }

    // MARK: -
    // MARK: Process Functions: Integer

    func process(integer: Int) -> Any? {
        switch self.outputType {
        case .bool:
            return self.bool(fromInteger: integer)
        case .array:
            return self.array(fromInteger: integer)
        case .date:
            return self.date(fromInteger: integer)
        case .integer:
            return integer
        case .float:
            return self.float(fromInteger: integer)
        case .string:
            return self.string(fromInteger: integer)
        default:
            Swift.print("Integer - Unhandled output type: \(self.outputType)")
        }
        return nil
    }

    func bool(fromInteger integer: Int) -> Bool {
        return integer == 0 ? false : true
    }

    func array(fromInteger integer: Int) -> [Any]? {
        return nil
    }

    func date(fromInteger integer: Int) -> Date? {
        return nil
    }

    func float(fromInteger integer: Int) -> Float? {
        return Float(integer)
    }

    func string(fromInteger integer: Int) -> String? {
        return String(integer)
    }

    // MARK: -
    // MARK: Process Functions: Date

    func process(date: Date) -> Any? {
        switch self.outputType {
        case .date:
            return date
        case .integer:
            return self.integer(fromDate: date)
        default:
            Swift.print("Date - Unhandled output type: \(self.outputType)")
        }
        return nil
    }

    func integer(fromDate date: Date) -> Int? {
        return Int(date.timeIntervalSince1970)
    }

    // MARK: -
    // MARK: Process Functions: Array

    func process(array: [Any]) -> Any? {
        switch self.outputType {
        case .array:
            return array
        case .integer:
            return self.integer(fromArray: array)
        case .string:
            return self.string(fromArray: array)
        case .dictionary:
            return self.dictionary(fromArray: array)
        default:
            Swift.print("Array - Unhandled output type: \(self.outputType)")
        }
        return nil
    }

    func integer(fromArray array: [Any]) -> Int? {
        return nil
    }

    func string(fromArray array: [Any]) -> String? {
        var stringArray = [String]()
        for element in array {
            if let elementString = element as? String {
                stringArray.append(elementString)
            }
        }

        if !stringArray.isEmpty {
            return stringArray.joined(separator: ",")
        }
        return nil
    }

    func dictionary(fromArray array: [Any]) -> [String: Any]? {
        var dictionary = [String: Any]()
        let valueKey = array.first as? String ?? ""
        let value: Any
        // FIXME:
        if 1 < array.count {
            value = array[1]
        } else {
            // FIXME: This will be the default value if value is nil.
            value = ""
        }
        dictionary[valueKey] = value
        return dictionary
    }

    // MARK: -
    // MARK: Process Functions: Data

    func process(data: Data) -> Any? {
        switch self.outputType {
        case .data:
            return data
        case .dictionary:
            return self.dictionary(fromData: data)
        case .string:
            return self.string(fromData: data)
        default:
            Swift.print("Data - Unhandled output type: \(self.outputType)")
        }
        return nil
    }

    func string(fromData data: Data) -> String? {
        return String(data: data, encoding: .utf8)
    }

    func dictionary(fromData data: Data) -> [String: Any]? {
        if let dictionary = NSKeyedUnarchiver.unarchiveObject(with: data) as? [String: Any] {
            return dictionary
        } else { return nil }
    }

    // MARK: -
    // MARK: Process Functions: Dictionary

    func process(dictionary: [String: Any]) -> Any? {
        switch self.outputType {
        case .array:
            return self.array(fromDictionary: dictionary)
        case .data:
            return self.data(fromDictionary: dictionary)
        case .dictionary:
            return dictionary
        default:
            Swift.print("Dictionary - Unhandled output type: \(self.outputType)")
        }
        return nil
    }

    func data(fromDictionary dictionary: [String: Any]) -> Data? {
        return NSKeyedArchiver.archivedData(withRootObject: dictionary)
    }

    func array(fromDictionary dictionary: [String: Any]) -> [Any]? {
        var array = [Any]()
        for (key, value) in dictionary {
            array.append(key)
            array.append(value)
        }
        return array
    }

    // MARK: -
    // MARK: Process Functions: Bool

    func process(bool: Bool) -> Any? {
        switch self.outputType {
        case .bool:
            return bool
        case .integer:
            return bool ? 1 : 0
        default:
            Swift.print("Bool - Unhandled output type: \(self.outputType)")
        }
        return nil
    }

    // MARK: -
    // MARK: Process Functions: String

    func process(string: String) -> Any? {
        switch self.outputType {
        case .array:
            return self.array(fromString: string)
        case .data:
            return self.data(fromString: string)
        case .integer:
            return self.integer(fromString: string)
        case .string:
            return self.string(fromString: string)
        default:
            Swift.print("String - Unhandled output type: \(self.outputType)")
        }
        return nil
    }

    func array(fromString string: String) -> [Any] {
        return [string]
    }

    func data(fromString string: String) -> Data? {
        return string.data(using: .utf8, allowLossyConversion: false)
    }

    func integer(fromString string: String) -> Int? {
        return Int(string)
    }

    func string(fromString string: String) -> String? {
        return string
    }

}
