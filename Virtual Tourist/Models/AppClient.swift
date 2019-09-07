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
    }
    
    enum Endpoint {
        static let baseUrl = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(Auth.key)"
        case base
        case fetchPhoto(Int, Double, Double)
        var stringValue: String{
            switch self {
            case .base: return Endpoint.baseUrl
            case .fetchPhoto(let page, let lat, let lon):
                return Endpoint.baseUrl + "&page=\(page)&per_page=21&bbox=\(getBbox(lat: lat, lon: lon))&extras=url_m&format=json&nojsoncallback=1&safe_search=1"
            }
        }
        
        func getBbox(lat: Double, lon: Double) -> String {
            //Remember: Longitude has a range of -180 to 180 , latitude of -90 to 90.
            let minLat = max(lat - 1, -90)
            let maxLat = min(lat + 1, 90)
            let minLon = max(lon - 1, -180)
            let maxLon = min(lon + 1, 180)
            return "\(minLon),\(minLat),\(maxLon),\(maxLat)"
        }
        
        var url: URL{
            return URL(string: stringValue)!
        }
    }
    
    class func requestPhoto(pinPoint: PinPoint, page: Int, complition: @escaping (FlickerPhotos?, Error?) -> Void){
        
        let task = URLSession.shared.dataTask(with: Endpoint.fetchPhoto(page, pinPoint.lat, pinPoint.lon).url) { data, response, error in
            guard let data = data else{
                DispatchQueue.main.async {
                    complition(nil, error)
                }
                return
            }
            do{
                let responseObject = try JSONDecoder().decode(FlickerPhotos.self, from: data)
                DispatchQueue.main.async {
                    complition(responseObject,nil)
                }
            }
            catch{
                complition(nil, error)
            }
            
        }
        task.resume()
    }
}


