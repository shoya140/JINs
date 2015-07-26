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
        case Speepy
        case LookingAround
    }
    
    enum Step {
        case Stop
        case Left
        case Right
    }
    
    @IBOutlet weak var saveButton: FUIButton!
    @IBOutlet weak var preferenceButton: FUIButton!
    
    @IBOutlet weak var debugTextView: UITextView!
    @IBOutlet weak var boccoImageView: UIImageView!
    @IBOutlet weak var mapWebView: UIWebView!

    var _audioPlayer:AVAudioPlayer! = nil
    var _timerForFetchingStandardData:NSTimer?
    var _condition:Condition = .Walking
    var _badPostureCount:Int = 0
    var _runningCount:Int = 0
    var _lastStepTimestamp:NSDate = NSDate()
    
    var _step:Step = .Stop
    
    var _sleepiness:Int = 1 // 1, 2, 3
    
    var _locationManager = CLLocationManager()
    var _currentLocation: CLLocation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _timerForFetchingStandardData = nil
        
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest
        _locationManager.distanceFilter = 10.0
        _locationManager.delegate = self
        startSearchLocation()
        
        let request = NSURLRequest(URL: NSURL(string: "http://nodejs.moe.hm:3000/")!)
        self.mapWebView.loadRequest(request)
        self.view.sendSubviewToBack(self.mapWebView)
        
        saveButton.buttonColor = UIColor.turquoiseColor()
        saveButton.shadowColor = UIColor.greenSeaColor()
        saveButton.shadowHeight = 3.0
        saveButton.cornerRadius = 2.0
        saveButton.titleLabel!.font = UIFont(name:"PixelMplus12", size: 18)
        saveButton.setTitleColor(UIColor.cloudsColor(), forState: UIControlState.Normal)
        saveButton.setTitleColor(UIColor.cloudsColor(), forState: UIControlState.Highlighted)
        
        preferenceButton.buttonColor = UIColor.turquoiseColor()
        preferenceButton.shadowColor = UIColor.greenSeaColor()
        preferenceButton.shadowHeight = 3.0
        preferenceButton.cornerRadius = 2.0
        preferenceButton.titleLabel!.font = UIFont(name:"PixelMplus12", size: 18)
        preferenceButton.setTitleColor(UIColor.cloudsColor(), forState: UIControlState.Normal)
        preferenceButton.setTitleColor(UIColor.cloudsColor(), forState: UIControlState.Highlighted)
        
        debugTextView.font = UIFont(name:"PixelMplus12", size: 16)
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
    
    func sendMaptipToServer(){
        // conditionをmaptipに変換して送信する
        
        let latitude:Double = _currentLocation!.coordinate.latitude
        let longtitude:Double = _currentLocation!.coordinate.longitude
        let timestamp:Double = NSDate().timeIntervalSince1970
        
        NSDate().timeIntervalSince1970
        let params:Dictionary<String, String> = [
            "userId": "6186A470-0EFA-4CE6-894E-4AAC03B50E03",
            "mapChipId": "1",
            "latitude":NSString(format: "%f", latitude) as String,
            "longtitude":NSString(format: "%f", longtitude) as String,
            "createDate": NSString(format: "%f", timestamp) as String
        ]
        let manager:AFHTTPRequestOperationManager = AFHTTPRequestOperationManager()
        manager.requestSerializer = AFJSONRequestSerializer()
        manager.POST("http://nodejs.moe.hm:3000/user_map/", parameters: params,
            success: {(operation: AFHTTPRequestOperation!, res: AnyObject!) in
                println("POST Success!!")
                println(res)
            },
            failure: {(operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error!!")
            }
        )
    }
    
    @IBAction func saveButtonTapped(sender: AnyObject) {
        
        let info = AccessInfo(id:BOCCO_ACCESS_ID, token: BOCCO_ACCESS_TOKEN, rid: BOCCO_ACCESS_RID);
        let bocco = Bocco();
        bocco.uploadDatas(info)
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
            
            switch _step{
            case .Stop, .Left:
                _step = .Right
                self.boccoImageView.image = UIImage(named: "bocco_right")
            case .Right:
                _step = .Left
                self.boccoImageView.image = UIImage(named: "bocco_left")
            }
        }
        
        if Double(NSDate().timeIntervalSinceDate(_lastStepTimestamp)) > 1.2{
            _step = .Stop
            self.boccoImageView.image = UIImage(named: "bocco_stop")
        }
    }
    
    func memeStandardModeDataReceived(data: MEMEStandardData!) {
        println(data)
        _sleepiness = Int(data.sleepy.value)
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
            sendMaptipToServer()
        }
    }
}
