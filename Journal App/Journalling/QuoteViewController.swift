//
//  QuoteViewController.swift
//  Journal App
//
//  Created by Hui Ying on 22/04/2024.
//

import UIKit
import CoreLocation

class QuoteViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var author: UILabel!
    @IBOutlet weak var quote: UILabel!
    
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var temperature: UILabel!
    @IBOutlet weak var cityName: UILabel!
    
    let WEATHER_API_KEY = "ce7489404d3679e03a2b5713017efb22"
    var locationManager = CLLocationManager()
    var latitude: Double?
    var longitude: Double?
    
    var indicator = UIActivityIndicatorView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add activity indicator view
        indicator.style = UIActivityIndicatorView.Style.large
        indicator.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(indicator)
        // set constraints
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo:
                    view.safeAreaLayoutGuide.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
        indicator.startAnimating()
            
    }

    override func viewWillAppear(_ animated: Bool) {
        loadQuote()
        
        let authorisationStatus = locationManager.authorizationStatus
            if authorisationStatus != .authorizedWhenInUse {
                locationManager.requestWhenInUseAuthorization()
                indicator.stopAnimating()
            } else {
                locationManager = CLLocationManager()
                locationManager.delegate = self
                locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
            }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: Quote
    
    // Request a random quote and decode
    func loadQuote(){
        guard let url = URL(string: "https://zenquotes.io/api/random/") else { return }
        let request = URLRequest(url: url)
        Task {
            do {
                // fetch quote
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let res = response as? HTTPURLResponse,
                      res.statusCode == 200 else {
                    print("Response Body:", String(data: data, encoding: .utf8) ?? "")
                    throw LoadError.invalidServerResponse
                }
                do {
                    // decode
                    let decoder = JSONDecoder()
                    let content = try decoder.decode([VolumeData].self, from: data)
                    if let author = content.first?.author {
                        if author == "unknown" {
                            self.author.text = ""
                        } else {
                            self.author.text = author
                        }}
                    if let quote = content.first?.quotes {
                        self.quote.text = quote
                    }
                } catch {}
            }
            catch {
                print(error.localizedDescription)
            }
        }
    }
    
    // MARK: Location Manager
    
    // CLLocationManagerDelegate method
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // get last location
        if let location = locations.last {
            // get the lat and long
            latitude = location.coordinate.latitude
            longitude = location.coordinate.longitude
            // stop updating location
            locationManager.stopUpdatingLocation()
            Task {
                // load weather with the lat and long
                await loadWeather()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            print("Location permission not determined.")
        case .restricted, .denied:
            indicator.stopAnimating()
            print("Location permission restricted or denied.")
        case .authorizedWhenInUse, .authorizedAlways:
            print("Location permission granted.")
            locationManager.startUpdatingLocation()
        @unknown default:
            break
        }
    }
    
    // MARK: Weather
    
    func loadWeather() async {
        // use lat and long to build url
        if let latitude = latitude, let longitude = longitude {
            guard let weatherURL = URL(string: "https://api.openweathermap.org/data/2.5/forecast?lat=\(latitude)&lon=\(longitude)&appid=\(WEATHER_API_KEY)") else { return }
            let weatherReq = URLRequest(url: weatherURL)
            Task {
                do {
                    // request weather data
                    let (data, response) = try await URLSession.shared.data(for: weatherReq)
                    guard let res = response as? HTTPURLResponse,
                          res.statusCode == 200 else {
                        print("Response Body:", String(data: data, encoding: .utf8) ?? "")
                        throw LoadError.invalidServerResponse
                    }
                    // decode weather data
                    do {
                        let decoder = JSONDecoder()
                        let content = try decoder.decode(WeatherData.self, from: data)
                        if let forecasts = content.forecast , let city = content.city {
                            print("City: \(city.name ?? "Unknown")")
                            cityName.text = city.name
                            // summarize the list of weather data
                            summarizeNextDayForecast(forecastData: forecasts)
                        }
                    }
                }
                catch {
                    print(error.localizedDescription)
                }
            }
        }
        
    }
    
    // summarize the weather data
    func summarizeNextDayForecast(forecastData: [ForecastData]) {
        // get the current date
        let calendar = Calendar.current
        let today = Date()
        // calculate the next day
        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: today) else { return }
        
        var nextDayForecasts = [ForecastData]()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        // if the date time string of the forecast data exists
        // and is the same day as the next day
        for forecast in forecastData {
            if let dtString = forecast.dt_txt,
               let forecastDate = dateFormatter.date(from: dtString),
               calendar.isDate(forecastDate, inSameDayAs: nextDay) {
                // append the forecast data into the list
                nextDayForecasts.append(forecast)
            }
        }
        
        // If the list is empty
        if nextDayForecasts.isEmpty {
            print("No forecast data available for the next day.")
            return
        }
        
        // Summarize weather conditions
        var iconCount: [String: Int] = [:]
        var tempSum: Double = 0.0
        var count: Double = 0.0
        
        // loop through the list of firecast data to
        for forecast in nextDayForecasts {
            // count the occurence of weather icon
            if let icon = forecast.weather_icon {
                iconCount[icon, default: 0] += 1
            }
            // calculate the average temperature
            if let temp = forecast.temp {
                tempSum += temp
                count += 1
            }
        }
        
        // get the most common icon and the average temperature
        let averageTemp = String(format: "%.1f", (count > 0 ? tempSum / count : 0.0) - 273.15)
        let mostCommonIcon = iconCount.max(by: { $0.value <= $1.value })?.key ?? "Unknown"

        temperature.text = averageTemp + "°C"
        // use the common icon
        fetchiconImage(iconID: mostCommonIcon)
    }
    
    // fetch the icon image suing the icon id
    func fetchiconImage(iconID: String){
        guard let url = URL(string: "https://openweathermap.org/img/wn/\(iconID)@2x.png") else { return }
        let iconReq = URLRequest(url: url)
        Task {
            do {
                // request icon id
                let (data, response) = try await URLSession.shared.data(for: iconReq)
                guard let res = response as? HTTPURLResponse,
                      res.statusCode == 200 else {
                    print("Response Body:", String(data: data, encoding: .utf8) ?? "")
                    throw LoadError.invalidServerResponse
                }
                // create UIImage using the data
                if let image = UIImage(data: data) {
                    icon.image = image
                    indicator.stopAnimating()
                } else {
                    print("Failed to decode image data")
                }
            }
            
            catch {
                print(error.localizedDescription)
            }
        }
    }

    enum LoadError : Error {
        case invalidServerResponse
        case invalidURL
    }

}
