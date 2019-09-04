//
//  PhotoResponse.swift
//  Virtual Tourist
//
//  Created by SpaCE_MAC on 3/9/2562 BE.
//  Copyright © 2562 SpaCE_MAC. All rights reserved.
//

import Foundation

struct FlickerPhotos: Codable {
    let photos: Photos
}

struct Photos: Codable{
    let page: Int
    let pages: Int
    let perpage: Int
    let total: String
    let photo: [Photo]
    
}

struct Photo: Codable{
    let id: String
    let title: String
    let url: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case url = "url_m"
    }
}
