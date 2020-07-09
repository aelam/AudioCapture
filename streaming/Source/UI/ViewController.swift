//
//  ViewController.swift
//  streaming
//
//  Created by naor lugasi on 6/29/20.
//  Copyright © 2020 Naor Lugasi. All rights reserved.
//

import UIKit
import AVFoundation


class ViewController: UIViewController {

    @IBOutlet weak var recordButton: UIButton!

    //let streamer = StreamFFp()
    var player: AVAudioPlayer?
    let screenRecord = ScreenRecordCoordinator()

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func playSound(_ sender: Any) {

        guard let url = Bundle.main.url(forResource: "soundName", withExtension: "mp3") else {
            return
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)

            /* iOS 10 and earlier require the following line:
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileTypeMPEGLayer3) */

            guard let player = player else {
                return
            }

            player.play()

        } catch let error {
            print(error.localizedDescription)
        }
    }


    @IBAction func startbtn(_ sender: Any) {

        screenRecord.viewOverlay.stopButtonColor = UIColor.red
        let randomNumber = arc4random_uniform(9999);
        screenRecord.startRecording(fileName: "coolScreenRecording\(randomNumber)", recordingHandler: { (error) in
            print("Recording in progress")
        }) { (error) in
            print("Recording Complete")
        }

    }

    @IBAction func stopButtonTapped(_ sender: Any) {
        screenRecord.stopRecording()
    }

    @IBAction func startSinAudioServerButton(_ sender: Any) {
        screenRecord.startSinAudioBroadcastServer()
    }

    @IBAction func stopSinAudioServerButton(_ sender: Any) {
        screenRecord.stopSinAudioBroadcastServer()
    }


}

