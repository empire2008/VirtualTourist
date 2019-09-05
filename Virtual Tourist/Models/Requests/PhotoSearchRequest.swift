//
//  PhotoSearchRequest.swift
//  Virtual Tourist
//
//  Created by SpaCE_MAC on 3/9/2562 BE.
//  Copyright © 2562 SpaCE_MAC. All rights reserved.
//

import Foundation

struct PhotoSearchRequest: Codable {
    let page: Int
    let perPage: Int
    let bbox: String
    
    enum CodingKeys: String, CodingKey {
        case page
        case perPage = "per_page"
        case bbox
    }
}
