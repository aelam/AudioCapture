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
    let aacEncoder2 = AACEncoder2()

//    @property (nonatomic) dispatch_queue_t encoderQueue;
    let encoderSerialQueue = DispatchQueue(label: "swiftlee.serial.queue")
    
    private(set) var audioAssetPath: String = ""
    public var receiverIP: String = "10.30.28.26" {
        didSet {
            socket_rtp.address = receiverIP
        }
    }
    public var receiverPort: String = "10001" {
        didSet {
            socket_rtp.port = Int(receiverIP) ?? 10001
        }
    }
    
    
    override init() {
        super.init()

        aacEncoder2.channelsPerFrame = 1
        aacEncoder2.delegate = self
        
        socket_rtp.address = receiverIP
        socket_rtp.port = Int(receiverIP) ?? 10001

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
//        DispatchQueue.main.async {
//            self.aacEncoder.encode(buffer)
//        }
//        self.aacEncoder.encode(buffer)
        
        // 2
        encoderSerialQueue.sync {
            self.aacEncoder2.startEncode(buffer)
        }
    }


    func stopRecording() {
        socket_rtp.reset()

        screenRecorder.stopRecording { (error) in
            self.viewOverlay.hide()
            self.recordCompleted?(error)
        }
    }

    class func listAllReplays() -> Array<URL> {
        return ReplayFileUtil.fetchAllReplays()
    }
}


extension ScreenRecordCoordinator: AACEncoderDelegate {
    func gotAACEncodedData(_ data: Data!, timestamp: CMTime, error: Error!) {
        if (data != nil) {
            socket_rtp.publish(data, timestamp: timestamp, payloadType: 97)
        }
    }
    
}


extension ScreenRecordCoordinator: AACEncoder2Delegate {
    func getEncodedAudioData(_ data: Data!, timeStamp: CMTime) {
        if (data != nil) {
            socket_rtp.publish(data, timestamp: timeStamp, payloadType: 97)
        }
    }
}
