//
//  DownloadManager.swift
//  ProfilePayloads
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation

class DownloadManager: NSObject {

    typealias completionBlock = (_ error: Error?, _ fileURL: URL?) -> Void

    static let shared = DownloadManager()

    var session: URLSession?
    var sessionDownloads = [String: DownloadObject]()
    var downloadedURLs = [URL]()

    override init() {
        super.init()
        self.session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }

    public func downloadUpdates(fromURLs urls: [URL], completionHandler: @escaping (_ urls: [URL]?, _ error: Error?) -> Void) {
        self.downloadedURLs = [URL]()
        for url in urls {
            if self.sessionDownloads.contains(where: { $0.key == url.absoluteString }) {
                continue
            } else if let downloadDirectory = self.downloadDirectory(forURL: url) {
                self.downloadFile(fromURL: url, inDirectory: downloadDirectory, completionHandler: completionHandler)
            } else {
                self.sessionDownloads.removeValue(forKey: url.absoluteString)
            }
        }
    }

    internal func downloadDirectory(forURL url: URL) -> URL? {
        if
            let payloadType = payloadType(forString: url.deletingLastPathComponent().lastPathComponent),
            let manifestType = manifestType(forString: url.deletingLastPathComponent().deletingLastPathComponent().lastPathComponent) {
            return applicationFolder(root: .applicationSupport, payloadType: payloadType, manifestType: manifestType)
        }
        Swift.print("Failed to get payloadType from url: \(url) and string: \(url.deletingLastPathComponent().lastPathComponent)")
        return nil
    }

    public func downloadFile(fromURL url: URL, inDirectory directoryURL: URL, completionHandler: @escaping (_ urls: [URL]?, _ error: Error?) -> Void) {
        guard let downloadTask = self.session?.downloadTask(with: url) else {
            Swift.print("Failed to create download task")
            completionHandler(nil, nil)
            return
        }

        //Swift.print("downloadTask: \(downloadTask)")
        let downloadObject = DownloadObject(task: downloadTask,
                                            completionBlock: { _, fileURL in

                                                if let downloadedURL = fileURL {
                                                    self.downloadedURLs.append(downloadedURL)
                                                }
                                                //Swift.print("error: \(error)")
                                                //Swift.print("fileURL: \(fileURL)")
                                                //Swift.print("remaining: \(self.sessionDownloads.count)")
                                                if self.sessionDownloads.isEmpty {
                                                    completionHandler(self.downloadedURLs, nil)
                                                }
        },
                                            fileName: url.lastPathComponent,
                                            directoryURL: directoryURL)
        //Swift.print("downloadObject: \(downloadObject)")
        self.sessionDownloads[url.absoluteString] = downloadObject
        //Swift.print("self.sessionDownloads: \(self.sessionDownloads)")
        //Swift.print("Resume Download")
        downloadTask.resume()
    }
}

extension DownloadManager: URLSessionDelegate, URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {

        //Swift.print("urlSession: \(session), downloadTask: \(downloadTask), location: \(location)")
        //Swift.print("Getting key: \(downloadTask.originalRequest?.url?.absoluteString)")
        guard let key = downloadTask.originalRequest?.url?.absoluteString else { return }
        //Swift.print("key: \(key)")
        if let downloadObject = self.sessionDownloads[key] {
            self.sessionDownloads.removeValue(forKey: key)
            //Swift.print("downloadTask.response: \(downloadTask.response)")
            if let response = downloadTask.response as? HTTPURLResponse {

                //Swift.print("response: \(response)")
                //Swift.print("response.statusCode: \(response.statusCode)")

                // Verify we got a reasonable result
                guard response.statusCode < 400 else {
                    // FIXME: Add Error
                    DispatchQueue.main.sync {
                        downloadObject.completionBlock(nil, nil)
                    }
                    return
                }

                do {
                    if let fileURL = try FileManager.default.moveFile(at: location, toDirectory: downloadObject.directoryURL, withName: downloadObject.fileName) {
                        DispatchQueue.main.sync {
                            downloadObject.completionBlock(nil, fileURL)
                        }
                    } else {
                        // FIXME: Add Error
                        DispatchQueue.main.sync {
                            downloadObject.completionBlock(nil, nil)
                        }
                    }
                } catch {
                    DispatchQueue.main.sync {
                        downloadObject.completionBlock(error, nil)
                    }
                }
            }
        } else {
            Swift.print("Failed to get downloadObject for key: \(key) in self.sessionDownloads: \(self.sessionDownloads)")
            self.sessionDownloads.removeValue(forKey: key)
        }
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        //Swift.print("urlSession: \(session), task: \(task), error: \(error)")
        //Swift.print("Getting key: \(task.originalRequest?.url?.absoluteString)")
        guard let key = task.originalRequest?.url?.absoluteString else { return }
        //Swift.print("key: \(key)")
        if let downloadObject = self.sessionDownloads[key] {
            self.sessionDownloads.removeValue(forKey: key)
            if let error = error {
                DispatchQueue.main.sync {
                    downloadObject.completionBlock(error, nil)
                }
            }
        } else {
            self.sessionDownloads.removeValue(forKey: key)
        }
    }

}
