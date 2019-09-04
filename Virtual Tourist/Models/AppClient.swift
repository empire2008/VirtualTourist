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
        case fetchPhoto(String)
        
        var stringValue: String{
            switch self {
            case .base: return Endpoint.baseUrl
            case .fetchPhoto(let bbox): return Endpoint.baseUrl + "&bbox=\(bbox)&format=json"
            }
        }
        
        var url: URL{
            return URL(string: stringValue)!
        }
    }
    
    class func requestPhoto(bbox: String, complition: @escaping (FlickerPhotos?, Error?) -> Void){
        let photoRequest = PhotoSearchRequest(bbox: bbox)
        let body = try? JSONEncoder().encode(photoRequest)
        
        var request = URLRequest(url: Endpoint.base.url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        print("Request = \(request)")
        
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


