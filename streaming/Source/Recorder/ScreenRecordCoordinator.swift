//
//  ScreenRecordCoordinator.swift
//  streaming
//
//  Created by naor lugasi on 7/1/20.
//  Copyright © 2020 Naor Lugasi. All rights reserved.
//

import Foundation

class ScreenRecordCoordinator: NSObject, ScreenRecorderDelegate {
    let viewOverlay = WindowUtil()
    let screenRecorder = ScreenRecorder()
    var recordCompleted: ((Error?) -> Void)?

    let socket_rtp = RTPClient()
    let aacEncoder = AACEncoder()
    
    private(set) var audioAssetPath: String = ""

    override init() {
        super.init()
        aacEncoder.delegate = self
        screenRecorder.delegate = self
        viewOverlay.onStopClick = {
            self.stopRecording()
        }
    }

    func startRecording(fileName: String, recordingHandler: @escaping (Error?) -> Void, onCompletion: @escaping (Error?) -> Void) {
        audioAssetPath = ReplayFileUtil.filePath(fileName)

        self.viewOverlay.show()
        screenRecorder.startRecording(audioAssetPath: audioAssetPath) { [unowned self] (error) in
            recordingHandler(error)
            self.recordCompleted = onCompletion
        }
        
    }
    
    func recorder(recorder: ScreenRecorder, didGetAudioBuffer buffer: CMSampleBuffer) {
//        print("audioAssetPath size ", getSizeOfFile(withPath: audioAssetPath))
        
//        let dataBuffer = CMSampleBufferGetDataBuffer(buffer)
//
//        CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
//        size_t length, totalLength;
//        char *dataPointer;
//        CMBlockBufferGetDataPointer(dataBuffer, 0, &length, &totalLength, &dataPointer);
//        NSData *rawAAC = [NSData dataWithBytes:dataPointer length:totalLength];
//        NSData *adtsHeader = [self adtsDataForPacketLength:totalLength];
//        NSMutableData *fullData = [NSMutableData dataWithData:adtsHeader];
//        [fullData appendData:rawAAC];
        aacEncoder.encode(buffer)
//        socket_rtp.publish(<#T##data: Data!##Data!#>, timestamp: <#T##CMTime#>, payloadType: 97)

    }


    func stopRecording() {
        
        screenRecorder.stopRecording { (error) in
            self.viewOverlay.hide()
            self.recordCompleted?(error)
        }
    }

    class func listAllReplays() -> Array<URL> {
        return ReplayFileUtil.fetchAllReplays()
    }

    
    func getSizeOfFile(withPath path:String) -> UInt64
    {
        var totalSpace : UInt64 = 0
        
        var dict : [FileAttributeKey : Any]?

        do {
            dict = try FileManager.default.attributesOfItem(atPath: path)
        } catch let error as NSError {
             print(error.localizedDescription)
        }

        if dict != nil {
            let fileSystemSizeInBytes = dict![FileAttributeKey.size] as! NSNumber

            totalSpace = fileSystemSizeInBytes.uint64Value
            return totalSpace
        }
        
        return 0
    }
    
    func startAudioBroadcastServer() {
    }

    
    func startSinAudioBroadcastServer() {

    }
    
    func stopSinAudioBroadcastServer() {

    }

    

}


extension ScreenRecordCoordinator: AACEncoderDelegate {
    func gotAACEncodedData(_ data: Data!, timestamp: CMTime, error: Error!) {
        if (data != nil) {
            socket_rtp.publish(data, timestamp: timestamp, payloadType: 97)
        }
    }
    
    
    
}
