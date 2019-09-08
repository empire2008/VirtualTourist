//
//  UserDefaultsExtension.swift
//  Virtual Tourist
//
//  Created by SpaCE_MAC on 3/9/2562 BE.
//  Copyright © 2562 SpaCE_MAC. All rights reserved.
//

import Foundation

enum UserDefaultsKeys: String{
    case latitude
    case lontitude
    case latDelta
    case lonDelta
    case isNoData
}

extension UserDefaults{
    func setLatitude(value: Double){
        set(value, forKey: UserDefaultsKeys.latitude.rawValue)
    }
    func getLatitude() -> Double{
        return double(forKey: UserDefaultsKeys.latitude.rawValue)
    }
    
    func setLongitude(value: Double){
        set(value, forKey: UserDefaultsKeys.lontitude.rawValue)
    }
    func getLongitude() -> Double{
        return double(forKey: UserDefaultsKeys.lontitude.rawValue)
    }
    
    func setLatDelta(value: Double){
        set(value, forKey: UserDefaultsKeys.latDelta.rawValue)
    }
    func getLatDelta() -> Double{
        return double(forKey: UserDefaultsKeys.latDelta.rawValue)
    }
    
    func setLonDelta(value: Double){
        set(value, forKey: UserDefaultsKeys.lonDelta.rawValue)
    }
    func getLonDelta() -> Double{
        return double(forKey: UserDefaultsKeys.lonDelta.rawValue)
    }
    func setHasData(){
        set(true, forKey: UserDefaultsKeys.isNoData.rawValue)
    }
    func isHasData() -> Bool{
        return bool(forKey: UserDefaultsKeys.isNoData.rawValue)
    }
}
