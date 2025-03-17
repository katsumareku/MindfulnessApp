//
//  APIService.swift
//  HelloWorldWatchApp
//
//  Created by Jacek Kaczmarek on 11/03/2025.
//

import Foundation

class APIService {
    static let shared = APIService()
    
    private let baseURL: String
    public private(set) var userId: Int?
    private let deviceId: String
    
    private init() {
        
#if targetEnvironment(simulator)
    self.baseURL = "http://10.33.79.108:5001/api"
#else
    self.baseURL = "http://10.33.79.108:5001/api" // For the local IP of the real device
#endif
        
        if let storedDeviceId = UserDefaults.standard.string(forKey: "device_id") {
                    self.deviceId = storedDeviceId
                } else {
                    self.deviceId = UUID().uuidString
                    UserDefaults.standard.set(self.deviceId, forKey: "device_id")
                }
    }
    
    // Register device and get user ID
    func registerDevice(completion: @escaping (Result<Int, Error>) -> Void) {
        print("Attempting to register device with ID: \(deviceId)")
        let url = URL(string: "\(baseURL)/users/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["device_id": deviceId]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            print("Registration response received: \(String(describing: response))")
            if let data = data {
                print("Registration data: \(String(data: data, encoding: .utf8) ?? "none")")
            }
            print("Registration error: \(String(describing: error))")
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let userId = json["user_id"] as? Int {
                    self.userId = userId
                    print("Successfully set userId to: \(userId)")
                    completion(.success(userId))
                } else {
                    completion(.failure(NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // Save meditation session
    func saveMeditationSession(duration: Int, focusRating: Int?, soundUsed: String?, completion: @escaping (Bool) -> Void) {
        guard let userId = userId else {
            // Register first if needed
            registerDevice { result in
                switch result {
                case .success:
                    // Try again with the user ID
                    self.saveMeditationSession(duration: duration, focusRating: focusRating, soundUsed: soundUsed, completion: completion)
                case .failure:
                    completion(false)
                }
            }
            return
        }
        
        let url = URL(string: "\(baseURL)/meditation/sessions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = [
            "user_id": userId,
            "duration": duration
        ]
        
        if let focusRating = focusRating {
            body["focus_rating"] = focusRating
        }
        
        if let soundUsed = soundUsed {
            body["sound_used"] = soundUsed
        }
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { _, _, error in
            completion(error == nil)
        }.resume()
    }
    
    func checkServerConnection(completion: @escaping (Bool) -> Void) {
        let url = URL(string: "\(baseURL)/health")! // Create a simple health endpoint
        
        URLSession.shared.dataTask(with: url) { _, response, error in
            let isConnected = error == nil && (response as? HTTPURLResponse)?.statusCode == 200
            completion(isConnected)
        }.resume()
    }
    
    // Get meditation goals
    func getMeditationGoal(completion: @escaping (Result<MeditationGoalResponse, Error>) -> Void) {
        print("Getting meditation goal. UserId: \(String(describing: userId))")
        
        guard let userId = userId else {
            // This shouldn't happen if registration worked
            print("No userId available, attempting registration")
            registerDevice { result in
                switch result {
                case .success(let newUserId):
                    print("Registration successful, userId: \(newUserId)")
                    self.getMeditationGoal(completion: completion)
                case .failure(let error):
                    print("Registration failed: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
            return
        }
        
        let urlString = "\(baseURL)/goals/goals?user_id=\(userId)"
        print("Fetching goal data from: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            completion(.failure(NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            print("Goal fetch response: \(String(describing: response))")
            if let data = data {
                print("Goal fetch data: \(String(data: data, encoding: .utf8) ?? "none")")
            }
            print("Goal fetch error: \(String(describing: error))")
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let goal = try decoder.decode(MeditationGoalResponse.self, from: data)
                print("Successfully decoded goal data: \(goal.dailyMinutes) minutes per day, \(goal.daysPerWeek) days per week")
                completion(.success(goal))
            } catch {
                print("Failed to decode goal data: \(error)")
                
                // Debugging - print the received JSON structure
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) {
                    print("Received JSON structure: \(json)")
                }
                
                completion(.failure(error))
            }
        }.resume()
    }
    
    // Get progress data
    func getProgressData(completion: @escaping (Result<ProgressResponse, Error>) -> Void) {
        guard let userId = userId else {
            registerDevice { result in
                switch result {
                case .success:
                    self.getProgressData(completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            return
        }
        
        let url = URL(string: "\(baseURL)/goals/progress?user_id=\(userId)")!
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let progress = try decoder.decode(ProgressResponse.self, from: data)
                completion(.success(progress))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

// Response Models
struct MeditationGoalResponse: Codable {
    let dailyMinutes: Int
    let daysPerWeek: Int
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case dailyMinutes = "daily_minutes"
        case daysPerWeek = "days_per_week"
        case updatedAt = "updated_at"
    }
}

struct ProgressResponse: Codable {
    let dailyGoalSeconds: Int
    let days: [DayProgress]
    let currentStreak: Int
    let longestStreak: Int
    
    enum CodingKeys: String, CodingKey {
        case dailyGoalSeconds = "daily_goal_seconds"
        case days
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
    }
}

struct DayProgress: Codable, Identifiable {
    var id: String { date }
    let date: String
    let totalSeconds: Int
    let goalCompleted: Bool
    let sessions: [SessionSummary]
    
    enum CodingKeys: String, CodingKey {
        case date
        case totalSeconds = "total_seconds"
        case goalCompleted = "goal_completed"
        case sessions
    }
}

struct SessionSummary: Codable, Identifiable {
    let id: Int
    let duration: Int
    let focusRating: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case duration
        case focusRating = "focus_rating"
    }
}
