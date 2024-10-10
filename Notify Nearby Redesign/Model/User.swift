//
//  User.swift
//  Notify Nearby Redesign
//
//  Created by Noman Ikram on 11/09/2018.
//  Copyright © 2018 nomanikram. All rights reserved.
//

import Foundation
import SwiftyJSON

// Class for managing user related data
class User{
    var name:String?
    var contact:String?
    var email:String?
    var profileImgURL : String?
    var userType: String?
    
    var followers: [String]?
    var following: [String]?
    var favourite: [String]?
    
    var address:String?
    
    var address_latitude:Double?
    var address_longitude:Double?
    
   
    var events: [String]?
    
//    var interest = [String]()
    
    // static: - Because i want this data to be accessible in every class
    static var singleton = User()
    
    // JSON Parsing
    init(json:JSON) {
        name = json["name"].stringValue as! String
        email = json["email"].stringValue as! String
        userType = json["userType"].stringValue as! String
        contact = json["contact"].stringValue as! String
        profileImgURL = json["profileImageUrl"].stringValue
        address = json["address"].stringValue
    }
    
     init(){
        
    }
}
