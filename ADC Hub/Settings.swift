//
//  Settings.swift
//
//  ADC Hub
//
//  Based on
//  VRC RoboScout by William Castro
//
//  Created by Skyler Clagg on 9/26/24.
//

import SwiftUI
import CoreData

struct Settings: View {
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var favorites: FavoriteStorage
    @EnvironmentObject var dataController: ADCHubDataController
    @EnvironmentObject var navigation_bar_manager: NavigationBarManager
   
    
    @State var selected_button_color = UserSettings().buttonColor()
    @State var selected_top_bar_color = UserSettings().topBarColor()
    @State var selected_top_bar_content_color = UserSettings().topBarContentColor()
    @State var top_bar_content_color_changed = false
    @State var minimalistic = UserSettings.getMinimalistic()
    @State var grade_level = UserSettings.getGradeLevel()
    @State var selected_season_id = UserSettings.getSelectedSeasonID()
    @State var apiKey = UserSettings.getRobotEventsAPIKey() ?? ""
    @State var team_info_default_page = UserSettings.getTeamInfoDefaultPage() == "statistics"
    @State var match_team_default_page = UserSettings.getMatchTeamDefaultPage() == "statistics"
    @State var showLoading = false
    @State var showApply = false
    @State var clearedTeams = false
    @State var clearedEvents = false
    @State var clearedNotes = false
    @State var confirmClearTeams = false
    @State var confirmClearEvents = false
    @State var confirmClearData = false
    @State var confirmClearNotes = false
    @State var confirmAppearance = false
    @State var confirmAPIKey = false
    
    var mode: String {
#if DEBUG
        return " DEBUG"
#else
        return ""
#endif
    }
    
    func format_season_option(raw: String) -> String {
        var season = raw
        season = season.replacingOccurrences(of: "ADC ", with: "")
        
        let season_split = season.split(separator: "-")
        
        if season_split.count == 1 {
            return season
        }
        
        return "\(season_split[0])-\(season_split[1].dropFirst(2))"
    }
    
    var body: some View {
        VStack {
            List {
                Section("Season Selector") {
                    HStack {
                        Spacer()
                        if showLoading || API.season_id_map.isEmpty {
                            ProgressView()
                        } else {
                            Picker("Season", selection: $selected_season_id) {
                                ForEach(API.season_id_map[0].keys.sorted().reversed(), id: \.self) { season_id in
                                    Text(format_season_option(raw: API.season_id_map[0][season_id] ?? "Unknown")).tag(season_id)
                                }
                            }
                            .labelsHidden()
                            .onChange(of: selected_season_id) { _ in
                                settings.setSelectedSeasonID(id: selected_season_id)
                                settings.updateUserDefaults(updateTopBarContentColor: false)
                                self.showLoading = false
                                DispatchQueue.global(qos: .userInteractive).async {
                                    API.populate_all_world_skills_caches()
                                    DispatchQueue.main.async {
                                        self.showLoading = false
                                    }
                                }
                            }
                        }
                        Spacer()
                    }
                }
                
                
                Section("Appearance") {
                    ColorPicker("Top Bar Color", selection: $selected_top_bar_color, supportsOpacity: false).onChange(of: selected_top_bar_color) { _ in
                        settings.setTopBarColor(color: selected_top_bar_color)
                        showApply = true
                    }
                    ColorPicker("Top Bar Content Color", selection: $selected_top_bar_content_color, supportsOpacity: false).onChange(of: selected_top_bar_content_color) { _ in
                        settings.setTopBarContentColor(color: selected_top_bar_content_color)
                        top_bar_content_color_changed = true
                        showApply = true
                    }
                    ColorPicker("Button and Tab Color", selection: $selected_button_color, supportsOpacity: false).onChange(of: selected_button_color) { _ in
                        settings.setButtonColor(color: selected_button_color)
                        showApply = true
                    }
                    Toggle("Minimalistic", isOn: $minimalistic).onChange(of: minimalistic) { _ in
                        settings.setMinimalistic(state: minimalistic)
                        showApply = true
                    }
                    if showApply {
                        Button("Apply changes") {
                            confirmAppearance = true
                        }
                        .confirmationDialog("Are you sure?", isPresented: $confirmAppearance) {
                            Button("Apply and close app?", role: .destructive) {
                                settings.updateUserDefaults(updateTopBarContentColor: top_bar_content_color_changed)
                                print("App Closing")
                                exit(0)
                            }
                        }
                    }
                }
                
                Section("Danger") {
                    Button("Clear favorite teams") {
                        confirmClearTeams = true
                    }
                    .alert(isPresented: $clearedTeams) {
                        Alert(title: Text("Cleared favorite teams"), dismissButton: .default(Text("OK")))
                    }
                    .confirmationDialog("Are you sure?", isPresented: $confirmClearTeams) {
                        Button("Clear ALL favorited teams?", role: .destructive) {
                            defaults.set([String](), forKey: "favorite_teams")
                            favorites.favorite_teams = [String]()
                            clearedTeams = true
                            print("Favorite teams cleared")
                        }
                    }
                    Button("Clear favorite events") {
                        confirmClearEvents = true
                    }
                    .alert(isPresented: $clearedEvents) {
                        Alert(title: Text("Cleared favorite events"), dismissButton: .default(Text("OK")))
                    }
                    .confirmationDialog("Are you sure?", isPresented: $confirmClearEvents) {
                        Button("Clear ALL favorited events?", role: .destructive) {
                            defaults.set([String](), forKey: "favorite_events")
                            favorites.favorite_events = [String]()
                            clearedEvents = true
                            print("Favorite events cleared")
                        }
                    }
                    Button("Clear all match notes") {
                        confirmClearNotes = true
                    }
                    .alert(isPresented: $clearedNotes) {
                        Alert(title: Text("Cleared match notes"), dismissButton: .default(Text("OK")))
                    }
                    .confirmationDialog("Are you sure?", isPresented: $confirmClearNotes) {
                        Button("Clear ALL match notes?", role: .destructive) {
                            dataController.deleteAllNotes()
                            clearedNotes = true
                        }
                    }
                }
                
                Section("Developer") {
                                        HStack {
                        Text("Version")
                        Spacer()
                        Text("\(UIApplication.appVersion!) (\(UIApplication.appBuildNumber!))\(self.mode)")
                    }
                }
                
                Section("Developed by Skyler Clagg, based on Teams Ace 229V and Jelly 2733J's VRC Roboscout") {}
            }
//            Link("Join the Discord Server", destination: URL(string: "https://discord.gg/KczJZUfs5f")!).padding()
        }
        .onAppear {
            navigation_bar_manager.title = "Settings"
            settings.readUserDefaults()
        }
    }
    
    struct Settings_Previews: PreviewProvider {
        static var previews: some View {
            Settings()
        }
    }
}
