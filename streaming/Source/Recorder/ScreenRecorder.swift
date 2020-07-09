//
//  ScreenRecorder.swift
//  streaming
//
//  Created by naor lugasi on 7/1/20.
//  Copyright © 2020 Naor Lugasi. All rights reserved.
//

import Foundation
import ReplayKit
import AVKit

let RecordVideo = false

@objc protocol ScreenRecorderDelegate: NSObjectProtocol {
    @objc optional func recorder(recorder: ScreenRecorder, didGetAudioBuffer buffer: CMSampleBuffer);
    @objc optional func recorder(recorder: ScreenRecorder, didGetVideoBuffer buffer: CMSampleBuffer);
    @objc optional func recorder(_ recorder: ScreenRecorder, didStopRecordingWithError error: Error?)

}


class ScreenRecorder: NSObject, RPScreenRecorderDelegate {

    var assetWriter: AVAssetWriter!
    var videoInput: AVAssetWriterInput?
    var audioInput: AVAssetWriterInput?

    let viewOverlay = WindowUtil()
    weak var delegate: ScreenRecorderDelegate?

    //MARK: Screen Recording
    func startRecording(audioAssetPath: String, recordingHandler: @escaping (Error?) -> Void) {
        if #available(iOS 11.0, *) {
            
            // Setup Recording File
            setupAudioSettings(audioAssetPath: audioAssetPath)
//            RPScreenRecorder.shared().delegate = self
//            RPScreenRecorder.shared().isMicrophoneEnabled = true
            RPScreenRecorder.shared().startCapture(handler: { (sample, bufferType, error) in
                //print(sample, bufferType)

                recordingHandler(error)
                
                if CMSampleBufferDataIsReady(sample) {
                    if self.assetWriter.status == AVAssetWriter.Status.unknown {
                        self.assetWriter.startWriting()
                        self.assetWriter.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sample))
                    }

                    if self.assetWriter.status == AVAssetWriter.Status.failed {
                        if self.assetWriter.status == .failed {
                            do { // delete old video
                                try FileManager.default.removeItem(at: URL(fileURLWithPath: audioAssetPath))
                            } catch { print(error.localizedDescription) }
                        }
                        print("[!!!]Error occured, status = \(self.assetWriter.status.rawValue), \(self.assetWriter.error!.localizedDescription) \(String(describing: self.assetWriter.error))")
                        return
                    }


                    if (bufferType == .video) {
                        if RecordVideo {
                            if self.videoInput?.isReadyForMoreMediaData ?? false {
                                self.videoInput?.append(sample)
                            }
                        }
                    }
                    else if (bufferType == .audioApp) {
                        if self.audioInput?.isReadyForMoreMediaData ?? false {
                            self.audioInput?.append(sample)
                            // HERE WE SEND THE SAMPLE BUFFER TO STREAMING
                            //self.streamer.didOutputSampleBuffer(sample)
                        }
                        self.delegate?.recorder?(recorder: self, didGetAudioBuffer: sample)
                    }

                    else if (bufferType == .audioMic) {
//                        if self.audioInput?.isReadyForMoreMediaData ?? false {
//                            self.audioInput?.append(sample)
//                            // HERE WE SEND THE SAMPLE BUFFER TO STREAMING
//                            //self.streamer.didOutputSampleBuffer(sample)
//                        }
//                        self.delegate?.recorder?(recorder: self, didGetAudioBuffer: sample)
                    }

                }

            }) { (error) in
                recordingHandler(error)
                //                debugPrint(error)
            }
        } else {
            // Fallback on earlier versions
        }
    }

    func setupAudioSettings(audioAssetPath: String) {
        if (RecordVideo) {
            let audioSettings = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVNumberOfChannelsKey: 2,
                AVSampleRateKey: 44100.0,
                AVEncoderBitRateKey: 192000
            ] as [String: Any]

            let fileURL = URL(fileURLWithPath: audioAssetPath)

            assetWriter = try! AVAssetWriter(outputURL: fileURL, fileType: AVFileType.m4a)

            audioInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: audioSettings)
            audioInput!.expectsMediaDataInRealTime = true
            assetWriter.add(audioInput!)
            let videoOutputSettings: Dictionary<String, Any> = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: UIScreen.main.bounds.size.width,
                AVVideoHeightKey: UIScreen.main.bounds.size.height
            ];

            videoInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoOutputSettings)
            videoInput!.expectsMediaDataInRealTime = true
            assetWriter.add(videoInput!)

        } else {
            let audioSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVNumberOfChannelsKey: 2,
                AVSampleRateKey: 44100.0,
                AVEncoderBitRateKey: 192000
            ]

            let fileURL = URL(fileURLWithPath: audioAssetPath)

            assetWriter = try! AVAssetWriter(outputURL: fileURL, fileType: AVFileType.m4a)
            audioInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: audioSettings)
            audioInput!.expectsMediaDataInRealTime = true
            assetWriter.add(audioInput!)
            
        }
    }

    func stopRecording(handler: @escaping (Error?) -> Void) {
        _stopRecording(handler: handler)
    }

    // Stop Actively
    internal func _stopRecording(handler: @escaping (Error?) -> Void) {
        if #available(iOS 11.0, *) {
            RPScreenRecorder.shared().stopCapture { (error) in
                handler(error)
                self.videoInput?.markAsFinished()
                self.audioInput?.markAsFinished()
                self.assetWriter.finishWriting {
                    print(ReplayFileUtil.fetchAllReplays())
                }
            }
        } else {
            // Fallback on earlier versions
        }
    }

    internal func _stopAssetWriter() {
        self.assetWriter.finishWriting {
            print(ReplayFileUtil.fetchAllReplays())
        }
    }

    func notifyStopRecorder(_ error: Error?) {
        self.delegate?.recorder?(self, didStopRecordingWithError: error)
    }


    func screenRecorder(_ screenRecorder: RPScreenRecorder, didStopRecordingWithError error: Error, previewViewController: RPPreviewViewController?) {
        notifyStopRecorder(error)
        _stopRecording { (e) in

        }
    }

    @available(iOS 11.0, *)
    func screenRecorder(_ screenRecorder: RPScreenRecorder, didStopRecordingWith previewViewController: RPPreviewViewController?, error: Error?) {
        _stopRecording { (e) in

        }
        notifyStopRecorder(error)
    }

}
