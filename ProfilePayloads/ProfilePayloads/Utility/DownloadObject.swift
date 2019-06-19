//
//  DownloadObject.swift
//  ProfilePayloads
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation

class DownloadObject {

    var completionBlock: DownloadManager.completionBlock

    let task: URLSessionDownloadTask

    let fileName: String
    let directoryURL: URL

    init(task: URLSessionDownloadTask,
         completionBlock: @escaping DownloadManager.completionBlock,
         fileName: String,
         directoryURL: URL) {
        self.completionBlock = completionBlock
        self.task = task
        self.fileName = fileName
        self.directoryURL = directoryURL
    }

}
