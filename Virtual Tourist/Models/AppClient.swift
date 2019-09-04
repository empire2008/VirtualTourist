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
        case photosGeo
        
        var stringValue: String{
            switch self {
            case .photosGeo: return "\(Auth.baseApi)?method=flickr.photos.search&api_key=\(Auth.key)"
            }
        }
        
        var url: URL{
            return URL(string: stringValue)!
        }
    }
    
    class func requestPhoto(bbox: String, complition: @escaping (FlickerPhotos?, Error?) -> Void){
        let photoRequest = PhotoSearchRequest(bbox: bbox)
        let body = try? JSONEncoder().encode(photoRequest)
        
        var request = URLRequest(url: Endpoint.photosGeo.url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else{
                DispatchQueue.main.async {
                    complition(nil, error)
                }
                return
            }
            do{
                let responseObject = try JSONDecoder().decode(FlickerPhotos.self, from: data)
                print(responseObject.photos.photo[0].url)
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


