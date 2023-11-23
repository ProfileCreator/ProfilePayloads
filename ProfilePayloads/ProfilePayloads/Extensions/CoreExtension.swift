//
//  CoreExtension.swift
//  ProfilePayloads
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import CommonCrypto
import Foundation

// MARK: -
// MARK: Data

extension Data {
    var md5: String {
        let length = Int(CC_MD5_DIGEST_LENGTH)
        var hash = [UInt8](repeating: 0, count: length)
        self.withUnsafeBytes { buffer in
            // Convert UnsafeRawBufferPointer to UnsafePointer<UInt8>
            guard let baseAddress = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                return
            }
            CC_MD5(baseAddress, CC_LONG(buffer.count), &hash)
        }
        return (0..<length).map { String(format: "%02x", hash[$0]) }.joined()
    }
}

// MARK: -
// MARK: Array

extension Array where Element: Comparable {
    func containsSameElements(as other: [Element]) -> Bool {
        self.count == other.count && self.sorted() == other.sorted()
    }
}

extension Array where Element: Equatable {
    public mutating func mergeElements<C: Collection>(newElements: C) where C.Iterator.Element == Element {
        let filteredList = newElements.filter { !self.contains($0) }
        self.append(contentsOf: filteredList)
    }

}

extension Array where Element: Any {

    // FIXME: Generics?
    public func containsAny(value: Any, ofType type: PayloadValueType) -> Bool {
        switch type {
        case .bool:
            if
                let valueBool = value as? Bool,
                let arrayBool = self as? [Bool] {
                return arrayBool.contains(valueBool)
            }
        case .integer:
            if
                let valueInt = value as? Int,
                let arrayInt = self as? [Int] {
                return arrayInt.contains(valueInt)
            }
        case .float:
            if
                let valueDouble = value as? Double,
                let arrayDouble = self as? [Double] {
                return arrayDouble.contains(valueDouble)
            } else if
                let valueFloat = value as? Float,
                let arrayFloat = self as? [Float] {
                return arrayFloat.contains(valueFloat)
            }
        case .date:
            if
                let valueDate = value as? Date,
                let arrayDate = self as? [Date] {
                return arrayDate.contains(valueDate)
            }
        case .string:
            if
                let valueString = value as? String,
                let arrayString = self as? [String] {
                return arrayString.contains(valueString)
            }
        default:
            Swift.print("Class: \(self.self), Function: \(#function), Unknown Type: \(Swift.type(of: value)), Expected Type: \(type)")
        }
        return false
    }

    // FIXME: Generics?
    public func containsAny(values: [Any], ofType type: PayloadValueType) -> Bool {
        switch type {
        case .bool:
            if
                let valueBool = values as? [Bool],
                let arrayBool = self as? [Bool] {
                return arrayBool.containsAny(valueBool)
            }
        case .integer:
            if
                let valueInt = values as? [Int],
                let arrayInt = self as? [Int] {
                return arrayInt.containsAny(valueInt)
            }
        case .float:
            if
                let valueDouble = values as? [Double],
                let arrayDouble = self as? [Double] {
                return arrayDouble.containsAny(valueDouble)
            } else if
                let valueFloat = values as? [Float],
                let arrayFloat = self as? [Float] {
                return arrayFloat.containsAny(valueFloat)
            }
        case .date:
            if
                let valueDate = values as? [Date],
                let arrayDate = self as? [Date] {
                return arrayDate.containsAny(valueDate)
            }
        case .string:
            if
                let valueString = values as? [String],
                let arrayString = self as? [String] {
                return arrayString.containsAny(valueString)
            }
        default:
            Swift.print("Class: \(self.self), Function: \(#function), Unknown Type: \(Swift.type(of: values)), Expected Type: \(type)")
        }
        return false
    }

    // FIXME: Generics?
    public func contains(value: Any, ofType type: PayloadValueType) -> Bool {
        switch type {
        case .bool:
            if
                let valueBool = value as? Bool,
                let arrayBool = self as? [Bool] {
                return arrayBool == [valueBool]
            }
        case .integer:
            if
                let valueInt = value as? Int,
                let arrayInt = self as? [Int] {
                return arrayInt == [valueInt]
            }
        case .float:
            if
                let valueDouble = value as? Double,
                let arrayDouble = self as? [Double] {
                return arrayDouble == [valueDouble]
            } else if
                let valueFloat = value as? Float,
                let arrayFloat = self as? [Float] {
                return arrayFloat == [valueFloat]
            }
        case .date:
            if
                let valueDate = value as? Date,
                let arrayDate = self as? [Date] {
                return arrayDate == [valueDate]
            }
        case .string:
            if
                let valueString = value as? String,
                let arrayString = self as? [String] {
                return arrayString == [valueString]
            }
        default:
            Swift.print("Class: \(self.self), Function: \(#function), Unknown Type: \(Swift.type(of: value)), Expected Type: \(type)")
        }
        return false
    }

