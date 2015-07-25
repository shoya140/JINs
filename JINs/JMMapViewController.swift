//
//  JMMapViewController.swift
//  JINs
//
//  Created by Shoya Ishimaru on 2015/07/25.
//  Copyright (c) 2015年 shoya140. All rights reserved.
//

import UIKit
import AVFoundation
import CoreLocation

class JMMapViewController: UIViewController, MEMELibDelegate, CLLocationManagerDelegate{
    
    enum Condition {
        case Walking
        case Running
        case BadPosture
    }
    
    @IBOutlet weak var debugTextView: UITextView!
    
    var _audioPlayer:AVAudioPlayer! = nil
    var _timerForFetchingStandardData:NSTimer?
    var _condition:Condition = .Walking
    var _badPostureCount:Int = 0
    var _runningCount:Int = 0
    var _lastStepTimestamp:NSDate = NSDate()
    
    var _locationManager = CLLocationManager()
    var _currentLocation: CLLocation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _timerForFetchingStandardData = nil
        
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest
        _locationManager.distanceFilter = 10.0
        _locationManager.delegate = self
        startSearchLocation()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        MEMELib.sharedInstance().delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func startSearchLocation(){
        let status = CLLocationManager.authorizationStatus()
        switch status{
        case .Restricted, .Denied:
            break
        case .NotDetermined:
            if _locationManager.respondsToSelector("requestWhenInUseAuthorization"){
                _locationManager.requestWhenInUseAuthorization()
            }else{
                _locationManager.startUpdatingLocation()
            }
        case .AuthorizedWhenInUse, .AuthorizedAlways:
            _locationManager.startUpdatingLocation()
        default:
            break
        }
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
        self.debugTextView.text = NSString(format: "%@", data) as String
        if _timerForFetchingStandardData == nil {
            _timerForFetchingStandardData = NSTimer.scheduledTimerWithTimeInterval(60.0, target: self, selector: Selector("fetchStandardData:"), userInfo: nil, repeats: false)
        }
        
        if data.fitError != 0 {
            // 装着状態に異常あり
            return
        }
        
        if data.isWalking == 1 {
            _condition = .Walking
            if data.pitch > 25 {
                _badPostureCount += 1
            }else{
                _badPostureCount = 0
            }
            if _badPostureCount > 2 {
                _condition = .BadPosture
            }
            
            if Double(NSDate().timeIntervalSinceDate(_lastStepTimestamp)) < 0.5{
                _runningCount += 1
            }else{
                _runningCount = 0
            }
            _lastStepTimestamp = NSDate()
            if _runningCount > 2 {
                _condition = .Running
            }
            
            switch _condition {
            case .Running:
                playSE("running",stop:true)
            case .BadPosture:
                playSE("poison",stop:true)
            default:
                playSE("coin", stop:true)
            }
        }
    }
    
    func memeStandardModeDataReceived(data: MEMEStandardData!) {
        println(data)
        MEMELib.sharedInstance().changeDataMode(MEME_COM_REALTIME)
        _timerForFetchingStandardData = nil
    }
    
    // MARK: - Location Manager Delegates
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        switch status{
        case .Restricted, .Denied:
            manager.stopUpdatingLocation()
        case .AuthorizedWhenInUse, .AuthorizedAlways:
            _locationManager.startUpdatingLocation()
        default:
            break
        }
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        if locations.count > 0{
            _currentLocation = locations.last as? CLLocation
            NSLog("lat:\(_currentLocation?.coordinate.latitude) long:\(_currentLocation?.coordinate.longitude)")
        }
    }
}
