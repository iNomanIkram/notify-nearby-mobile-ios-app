//
//  File.swift
//  Notify Nearby Redesign
//
//  Created by Noman Ikram on 10/10/2018.
//  Copyright © 2018 nomanikram. All rights reserved.
//

import Foundation
import SwiftyJSON

// Class Notification is storing Notification Related Data
class Notification{
    var storyId :String?
//    var storyname:String?
    
    var string : String?
    var type: String?
    var userID:String?
    var username:String?
    var profileImage:String?
    
    
    // JSON Parsing
    init(json: JSON) {
        storyId = json["sid"].stringValue
        string = json["string"].stringValue
        type = json["type"].stringValue
        userID =  json["userid"].stringValue
        
    }
}
