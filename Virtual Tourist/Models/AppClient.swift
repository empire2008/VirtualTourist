//
//  AppClient.swift
//  Virtual Tourist
//
//  Created by SpaCE_MAC on 3/9/2562 BE.
//  Copyright © 2562 SpaCE_MAC. All rights reserved.
//

import Foundation

class AppClient {
    struct Auth {
        static var key = "c1b22b2b4a8dafa97f79965fc923767c"
        static var secret = "6195661bb9f03882"
        static let baseApi = "https://api.flickr.com/services/rest/"
    }
    
    enum Endpoint {
        case photosGeo(String, String)
        
        var stringValue: String{
            switch self {
            case .photosGeo(let lat, let lon): return "\(Auth.baseApi)?method=flickr.photos.geo.photosForLocation&api_key=\(Auth.key)&lat=\(lat)&lon=\(lon)"
            }
        }
        
        var url: URL{
            return URL(string: stringValue)!
        }
    }
    
    class func requestPhoto(lat: String, lon: String, complition: @escaping ())
}