    // FIXME: Generics?
    public func contains(values: [Any], ofType type: PayloadValueType, sorted: Bool = false) -> Bool {
        switch type {
        case .array:
            if
                let valueArray = values as? [[Any]],
                let arrayArray = self as? [[Any]] {
                for index in valueArray.indices {
                    let valueArrayArray = valueArray[index]
                    let arrayArrayArray = arrayArray[index]

                    guard
                        let value1Value = valueArrayArray.first,
                        let value2Value = arrayArrayArray.first else {
                            return false
                    }

                    let value1TypePayload = PayloadUtility.valueType(value: value1Value)
                    let value1Type = String(cString: object_getClassName(value1Value))

                    let value2TypePayload = PayloadUtility.valueType(value: value2Value)
                    let value2Type = String(cString: object_getClassName(value2Value))

                    if value1TypePayload != value2TypePayload || value1Type != value2Type {
                        Swift.print("value1TypePayload: \(value1TypePayload)")
                        Swift.print("value2TypePayload: \(value2TypePayload)")
                        Swift.print("value1Type: \(value1Type)")
                        Swift.print("value2Type: \(value2Type)")
                        return false
                    }

                    return valueArrayArray.contains(values: arrayArrayArray, ofType: value1TypePayload, sorted: sorted)
                }
            }
        case .bool:
            if
                let valueBool = values as? [Bool],
                let arrayBool = self as? [Bool] {
                return arrayBool == valueBool
            }
        case .integer:
            if
                let valueInt = values as? [Int],
                let arrayInt = self as? [Int] {
                if sorted {
                    return arrayInt.containsSameElements(as: valueInt)
                } else {
                    return arrayInt == valueInt
                }
            }
        case .float:
            if
                let valueDouble = values as? [Double],
                let arrayDouble = self as? [Double] {
                if sorted {
                    return arrayDouble.containsSameElements(as: valueDouble)
                } else {
                    return arrayDouble == valueDouble
                }
            } else if
                let valueFloat = values as? [Float],
                let arrayFloat = self as? [Float] {
                if sorted {
                    return arrayFloat.containsSameElements(as: valueFloat)
                } else {
                    return arrayFloat == valueFloat
                }
            }
        case .data:
            if let valueData = values as? [Data],
                let arrayData = values as? [Data] {
                return arrayData == valueData
            }
        case .date:
            if
                let valueDate = values as? [Date],
                let arrayDate = self as? [Date] {
                if sorted {
                    return arrayDate.containsSameElements(as: valueDate)
                } else {
                    return arrayDate == valueDate
                }
            }
        case .string:
            if
                let valueString = values as? [String],
                let arrayString = self as? [String] {
                if sorted {
                    return arrayString.containsSameElements(as: valueString)
                } else {
                    return arrayString == valueString
                }
            }
        case .dictionary:
            if
                let valueDictionary = values as? [[String: AnyHashable]],
                let arrayDictionary = self as? [[String: AnyHashable]] {
                return arrayDictionary == valueDictionary
            }
        default:
            Swift.print("Class: \(self.self), Function: \(#function), Unknown Type: \(Swift.type(of: values)), Expected Type: \(type)")
        }
        return false
    }

    // FIXME: Generics?
    public mutating func remove(_ value: Any, ofType type: PayloadValueType) {
        switch type {
        case .bool:
            if
                let valueBool = value as? Bool,
                let arrayBool = self as? [Bool] {

                // swiftlint:disable:next syntactic_sugar
                if let newArray = arrayBool.filter({ $0 != valueBool }) as? Array<Element> {
                    self = newArray
                }
            }
        case .integer:
            if
                let valueInt = value as? Int,
                let arrayInt = self as? [Int] {

                // swiftlint:disable:next syntactic_sugar
                if let newArray = arrayInt.filter({ $0 != valueInt }) as? Array<Element> {
                    self = newArray
                }
            }
        case .float:
            if
                let valueDouble = value as? Double,
                let arrayDouble = self as? [Double] {

                // swiftlint:disable:next syntactic_sugar
                if let newArray = arrayDouble.filter({ $0 != valueDouble }) as? Array<Element> {
                    self = newArray
                }
            } else if
                let valueFloat = value as? Float,
                let arrayFloat = self as? [Float] {

                // swiftlint:disable:next syntactic_sugar
                if let newArray = arrayFloat.filter({ $0 != valueFloat }) as? Array<Element> {
                    self = newArray
                }
            }
        case .date:
            if
                let valueDate = value as? Date,
                let arrayDate = self as? [Date] {

                // swiftlint:disable:next syntactic_sugar
                if let newArray = arrayDate.filter({ $0 != valueDate }) as? Array<Element> {
                    self = newArray
                }
            }
        case .data:
            if
                let valueData = value as? Data,
                let arrayData = self as? [Data] {

                // swiftlint:disable:next syntactic_sugar
                if let newArray = arrayData.filter({ $0 != valueData }) as? Array<Element> {
                    self = newArray
                }
            }
        case .string:
            if
                let valueString = value as? String,
                let arrayString = self as? [String] {

                // swiftlint:disable:next syntactic_sugar
                if let newArray = arrayString.filter({ $0 != valueString }) as? Array<Element> {
                    self = newArray
                }
            }
        default:
            Swift.print("Class: \(self.self), Function: \(#function), Unknown Type: \(Swift.type(of: value)), Expected Type: \(type)")
        }
    }

