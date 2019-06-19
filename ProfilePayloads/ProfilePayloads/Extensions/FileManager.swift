//
//  FileManager.swift
//  ProfilePayloads
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation

extension FileManager {

    func moveFile(at url: URL, toDirectory directoryURL: URL, withName name: String) throws -> URL? {
        let targetURL = directoryURL.appendingPathComponent(name)
        try self.createDirectoryIfNotExists(at: directoryURL, withIntermediateDirectories: true)
        try self.removeItemIfExists(at: targetURL)
        try self.moveItem(at: url, to: targetURL)
        return targetURL
    }

    func createDirectoryIfNotExists(at url: URL, withIntermediateDirectories intermediate: Bool, attributes: [FileAttributeKey: Any]? = nil) throws {
        do {
            try self.createDirectory(at: url, withIntermediateDirectories: intermediate, attributes: attributes)
        } catch {
            if (error as NSError).code != 516 {
                throw error
            }
        }
    }

    func removeItemIfExists(at url: URL) throws {
        do {
            try self.removeItem(at: url)
        } catch {
            if (error as NSError).code != NSFileNoSuchFileError {
                throw error
            }
        }
    }

    func contentsOfDirectory(at url: URL, withExtension pathExtension: String, includingPropertiesForKeys keys: [URLResourceKey]?, options: FileManager.DirectoryEnumerationOptions = []) -> [URL]? {

        var contents = [URL]()
        do {
            contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: keys, options: options)
        } catch {
            // FIXME: Proper Logging
            print("Class: \(self.self), Function: \(#function), Error: \(error)")
            return nil
        }

        return contents.filter { $0.pathExtension == pathExtension }
    }
}
