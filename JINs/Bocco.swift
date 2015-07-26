//
//  Bocco.swift
//  BoccoDemo
//
//  Created by 吉田悠一郎 on 2015/07/25.
//  Copyright © 2015年 吉田悠一郎. All rights reserved.
//

import Foundation

class Bocco {
    
    private var accessInfo:AccessInfo = AccessInfo(uid: "", token: "", rid: "")
    
    private var appServerUrlString = "http://nodejs.moe.hm:3000/user_activity_log_summary"
    
    private let uniqueIdLength = 36
    
    internal func uploadDatas(info:AccessInfo) {
        accessInfo = info
        
        let paramId = "?userId=" + accessInfo.getUserId()
        appServerUrlString += paramId
        let url = NSURL(string: appServerUrlString)!
        let request = NSMutableURLRequest(URL: url)
        
        request.HTTPMethod = "GET"
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: { data, response, error in
            if (error == nil) {
                self.postTodayDatas(data!)
            } else {
                print(error)
            }
        })
        task.resume()
    }
    
    private func postTodayDatas(todayDatas:NSData) {
        var todayDatasArray = NSArray();
        
        var error:NSError? = nil
        let jsonObject: AnyObject = NSJSONSerialization.JSONObjectWithData(todayDatas, options: NSJSONReadingOptions.MutableContainers, error:&error)!
            todayDatasArray = jsonObject as! NSArray
        
        let roomId = accessInfo.getRoomId()
        let urlString = "https://api.bocco.me/1/rooms/" + roomId + "/messages"
        let request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
        
        request.HTTPMethod = "POST"
        
        let paramToken = "access_token=" + accessInfo.getAccessToken() + "&"
        let paramText = "text=" + (todayDatasArray[0]["message"] as! String) + "&"
        var randomUniqueId = ""
        for (var i = 0; i < uniqueIdLength; i++) {
            let rand = Int(arc4random_uniform(UInt32(10)))
            randomUniqueId += String(rand)
        }
        let paramUniqueId = "unique_id=" + randomUniqueId + "&"
        let paramMedia = "media=" + "text"
        
        let params = paramToken + paramText + paramUniqueId + paramMedia
        let uploadData = params.dataUsingEncoding(NSUTF8StringEncoding)
        request.HTTPBody = uploadData

        let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: {data, response, error in
            if (error == nil) {
                let result = NSString(data: data!, encoding: NSUTF8StringEncoding)!
                print(result)
            } else {
                print(error)
            }
        })
        
        task.resume()
    }
}
