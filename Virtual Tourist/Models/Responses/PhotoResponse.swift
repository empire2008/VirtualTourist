//
//  PhotoResponse.swift
//  Virtual Tourist
//
//  Created by SpaCE_MAC on 3/9/2562 BE.
//  Copyright © 2562 SpaCE_MAC. All rights reserved.
//

import Foundation

struct PhotoResponse: Codable {
    let photos: Photos
    let stat: String
}

struct Photos: Codable{
    let page: Int
    let pages: String
    let perpage: String
    let total: String
    let photo: [Photo]
    
}

struct Photo: Codable{
    let id: String
    let owner: String
    let secret: String
    let server: String
    let farm: Int
    let title: String
    let ispublic: Int
    let isfriend: Int
    let isfamily: Int
}
