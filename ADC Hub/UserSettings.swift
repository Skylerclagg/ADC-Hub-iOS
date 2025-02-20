//
//  UserSettings.swift
//
//  ADC Hub
//
//  Based on
//  VRC RoboScout by William Castro
//
//  Created by Skyler Clagg on 9/26/24.
//

import Foundation
import SwiftUI

let defaults = UserDefaults.standard

public extension UIColor {
    
    class func StringFromUIColor(color: UIColor) -> String {
        var components = color.cgColor.components
        while (components!.count < 4) {
            components!.append(1.0)
        }
        return "[\(components![0]), \(components![1]), \(components![2]), \(components![3])]"
    }
    
    class func UIColorFromString(string: String) -> UIColor {
        let componentsString = string
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")
        let components = componentsString.components(separatedBy: ", ")
        return UIColor(
            red: CGFloat((components[0] as NSString).floatValue),
            green: CGFloat((components[1] as NSString).floatValue),
            blue: CGFloat((components[2] as NSString).floatValue),
            alpha: CGFloat((components[3] as NSString).floatValue)
        )
    }
    
}

func getGreen() -> UIColor {
    #if os(iOS)
    return .systemGreen
    #else
    return .green
    #endif
}

class UserSettings: ObservableObject {
    
    // ==============================
    // NEW: Toggleable Haptics
    // ==============================
    @Published var enableHaptics = false  // Default OFF
    
    private var buttonColorString: String
    private var topBarColorString: String
    private var topBarContentColorString: String
    private var minimalistic: Bool
    private var adam_score: Bool
    private var grade_level: String
    private var team_info_default_page: String
    private var match_team_default_page: String
    private var selected_season_id: Int
    
    static var keyIndex = Int.random(in: 0..<10)
    
    init() {
        // Read stored color strings or fallback to default
        self.buttonColorString = defaults.object(forKey: "buttonColor") as? String
            ?? UIColor.StringFromUIColor(color: getGreen())
        self.topBarColorString = defaults.object(forKey: "topBarColor") as? String
            ?? UIColor.StringFromUIColor(color: getGreen())
        
        defaults.object(forKey: "minimalistic") as? Int ?? 1 == 1
            ? (self.minimalistic = true)
            : (self.minimalistic = false)
        
        self.topBarContentColorString = defaults.object(forKey: "topBarContentColor") as? String
            ?? UIColor.StringFromUIColor(color: self.minimalistic ? getGreen() : .white)
        
        defaults.object(forKey: "adam_score") as? Int ?? 1 == 1
            ? (self.adam_score = true)
            : (self.adam_score = false)
        
        self.grade_level = defaults.object(forKey: "grade_level") as? String
            ?? "High School"
        self.team_info_default_page = defaults.object(forKey: "team_info_default_page") as? String
            ?? "events"
        self.match_team_default_page = defaults.object(forKey: "match_team_default_page") as? String
            ?? "matches"
        self.selected_season_id = defaults.object(forKey: "selected_season_id") as? Int
            ?? API.active_season_id()
        
        // NEW: Read haptics toggle from UserDefaults (default false if not found).
        self.enableHaptics = defaults.bool(forKey: "enableHaptics")
    }
    
    func readUserDefaults() {
        self.buttonColorString = defaults.object(forKey: "buttonColor") as? String
            ?? UIColor.StringFromUIColor(color: getGreen())
        
        self.topBarColorString = defaults.object(forKey: "topBarColor") as? String
            ?? UIColor.StringFromUIColor(color: getGreen())
        
        defaults.object(forKey: "minimalistic") as? Int ?? 1 == 1
            ? (self.minimalistic = true)
            : (self.minimalistic = false)
        
        self.topBarContentColorString = defaults.object(forKey: "topBarContentColor") as? String
            ?? UIColor.StringFromUIColor(color: self.minimalistic ? getGreen() : .white)
        
        self.grade_level = defaults.object(forKey: "grade_level") as? String
            ?? "High School"
        
        self.team_info_default_page = defaults.object(forKey: "team_info_default_page") as? String
            ?? "events"
        
        self.match_team_default_page = defaults.object(forKey: "match_team_default_page") as? String
            ?? "matches"
        
        self.selected_season_id = defaults.object(forKey: "selected_season_id") as? Int
            ?? API.selected_season_id()
        
        // NEW: Re-read haptics
        self.enableHaptics = defaults.bool(forKey: "enableHaptics")
    }
    
