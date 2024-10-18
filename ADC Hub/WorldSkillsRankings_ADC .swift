//
//  WorldSkillsRankings.swift
//
//  ADC Hub
//
//  Based on
//  VRC RoboScout by William Castro
//
//  Created by Skyler Clagg on 9/26/24.
//

import SwiftUI

struct WorldSkillsTeam: Identifiable, Hashable {
    let id = UUID()
    let number: String
    let ranking: Int
    let additional_ranking: Int
    let driver: Int
    let programming: Int
    let highest_driver: Int
    let highest_programming: Int
    let combined: Int
    
    init(world_skills: WorldSkills, ranking: Int, additional_ranking: Int? = nil) {
        self.number = world_skills.team.number
        self.ranking = ranking
        self.additional_ranking = additional_ranking ?? 0
        self.driver = world_skills.driver
        self.programming = world_skills.programming
        self.highest_driver = world_skills.highest_driver
        self.highest_programming = world_skills.highest_programming
        self.combined = world_skills.combined
    }
}

struct WorldSkillsRow: View {
    var team_world_skills: WorldSkillsTeam

    var body: some View {
        HStack {
            HStack {
                Text(team_world_skills.additional_ranking == 0 ? "#\(team_world_skills.ranking)" : "#\(team_world_skills.ranking) (#\(team_world_skills.additional_ranking))").font(.system(size: 18))
                Spacer()
            }.frame(width: 80)
            Spacer()
            Text("\(team_world_skills.number)").font(.system(size: 18))
            Spacer()
            HStack {
                Menu("\(team_world_skills.combined)") {
                    Text("\(team_world_skills.combined) Combined")
                    Text("\(team_world_skills.programming) Autonomous Flight")
                    Text("\(team_world_skills.driver) Piloting")
                    Text("\(team_world_skills.highest_programming) Highest Autonomous Flight")
                    Text("\(team_world_skills.highest_driver) Highest Piloting")
                }.font(.system(size: 18))
                HStack {
                    Spacer()
                    VStack {
                        Text(String(describing: team_world_skills.programming)).font(.system(size: 10))
                        Text(String(describing: team_world_skills.driver)).font(.system(size: 10))
                    }
                }.frame(width: 30)
            }.frame(width: 80)
        }
    }
}

class WorldSkillsTeams: ObservableObject {
    @Published var world_skills_teams: [WorldSkillsTeam]
        
        
        // Modify the initializer to accept a list of teams as a parameter
        init(teams: [WorldSkills] = [], region: Int = 0, letter: Character = "0", filter_array: [String] = [], fetch: Bool = false) {
            self.world_skills_teams = [WorldSkillsTeam]()
            
            if !teams.isEmpty {  // If teams are provided, initialize the object with them
                var rank = 1
                for team in teams {
                    self.world_skills_teams.append(WorldSkillsTeam(world_skills: team, ranking: rank))
                    rank += 1
                }
            } else if fetch {
                // Fallback to fetching teams if fetch is true
                let combinedTeams = API.update_combined_world_skills_cache()
                var rank = 1
                for team in combinedTeams {
                    self.world_skills_teams.append(WorldSkillsTeam(world_skills: team, ranking: rank))
                    rank += 1
                }
            } else {
                if filter_array.count != 0 {
                    var rank = 1
                    for team in API.world_skills_cache.teams {
                        if !filter_array.contains(team.team.number) {
                            continue
                        }
                        self.world_skills_teams.append(WorldSkillsTeam(world_skills: team, ranking: rank, additional_ranking: team.ranking))
                        rank += 1
                    }
                } else if region != 0 {
                    var rank = 1
                    for team in API.world_skills_cache.teams {
                        if region != team.event_region_id {
                            continue
                        }
                        self.world_skills_teams.append(WorldSkillsTeam(world_skills: team, ranking: rank, additional_ranking: team.ranking))
                        rank += 1
                    }
                } else if letter != "0" {
                    var rank = 1
                    for team in API.world_skills_cache.teams {
                        if letter != team.team.number.last {
                            continue
                        }
                        self.world_skills_teams.append(WorldSkillsTeam(world_skills: team, ranking: rank, additional_ranking: team.ranking))
                        rank += 1
                    }
                } else {
                    if API.world_skills_cache.teams.isEmpty {
                        return
                    }
                    for i in 0..<API.world_skills_cache.teams.count {
                        let team = API.world_skills_cache.teams[i]
                        self.world_skills_teams.append(WorldSkillsTeam(world_skills: team, ranking: team.ranking))
                    }
                }
            }
    }

    
    // Add this method to dynamically update teams
    func updateTeams(_ teams: [WorldSkills]) {
        self.world_skills_teams = teams.map { WorldSkillsTeam(world_skills: $0, ranking: $0.ranking) }
    }
}


struct WorldSkillsRankings: View {
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var favorites: FavoriteStorage
    @EnvironmentObject var navigation_bar_manager: NavigationBarManager

