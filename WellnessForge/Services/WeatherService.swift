import Foundation
import CoreLocation
import Combine

struct WeatherData {
    let temperature: Double
    let conditionCode: Int
    let conditionText: String
    let uvIndex: Int
    let humidity: Int
    let feelsLike: Double

    var wellnessImpact: String {
        switch conditionCode {
        case 0, 1:       return "Perfect conditions for outdoor WellnessForge activity."
        case 2, 3:       return "Partly cloudy — great for a brisk walk."
        case 45, 48:     return "Foggy — stay visible if exercising outside."
        case 51...67:    return "Rainy — ideal day for indoor training."
        case 71...77:    return "Snowy — low-impact indoor movement recommended."
        case 95, 96, 99: return "Thunderstorm — stay indoors and rest."
        default:         return "Check conditions before heading out."
        }
    }

    var conditionIcon: String {
        switch conditionCode {
        case 0:          return "sun.max.fill"
        case 1, 2:       return "cloud.sun.fill"
        case 3:          return "cloud.fill"
        case 45, 48:     return "cloud.fog.fill"
        case 51...67:    return "cloud.rain.fill"
        case 71...77:    return "cloud.snow.fill"
        case 80...82:    return "cloud.heavyrain.fill"
        case 95, 96, 99: return "cloud.bolt.rain.fill"
        default:         return "thermometer"
        }
    }
}

class WeatherService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var weather: WeatherData? = nil
    @Published var isLoading: Bool = false
    @Published var error: ForgeError? = nil

    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func fetchWeather() {
        isLoading = true
        error = nil
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task {
            await fetchWeatherWithRetry(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task {
            await MainActor.run { self.error = .weather("Location access failed. Using default.") }
            await fetchWeatherWithRetry(lat: 51.5074, lon: -0.1278)
        }
    }

    private func fetchWeatherWithRetry(lat: Double, lon: Double, retries: Int = 3) async {
        await MainActor.run { self.isLoading = true }
        
        for attempt in 0..<retries {
            do {
                let data = try await performFetch(lat: lat, lon: lon)
                let weather = try parseWeather(from: data)
                await MainActor.run {
                    self.weather = weather
                    self.isLoading = false
                    self.error = nil
                }
                return // Success
            } catch {
                if attempt == retries - 1 {
                    await MainActor.run {
                        self.isLoading = false
                        self.error = .network("Weather sync failed after multiple attempts.")
                    }
                } else {
                    try? await Task.sleep(nanoseconds: 1_000_000_000 * UInt64(attempt + 1))
                }
            }
        }
    }

    private func performFetch(lat: Double, lon: Double) async throws -> Data {
        let urlStr = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current_weather=true&hourly=relativehumidity_2m,apparent_temperature,uv_index"
        guard let url = URL(string: urlStr) else { throw ForgeError.weather("Invalid URL") }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ForgeError.network("Server returned error")
        }
        return data
    }

    private func parseWeather(from data: Data) throws -> WeatherData {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let current = json["current_weather"] as? [String: Any] else {
            throw ForgeError.weather("Invalid response format")
        }
        
        let temp = current["temperature"] as? Double ?? 0
        let code = current["weathercode"] as? Int ?? 0
        let hourly = json["hourly"] as? [String: Any]
        
        let uv = (hourly?["uv_index"] as? [Double])?.first.map { Int($0) } ?? 0
        let humidity = (hourly?["relativehumidity_2m"] as? [Int])?.first ?? 0
        let feels = (hourly?["apparent_temperature"] as? [Double])?.first ?? temp
        
        return WeatherData(
            temperature: temp, 
            conditionCode: code, 
            conditionText: conditionText(for: code),
            uvIndex: uv, 
            humidity: humidity, 
            feelsLike: feels
        )
    }

    private func conditionText(for code: Int) -> String {
        switch code {
        case 0: return "Clear Sky"
        case 1: return "Mainly Clear"
        case 2: return "Partly Cloudy"
        case 3: return "Overcast"
        case 45, 48: return "Foggy"
        case 51...55: return "Drizzle"
        case 61...65: return "Rain"
        case 71...75: return "Snow"
        case 80...82: return "Heavy Rain"
        case 95: return "Thunderstorm"
        default: return "Variable"
        }
    }
}
