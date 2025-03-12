//
//  APIService.swift
//  HelloWorldWatchApp
//
//  Created by Jacek Kaczmarek on 11/03/2025.
//

import Foundation

class APIService {
    static let shared = APIService()
    
    private let baseURL = "http://localhost:5001/api"
    private var userId: Int?
    private let deviceId: String
    
    private init() {
        if let storedDeviceId = UserDefaults.standard.string(forKey: "device_id") {
                    self.deviceId = storedDeviceId
                } else {
                    self.deviceId = UUID().uuidString
                    UserDefaults.standard.set(self.deviceId, forKey: "device_id")
                }
    }
    
    // Register device and get user ID
    func registerDevice(completion: @escaping (Result<Int, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/users/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["device_id": deviceId]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
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
    
    // Get meditation goals
    func getMeditationGoal(completion: @escaping (Result<MeditationGoalResponse, Error>) -> Void) {
        guard let userId = userId else {
            registerDevice { result in
                switch result {
                case .success:
                    self.getMeditationGoal(completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            return
        }
        
        let url = URL(string: "\(baseURL)/goals/goals?user_id=\(userId)")!
        
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
                let goal = try decoder.decode(MeditationGoalResponse.self, from: data)
                completion(.success(goal))
            } catch {
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