    @State private var display_skills = "World Skills"
    @State private var region_id = 0
    @State private var letter: Character = "0"
    @State private var world_skills_rankings = WorldSkillsTeams(fetch: false)
    @State private var grade_level = UserSettings.getGradeLevel()
    @State private var show_leaderboard = false
    @State private var importing = true
    @State private var selected_season: Int = API.selected_season_id()
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            // Grade Level Picker
            Section("Grade Level") {
                Picker("Grade Level", selection: $grade_level) {
                    Text("MS").tag("Middle School")
                    Text("HS").tag("High School")
                }
                .pickerStyle(.segmented)
                .padding([.top, .bottom], 5)
                .onChange(of: grade_level) { grade in
                    updateWorldSkillsForGrade(grade: grade)
                }
            }
            Section("Season") {
                if !API.season_id_map.isEmpty && !API.season_id_map[0].isEmpty {
                    Picker("Season", selection: $selected_season) {
                        ForEach(API.season_id_map[0].keys.sorted().reversed(), id: \.self) { season_id in
                            Text(API.season_id_map[0][season_id] ?? "Unknown").tag(season_id)
                        }
                    }
                    .onChange(of: selected_season) { _ in
                        settings.setSelectedSeasonID(id: selected_season)
                        settings.updateUserDefaults(updateTopBarContentColor: false)
                        DispatchQueue.global(qos: .userInteractive).async {
                            API.populate_all_world_skills_caches()
                            updateWorldSkillsForGrade(grade: grade_level)
                            DispatchQueue.main.async {
                            }
                        }
                    }
                } else {
                    Text("No seasons available")
                }
            }
            
            // Season Filter
            Menu("Filter") {
                // Favorites Filter
                if !favorites.teams_as_array().isEmpty {
                    Button("Favorites") {
                        display_skills = "Favorites Skills"
                        navigation_bar_manager.title = display_skills
                        region_id = 0
                        letter = "0"
                        world_skills_rankings = WorldSkillsTeams(filter_array: favorites.teams_as_array(), fetch: false)
                    }
                }
                
                // Region Filter
                Menu("Region") {
                    Button("World") {
                        display_skills = "World Skills"
                        navigation_bar_manager.title = display_skills
                        region_id = 0
                        letter = "0"
                        world_skills_rankings = WorldSkillsTeams(fetch: false)
                    }
                    ForEach(API.regions_map.sorted(by: <), id: \.key) { region, id in
                        Button(region) {
                            display_skills = "\(region) Skills"
                            navigation_bar_manager.title = display_skills
                            region_id = id
                            letter = "0"
                            world_skills_rankings = WorldSkillsTeams(region: id, fetch: false)
                        }
                    }
                }
                
                // Letter Filter
                Menu("Letter") {
                    ForEach(["A", "B", "C", "D", "E", "F", "G", "H", "J", "K", "L", "M", "N", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"], id: \.self) { char in
                        Button(char) {
                            display_skills = "\(char) Skills"
                            navigation_bar_manager.title = display_skills
                            letter = char.first!
                            world_skills_rankings = WorldSkillsTeams(letter: char.first!, fetch: false)
                        }
                    }
                }
                
                Button("Clear Filters") {
                    display_skills = "World Skills"
                    navigation_bar_manager.title = display_skills
                    region_id = 0
                    letter = "0"
                    world_skills_rankings = WorldSkillsTeams(fetch: false)
                }
            }
            .fontWeight(.medium)
            .font(.system(size: 19))
            .padding(20)
            
            if show_leaderboard {
                List(world_skills_rankings.world_skills_teams) { team in
                    WorldSkillsRow(team_world_skills: team)
                }
            }
        }
        .onAppear {
            self.show_leaderboard = true
            navigation_bar_manager.title = display_skills
            API.populate_all_world_skills_caches()
            if world_skills_rankings.world_skills_teams.isEmpty {
                world_skills_rankings = WorldSkillsTeams(fetch: false)
                grade_level = UserSettings.getGradeLevel()
            }
        }
        .onDisappear {
            show_leaderboard = false
        }
    }
    
    private func updateWorldSkillsForGrade(grade: String) {
        DispatchQueue.global(qos: .userInteractive).async {
            API.populate_all_world_skills_caches()
            DispatchQueue.main.async {
                switch grade {
                case "Middle School":
                    world_skills_rankings = WorldSkillsTeams(teams: API.middle_school_world_skills_cache.teams)
                case "High School":
                    world_skills_rankings = WorldSkillsTeams(teams: API.high_school_world_skills_cache.teams)
                default:
                    break
                }
                importing = false
            }
        }
    }
    
    private func updateWorldSkillsForSeason(newSeason: Int) {
        // Update the selected season in settings
        settings.setSelectedSeasonID(id: newSeason)
        API.current_skills_season_id = newSeason

        // Repopulate the caches for the new season
        API.populate_all_world_skills_caches()
        updateWorldSkillsForGrade(grade: grade_level)
    }
}
