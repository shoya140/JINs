//
//  JMMapViewController.swift
//  JINs
//
//  Created by Shoya Ishimaru on 2015/07/25.
//  Copyright (c) 2015年 shoya140. All rights reserved.
//

import UIKit
import AVFoundation

class JMMapViewController: UIViewController, MEMELibDelegate{

    var audioPlayer:AVAudioPlayer! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        MEMELib.sharedInstance().delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func playSE(file_name:String, stop:Bool){
        
        if self.audioPlayer != nil && self.audioPlayer.playing == true {
            if stop == true{
                self.audioPlayer.stop()
            }
        }
        
        let sound_data = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource(file_name, ofType: "mp3")!)
        self.audioPlayer = AVAudioPlayer(contentsOfURL: sound_data, error: nil)
        
        self.audioPlayer.play()
    }
    
    // MARK: - MEMELib Delegates
    
    func memeRealTimeModeDataReceived(data: MEMERealTimeData!) {
        println(data)
        
        if data.fitError != 0 {
            // 装着状態に異常あり
            return
        }
        if data.isWalking == 1 {
            playSE("coin",stop:true);
        }
    }

}
