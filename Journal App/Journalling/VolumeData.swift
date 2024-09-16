//
//  VolumeData.swift
//  Journal App
//
//  Created by Hui Ying on 22/04/2024.
//

import UIKit

class VolumeData: NSObject, Decodable {

    var quotes: String?
    var author: String?
    
    private enum CodingKeys: String, CodingKey{
        case quotes = "q"
        case author = "a"
    }
    
    
}
