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

    var _audioPlayer:AVAudioPlayer! = nil
    var _timerForFetchingStandardData:NSTimer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        _timerForFetchingStandardData = nil
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
        if _audioPlayer != nil && _audioPlayer.playing == true {
            if stop == true{
                _audioPlayer.stop()
            }
        }
        let sound_data = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource(file_name, ofType: "mp3")!)
        _audioPlayer = AVAudioPlayer(contentsOfURL: sound_data, error: nil)
        _audioPlayer.play()
    }
    
    func fetchStandardData(timer:NSTimer){
        MEMELib.sharedInstance().changeDataMode(MEME_COM_STANDARD)
    }
    
    // MARK: - MEMELib Delegates
    
    func memeRealTimeModeDataReceived(data: MEMERealTimeData!) {
        if _timerForFetchingStandardData == nil {
            _timerForFetchingStandardData = NSTimer.scheduledTimerWithTimeInterval(60.0, target: self, selector: Selector("fetchStandardData:"), userInfo: nil, repeats: false)
        }
        
        if data.fitError != 0 {
            // 装着状態に異常あり
            return
        }
        if data.isWalking == 1 {
            playSE("coin",stop:true);
        }
    }
    
    func memeStandardModeDataReceived(data: MEMEStandardData!) {
        println(data)
        MEMELib.sharedInstance().changeDataMode(MEME_COM_REALTIME)
        _timerForFetchingStandardData = nil
    }

}
