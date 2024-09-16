//
//  ForecastData.swift
//  Journal App
//
//  Created by Hui Ying on 03/06/2024.
//

import UIKit

class ForecastData: NSObject, Decodable {
    
    var weather_main : String?
    var weather_desc : String?
    var weather_icon : String?
    var dt_txt: String?
    var temp: Double?
    
    private enum ForecastKeys: String, CodingKey {
        case weather
        case dt_txt
        case main
    }
    
    private enum WeatherKeys: String, CodingKey {
        case main
        case description
        case icon
    }
    
    private enum MainKeys: String, CodingKey {
            case temp
        }
    
    required init(from decoder: Decoder) throws {
            
        let rootContainer = try decoder.container(keyedBy: ForecastKeys.self)
        
        var weatherContainer = try rootContainer.nestedUnkeyedContainer(forKey: .weather)
                
        if let firstWeather = try? weatherContainer.nestedContainer(keyedBy: WeatherKeys.self) {
            weather_main = try firstWeather.decode(String.self, forKey: .main)
            weather_desc = try? firstWeather.decode(String.self, forKey: .description)
            weather_icon = try? firstWeather.decode(String.self, forKey: .icon)
        }
        
        dt_txt = try? rootContainer.decode(String.self, forKey: .dt_txt)
        
        let mainContainer = try rootContainer.nestedContainer(keyedBy: MainKeys.self, forKey: .main)
        temp = try? mainContainer.decode(Double.self, forKey: .temp)
            
    }
    
}