    // FIXME: Generics?
    public func index(ofValue value: Any, ofType type: PayloadValueType) -> Index? {
        switch type {
        case .float:
            if let valueDouble = value as? Double,
                let arrayDouble = self as? [Double] {
                return arrayDouble.firstIndex(of: valueDouble)
            } else if let valueFloat = value as? Float,
                let arrayFloat = self as? [Float] {
                return arrayFloat.firstIndex(of: valueFloat)
            }
        case .integer:
            if
                let valueInt = value as? Int,
                let arrayInt = self as? [Int] {
                return arrayInt.firstIndex(of: valueInt)
            }
        case .string:
            if let valueString = value as? String,
                let arrayString = self as? [String] {
                return arrayString.firstIndex(of: valueString)
            }
        case .bool:
            if let valueBool = value as? Bool,
                let arrayBool = self as? [Bool] {
                return arrayBool.firstIndex(of: valueBool)
            }
        case .date:
            if let valueDate = value as? Date,
                let arrayDate = self as? [Date] {
                return arrayDate.firstIndex(of: valueDate)
            }
        case .data:
            if let valueData = value as? Data,
                let arrayData = self as? [Data] {
                return arrayData.firstIndex(of: valueData)
            }
        case .dictionary:
            Swift.print("value: \(value)")
            if
                let valueDictionary = value as? [String: Any],
                let arrayDictionary = self as? [[String: Any]] {
                Swift.print("valueDictionary: \(valueDictionary)")
                Swift.print("arrayDictionary: \(arrayDictionary)")
                return arrayDictionary.firstIndex(where: { $0 == valueDictionary })
            }
        default:
            Swift.print("Class: \(self.self), Function: \(#function), Unknown Type: \(type)")
        }
        return nil
    }

    // FIXME: Generics?
    public func indexes(ofValues values: [Any], ofType type: PayloadValueType) -> IndexSet? {
        var indexSet = IndexSet()
        switch type {
        case .float:
            if
                let valuesDouble = values as? [Double],
                let arrayDouble = self as? [Double] {
                valuesDouble.forEach {
                    if let index = arrayDouble.firstIndex(of: $0) {
                        indexSet.insert(index)
                    }
                }
            } else if
                let valuesFloat = values as? [Float],
                let arrayFloat = self as? [Float] {
                valuesFloat.forEach {
                    if let index = arrayFloat.firstIndex(of: $0) {
                        indexSet.insert(index)
                    }
                }
            }
        case .integer:
            if
                let valuesInt = values as? [Int],
                let arrayInt = self as? [Int] {
                valuesInt.forEach {
                    if let index = arrayInt.firstIndex(of: $0) {
                        indexSet.insert(index)
                    }
                }
            }
        case .string:
            if let valuesString = values as? [String],
                let arrayString = self as? [String] {
                valuesString.forEach {
                    if let index = arrayString.firstIndex(of: $0) {
                        indexSet.insert(index)
                    }
                }
            }
        case .bool:
            if let valuesBool = values as? [Bool],
                let arrayBool = self as? [Bool] {
                valuesBool.forEach {
                    if let index = arrayBool.firstIndex(of: $0) {
                        indexSet.insert(index)
                    }
                }
            }
        case .date:
            if let valuesDate = values as? [Date],
                let arrayDate = self as? [Date] {
                valuesDate.forEach {
                    if let index = arrayDate.firstIndex(of: $0) {
                        indexSet.insert(index)
                    }
                }
            }
        case .data:
            if let valuesData = values as? [Data],
                let arrayData = self as? [Data] {
                valuesData.forEach {
                    if let index = arrayData.firstIndex(of: $0) {
                        indexSet.insert(index)
                    }
                }
            }
        default:
            Swift.print("Class: \(self.self), Function: \(#function), Unknown Type: \(type)")
        }
        return indexSet.isEmpty ? nil : indexSet
    }
}
