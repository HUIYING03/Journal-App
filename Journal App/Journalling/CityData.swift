//
//  CityData.swift
//  Journal App
//
//  Created by Hui Ying on 03/06/2024.
//

import UIKit

class CityData: NSObject, Decodable {
    var name: String?
    
    private enum CityKeys: String, CodingKey {
        case name
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CityKeys.self)
        name = try container.decode(String.self, forKey: .name)
    }
}
