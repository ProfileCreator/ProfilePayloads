//
//  ValueProcessors.swift
//  ProfilePayloads
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation

public class PayloadValueProcessors {

    // MARK: -
    // MARK: Variables

    public static let shared = PayloadValueProcessors()

    private init() {}

    public func processor(subkey: PayloadSubkey, inputType: PayloadValueType, outputType: PayloadValueType) -> PayloadValueProcessor {
        return PayloadValueProcessor(subkey: subkey, inputType: inputType, outputType: outputType)
    }

    public func processor(withIdentifier identifier: String, subkey: PayloadSubkey, inputType: PayloadValueType, outputType: PayloadValueType) -> PayloadValueProcessor {
        switch identifier {
        case PayloadValueProcessorIdentifier.hex2data:
            return PayloadValueProcessorHex2Data(subkey: subkey, inputType: inputType, outputType: outputType)
        case PayloadValueProcessorIdentifier.base642data:
            return PayloadValueProcessorBase642Data(subkey: subkey, inputType: inputType, outputType: outputType)
        case PayloadValueProcessorIdentifier.designatedCodeRequirement2Data:
            return PayloadValueProcessorDesignatedCodeRequirement2Data(subkey: subkey, inputType: inputType, outputType: outputType)
        case PayloadValueProcessorIdentifier.plist2dict:
            return PayloadValueProcessorPlist2Dict(subkey: subkey, inputType: inputType, outputType: outputType)
        case PayloadValueProcessorIdentifier.weekdaysBitmask2Int:
            return PayloadValueProcessorWeekdaysBitmask2Int(subkey: subkey, inputType: inputType, outputType: outputType)
        case PayloadValueProcessorIdentifier.time2minutes:
            return PayloadValueProcessorTime2Minutes(subkey: subkey, inputType: inputType, outputType: outputType)
        case PayloadValueProcessorIdentifier.x5002subjectArray:
            return PayloadValueProcessorX5002SubjectArray(subkey: subkey, inputType: inputType, outputType: outputType)
        case PayloadValueProcessorIdentifier.dockTileType:
            return PayloadValueProcessorDockTileType(subkey: subkey, inputType: inputType, outputType: outputType)
        case PayloadValueProcessorIdentifier.dockTilePathType:
            return PayloadValueProcessorDockTilePathType(subkey: subkey, inputType: inputType, outputType: outputType)
        case PayloadValueProcessorIdentifier.dockTileLabel:
            return PayloadValueProcessorDockTileLabel(subkey: subkey, inputType: inputType, outputType: outputType)
        default:
            return PayloadValueProcessor(subkey: subkey, inputType: inputType, outputType: outputType)
        }
    }

    public func process(value: Any?, forSubkey subkey: PayloadSubkey, inputType: PayloadValueType, outputType: PayloadValueType) throws -> Any? {
        guard let valueToProcess = value else { return nil }
        var valueProcessed: Any?

        // ---------------------------------------------------------------------
        //  If the manifest has different input and output types for the value, the value will not be of the correct typ until it has been processed
        // ---------------------------------------------------------------------
        if let valueProcessorIdentifier = subkey.valueProcessor {

            // ---------------------------------------------------------------------
            //  If a specific valueProcessor has been selected in the manifest, use that
            // ---------------------------------------------------------------------
            let valueProcessor = PayloadValueProcessors.shared.processor(withIdentifier: valueProcessorIdentifier, subkey: subkey, inputType: inputType, outputType: outputType)
            if let valueProcessorOutput = valueProcessor.process(value: valueToProcess) {
                valueProcessed = valueProcessorOutput
            } else {
                Swift.print("Processing value: \(valueToProcess) returned a nil value using value processor: \(valueProcessorIdentifier)")
            }
        } else if inputType != outputType, subkey.type != .array {

            // ---------------------------------------------------------------------
            //  If no valueProcessor has been selected, use the default conversion between the input and output types
            // ---------------------------------------------------------------------
            let valueProcessor = PayloadValueProcessors.shared.processor(subkey: subkey, inputType: inputType, outputType: outputType)
            if let valueProcessorOutput = valueProcessor.process(value: valueToProcess) {
                valueProcessed = valueProcessorOutput
            } else {
                // FIXME: Log
            }
        }

        return valueProcessed ?? value
    }

    public func process(savedValue value: Any?, forSubkey subkey: PayloadSubkey) throws -> Any? {
        return try self.process(value: value, forSubkey: subkey, inputType: subkey.type, outputType: subkey.typeInput)
    }

    public func process(inputValue value: Any?, forSubkey subkey: PayloadSubkey) throws -> Any? {
        return try self.process(value: value, forSubkey: subkey, inputType: subkey.typeInput, outputType: subkey.type)
    }
}
