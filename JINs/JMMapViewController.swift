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
    
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var preferenceButton: UIButton!
    
    @IBOutlet weak var debugTextView: UITextView!
    @IBOutlet weak var boccoImageView: UIImageView!
    @IBOutlet weak var mapWebView: UIWebView!
    @IBOutlet weak var statusContainerView: UIView!
    @IBOutlet weak var saveContainerView: UIView!
    @IBOutlet weak var preferenceContainerView: UIView!
    
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
    
    var _stepCount = 140
    var _isNuma = false
    
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
        
        debugTextView.font = UIFont(name:"PixelMplus12", size: 18)
        statusContainerView.layer.cornerRadius = 5.0
        statusContainerView.layer.masksToBounds = true
        statusContainerView.layer.borderColor = UIColor.whiteColor().CGColor
        statusContainerView.layer.borderWidth = 2.0
        
        saveContainerView.layer.cornerRadius = 5.0
        saveContainerView.layer.masksToBounds = true
        saveContainerView.layer.borderColor = UIColor.whiteColor().CGColor
        saveContainerView.layer.borderWidth = 2.0
        
        preferenceContainerView.layer.cornerRadius = 5.0
        preferenceContainerView.layer.masksToBounds = true
        preferenceContainerView.layer.borderColor = UIColor.whiteColor().CGColor
        preferenceContainerView.layer.borderWidth = 2.0
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
        let longitude:Double = _currentLocation!.coordinate.longitude
        let timestamp:Double = NSDate().timeIntervalSince1970
        
        var map:String = "10"
        if _isNuma {
            map = "22"
        }
        _isNuma = false
        
        NSDate().timeIntervalSince1970
        let params:Dictionary<String, String> = [
            "userId": "6186A470-0EFA-4CE6-894E-4AAC03B50E03",
            "mapChipId": map,
            "latitude":NSString(format: "%f", latitude) as String,
            "longitude":NSString(format: "%f", longitude) as String,
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
        let info = AccessInfo(uid:BOCCO_ACCESS_ID, token: BOCCO_ACCESS_TOKEN, rid: BOCCO_ACCESS_RID);
        let bocco = Bocco();
        bocco.uploadDatas(info)
        
        var alert: UIAlertController = UIAlertController(title: "セーブ完了", message: "Boccoが冒険の記録を教えてくれるよ", preferredStyle: UIAlertControllerStyle.Alert)
        let cancel: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler:nil)
        alert.addAction(cancel)
        presentViewController(alert, animated: true, completion: nil)
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
            _condition = .Walking
            if data.pitch > 25 {
                _badPostureCount += 1
            }else{
                _badPostureCount = 0
            }
            if _badPostureCount > 3 {
                _condition = .BadPosture
                _isNuma = true
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
            
            _stepCount += 1
            var text = NSString(format:"ＬＶ: 12\nＨＰ: 60/100\nじょうたい: けんこう\nそうほすう: %dほ", _stepCount) as String
            self.debugTextView.text = text
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
