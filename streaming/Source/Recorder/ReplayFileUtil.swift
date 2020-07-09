//
//  ReplayFileUtil.swift
//  streaming
//
//  Created by naor lugasi on 7/1/20.
//  Copyright © 2020 Naor Lugasi. All rights reserved.
//

import UIKit

class ReplayFileUtil {

    internal class func createReplaysFolder() {
        // path to documents directory
        let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        if let documentDirectoryPath = documentDirectoryPath {
            // create the custom folder path
            let replayDirectoryPath = documentDirectoryPath.appending("/Replays")
            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: replayDirectoryPath) {
                do {
                    try fileManager.createDirectory(atPath: replayDirectoryPath,
                            withIntermediateDirectories: false,
                            attributes: nil)
                } catch {
                    print("Error creating Replays folder in documents dir: \(error)")
                }
            }
        }
    }

    internal class func filePath(_ fileName: String) -> String {
        createReplaysFolder()
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0] as String
//        let filePath: String = "\(documentsDirectory)/Replays/\(fileName).mp4"
        let filePath: String = "\(documentsDirectory)/\(fileName).m4a"
        return filePath
    }

    internal class func fetchAllReplays() -> Array<URL> {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let replayPath = documentsDirectory?.appendingPathComponent("/Replays")
        let directoryContents = try! FileManager.default.contentsOfDirectory(at: replayPath!, includingPropertiesForKeys: nil, options: [])
        return directoryContents
    }

}
