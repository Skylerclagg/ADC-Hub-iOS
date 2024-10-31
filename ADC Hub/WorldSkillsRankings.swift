//
//  WorldSkillsRankings.swift
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
    let additional_ranking: Int?
    let driver: Int
    let programming: Int
    let highest_driver: Int
    let highest_programming: Int
    let combined: Int

    init(world_skills: WorldSkills, ranking: Int, additional_ranking: Int? = nil) {
        self.number = world_skills.team.number
        self.ranking = ranking
        self.additional_ranking = additional_ranking
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
                if let additionalRanking = team_world_skills.additional_ranking {
                    Text("#\(team_world_skills.ranking) (#\(additionalRanking))")
                        .font(.system(size: 18))
                } else {
                    Text("#\(team_world_skills.ranking)")
                        .font(.system(size: 18))
                }
                Spacer()
            }
            .frame(width: 80)
            Spacer()
            Text("\(team_world_skills.number)")
                .font(.system(size: 18))
            Spacer()
            HStack {
                Menu("\(team_world_skills.combined)") {
                    Text("\(team_world_skills.combined) Combined")
                    Text("\(team_world_skills.programming) Autonomous Flight")
                    Text("\(team_world_skills.driver) Piloting")
                    Text("\(team_world_skills.highest_programming) Highest Autonomous Flight")
                    Text("\(team_world_skills.highest_driver) Highest Piloting")
                }
                .font(.system(size: 18))
                HStack {
                    Spacer()
                    VStack {
                        Text("\(team_world_skills.programming)")
                            .font(.system(size: 10))
                        Text("\(team_world_skills.driver)")
                            .font(.system(size: 10))
                    }
                }
                .frame(width: 30)
            }
            .frame(width: 80)
        }
    }
}

class WorldSkillsTeams: ObservableObject {
    @Published var world_skills_teams: [WorldSkillsTeam] = []


    private var region: Int = 0
    private var letter: Character = "0"
    private var filter_array: [String] = []
    private var gradeLevel: String = "High School" // Default to High School


    func loadWorldSkillsData(region: Int = 0, letter: Character = "0", filter_array: [String] = [], gradeLevel: String) {
        self.region = region
        self.letter = letter
        self.filter_array = filter_array
        self.gradeLevel = gradeLevel

        DispatchQueue.global(qos: .userInitiated).async {
            var skillsCache: WorldSkillsCache
            switch self.gradeLevel {
            case "Middle School":
                skillsCache = API.middle_school_world_skills_cache
            case "High School":
                skillsCache = API.high_school_world_skills_cache
            default:
                skillsCache = API.high_school_world_skills_cache
            }

            var teamsToProcess = skillsCache.teams

            if !self.filter_array.isEmpty {
                teamsToProcess = teamsToProcess.filter { self.filter_array.contains($0.team.number) }
            }
            if self.region != 0 {
                teamsToProcess = teamsToProcess.filter { $0.event_region_id == self.region }
            }
            if self.letter != "0" {
                teamsToProcess = teamsToProcess.filter { $0.team.number.last == self.letter }
            }

            var worldSkillsTeams = [WorldSkillsTeam]()
            var rank = 1
            for team in teamsToProcess {
                let isFilterApplied = !self.filter_array.isEmpty || self.region != 0 || self.letter != "0"
                let additionalRanking = isFilterApplied ? team.ranking : nil
                let worldSkillsTeam = WorldSkillsTeam(world_skills: team, ranking: rank, additional_ranking: additionalRanking)
                worldSkillsTeams.append(worldSkillsTeam)
                rank += 1
            }

            // Update the published property on the main thread
            DispatchQueue.main.async {
                self.world_skills_teams = worldSkillsTeams
            }
        }
    }
}

struct WorldSkillsRankings: View {
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var favorites: FavoriteStorage
    @EnvironmentObject var navigation_bar_manager: NavigationBarManager

    @State private var display_skills = "World Skills"
    @State private var region_id = 0
    @State private var letter: Character = "0"
    @State private var grade_level = UserSettings.getGradeLevel()
    @State private var selected_season: Int = API.selected_season_id()

    @StateObject private var world_skills_rankings = WorldSkillsTeams()

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

            // Season Picker
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
                        loadData()
                    }
                } else {
                    Text("No seasons available")
                }
            }

            // Filter Menu
            Menu("Filter") {
                // Favorites Filter
                if !favorites.teams_as_array().isEmpty {
                    Button("Favorites") {
                        applyFilter(filterArray: favorites.teams_as_array(), filterName: "Favorites Skills")
                    }
                }

                // Region Filter
                Menu("Region") {
                    Button("World") {
                        clearFilters()
                    }
                    ForEach(API.regions_map.sorted(by: <), id: \.key) { region, id in
                        Button(region) {
                            applyFilter(regionID: id, filterName: "\(region) Skills")
                        }
                    }
                }

                Button("Clear Filters") {
                    clearFilters()
                }
            }
            .fontWeight(.medium)
            .font(.system(size: 19))
            .padding(5)

            // Display List or Loading Indicator
            if world_skills_rankings.world_skills_teams.isEmpty {
                ProgressView("Loading Skills Rankings...")
            } else {
                List(world_skills_rankings.world_skills_teams) { team in
                    WorldSkillsRow(team_world_skills: team)
                }
            }
        }
        .navigationTitle(display_skills)
        .onAppear {
            navigation_bar_manager.title = display_skills
            loadData()
        }
    }

    private func loadData() {
        // Indicate that data is loading
        world_skills_rankings.world_skills_teams = []

        API.populate_all_world_skills_caches {
            self.world_skills_rankings.loadWorldSkillsData(region: self.region_id, letter: self.letter, filter_array: [], gradeLevel: self.grade_level)
        }
    }

    private func updateWorldSkillsForGrade(grade: String) {
        world_skills_rankings.loadWorldSkillsData(region: region_id, letter: letter, filter_array: [], gradeLevel: grade)
    }

    private func applyFilter(regionID: Int = 0, filterArray: [String] = [], filterName: String) {
        display_skills = filterName
        navigation_bar_manager.title = display_skills
        region_id = regionID
        letter = "0"
        world_skills_rankings.loadWorldSkillsData(region: region_id, letter: letter, filter_array: filterArray, gradeLevel: grade_level)
    }

    private func clearFilters() {
        display_skills = "World Skills"
        navigation_bar_manager.title = display_skills
        region_id = 0
        letter = "0"
        world_skills_rankings.loadWorldSkillsData(region: region_id, letter: letter, filter_array: [], gradeLevel: grade_level)
    }
}
