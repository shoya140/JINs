//
//  AccessInfo.swift
//  BoccoDemo
//
//  Created by 吉田悠一郎 on 2015/07/25.
//  Copyright © 2015年 吉田悠一郎. All rights reserved.
//

import Foundation

class AccessInfo {
    
    private var id:String = ""
    private var accessToken:String = ""
    private var roomId:String = ""
    
    init(id:String, token:String, rid:String) {
        self.id = id
        self.accessToken = token
        self.roomId = rid
    }
    
    func setId(id:String) {
        self.id = id
    }
    
    func getId() -> String {
        return id
    }

    
    func setAccessToken(token:String) {
        self.accessToken = token
    }
    
    func getAccessToken() -> String {
        return accessToken
    }
    
    func setRoomId(id:String) {
        roomId = id
    }
    
    func getRoomId() -> String {
        return roomId
    }
}