//
//  JMPreferenceViewController.swift
//  JINs
//
//  Created by Shoya Ishimaru on 2015/07/25.
//  Copyright (c) 2015年 shoya140. All rights reserved.
//

import UIKit

class JMPreferenceViewController: UIViewController, MEMELibDelegate {
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var scanButton: UIButton!
    @IBOutlet weak var boccoImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        MEMELib.sharedInstance().delegate = self
        MEMELib.sharedInstance().addObserver(self, forKeyPath: "centralManagerEnabled", options: .New, context: nil)
        
        self.backButton.alpha = 0.0
    }
    
//    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
//        
//        if keyPath == "centralManagerEnabled" {
//            self.navigationItem.rightBarButtonItem?.enabled = true
//        }
//    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func scanButtonTapped(sender: AnyObject) {
        MEMELib.sharedInstance().startScanningPeripherals()
        SVProgressHUD.showWithStatus("Scanning")
    }
    
    @IBAction func backButtonTapped(sender: AnyObject) {
        SVProgressHUD.dismiss()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - MEMELib Delegates
    
    func memePeripheralFound(peripheral: CBPeripheral!) {
        NSLog("peripheral found %@", peripheral.identifier.UUIDString)
        
        // UUID決め打ちでつなぎます
        if peripheral.identifier.UUIDString == MEME_DEVICE_UUID {
            MEMELib.sharedInstance().connectPeripheral(peripheral)
            SVProgressHUD.showWithStatus("Connecting")
        }
    }
    
    func memePeripheralConnected(peripheral: CBPeripheral!) {
        NSLog("MEME Device Connected!")
        SVProgressHUD.showSuccessWithStatus("Cnnected!")
        MEMELib.sharedInstance().changeDataMode(MEME_COM_REALTIME)
        
        self.scanButton.setImage(UIImage(named: "disconnect_button"), forState: .Normal)
        self.boccoImageView.image = UIImage(named:"paring_bocco_paird")
        self.backButton.alpha = 1.0
    }
    
    func memePeripheralDisconnected(peripheral: CBPeripheral!) {
        NSLog("MEME Device Disconnected")
    }
    
    // MARK: - TableView Delegates
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

}
