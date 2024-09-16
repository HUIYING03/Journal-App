//
//  WeatherData.swift
//  Journal App
//
//  Created by Hui Ying on 03/06/2024.
//

import UIKit

class WeatherData: NSObject, Decodable {
    var city: CityData?
    var forecast: [ForecastData]?
    
    private enum RootKeys: String, CodingKey {
        case city
        case forecast = "list"
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: RootKeys.self)
        city = try container.decode(CityData.self, forKey: .city)
        forecast = try container.decode([ForecastData].self, forKey: .forecast)
    }
}