    func updateUserDefaults(updateTopBarContentColor: Bool = false) {
        defaults.set(
            UIColor.StringFromUIColor(color: UIColor.UIColorFromString(string: self.buttonColorString)),
            forKey: "buttonColor"
        )
        defaults.set(
            UIColor.StringFromUIColor(color: UIColor.UIColorFromString(string: self.topBarColorString)),
            forKey: "topBarColor"
        )
        if updateTopBarContentColor {
            defaults.set(
                UIColor.StringFromUIColor(color: UIColor.UIColorFromString(string: self.topBarContentColorString)),
                forKey: "topBarContentColor"
            )
        }
        defaults.set(self.minimalistic ? 1 : 0, forKey: "minimalistic")
        defaults.set(self.grade_level, forKey: "grade_level")
        defaults.set(self.team_info_default_page, forKey: "team_info_default_page")
        defaults.set(self.match_team_default_page, forKey: "match_team_default_page")
        defaults.set(self.selected_season_id, forKey: "selected_season_id")
        
        // NEW: Persist haptics setting
        defaults.set(self.enableHaptics, forKey: "enableHaptics")
    }
    
    // MARK: - Setters
    
    func setButtonColor(color: SwiftUI.Color) {
        self.buttonColorString = UIColor.StringFromUIColor(color: UIColor(color))
    }
    
    func setTopBarColor(color: SwiftUI.Color) {
        self.topBarColorString = UIColor.StringFromUIColor(color: UIColor(color))
    }
    
    func setTopBarContentColor(color: SwiftUI.Color) {
        self.topBarContentColorString = UIColor.StringFromUIColor(color: UIColor(color))
    }
    
    func setMinimalistic(state: Bool) {
        self.minimalistic = state
    }
    
    func setGradeLevel(grade_level: String) {
        self.grade_level = grade_level
        API.update_world_skills_cache()
    }
    
    func setTeamInfoDefaultPage(page: String) {
        self.team_info_default_page = page
    }
    
    func setMatchTeamDefaultPage(page: String) {
        self.match_team_default_page = page
    }
    
    func setSelectedSeasonID(id: Int) {
        self.selected_season_id = id
    }
    
    // MARK: - Getters
    
    func buttonColor() -> SwiftUI.Color {
        if let colorString = defaults.object(forKey: "buttonColor") as? String {
            return Color(UIColor.UIColorFromString(string: colorString))
        } else {
            return Color(getGreen())
        }
    }
    
    func topBarColor() -> SwiftUI.Color {
        if let colorString = defaults.object(forKey: "topBarColor") as? String {
            return Color(UIColor.UIColorFromString(string: colorString))
        } else {
            return Color(getGreen())
        }
    }
    
    func topBarContentColor() -> SwiftUI.Color {
        if let colorString = defaults.object(forKey: "topBarContentColor") as? String {
            let color = Color(UIColor.UIColorFromString(string: colorString))
            return color != topBarColor() ? color : Color.white
        } else {
            if UserSettings.getMinimalistic() {
                return Color(getGreen())
            } else {
                return Color.white
            }
        }
    }
    
    func tabColor() -> SwiftUI.Color {
        if defaults.object(forKey: "minimalistic") as? Int ?? 1 == 1 {
            return Color(UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0))
        } else {
            return self.topBarColor()
        }
    }
    
    // MARK: - Static
    static func getRobotEventsAPIKey() -> String? {
        var robotevents_api_key: String? {
            if let environmentAPIKey = ProcessInfo.processInfo.environment["ROBOTEVENTS_API_KEY"] {
                defaults.set(environmentAPIKey, forKey: "robotevents_api_key")
                return environmentAPIKey
            } else if let defaultsAPIKey = defaults.object(forKey: "robotevents_api_key") as? String,
                      !defaultsAPIKey.isEmpty {
                return defaultsAPIKey
            } else if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
                      let config = NSDictionary(contentsOfFile: path) as? [String: Any] {
                return config["key\(self.keyIndex)"] as? String
            }
            return nil
        }
        return robotevents_api_key
    }
    
    static func getMinimalistic() -> Bool {
        return defaults.object(forKey: "minimalistic") as? Int ?? 1 == 1
    }
    
    static func getGradeLevel() -> String {
        return defaults.object(forKey: "grade_level") as? String ?? "High School"
    }
    
    static func getTeamInfoDefaultPage() -> String {
        return defaults.object(forKey: "team_info_default_page") as? String ?? "events"
    }
    
    static func getMatchTeamDefaultPage() -> String {
        return defaults.object(forKey: "match_team_default_page") as? String ?? "matches"
    }
    
    static func getSelectedSeasonID() -> Int {
        return defaults.object(forKey: "selected_season_id") as? Int ?? API.selected_season_id()
    }
}
