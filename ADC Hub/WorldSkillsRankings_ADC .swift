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

    init(teams: [WorldSkills] = []) {
        self.world_skills_teams = teams.map { WorldSkillsTeam(world_skills: $0, ranking: $0.ranking) }
    }
    
    func updateTeams(teams: [WorldSkills]) {
        self.world_skills_teams = teams.map { WorldSkillsTeam(world_skills: $0, ranking: $0.ranking) }
    }
}

struct WorldSkillsRankings: View {
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var favorites: FavoriteStorage
    @EnvironmentObject var navigation_bar_manager: NavigationBarManager
    
    @ObservedObject private var world_skills_rankings = WorldSkillsTeams()  // Use @ObservedObject
    
    @State private var display_skills = "World Skills"
    @State private var region_id = 0
    @State private var letter: Character = "0"
    @State private var season_id = API.selected_season_id()
    @State private var grade_level = UserSettings.getGradeLevel()
    @State private var show_leaderboard = false
    @State private var importing = true

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            Section("Grade Level") {
                Picker("Grade Level", selection: $grade_level) {
                    Text("MS").tag("Middle School")
                    Text("HS").tag("High School")
                }
                .pickerStyle(.segmented)
                .padding([.top, .bottom], 5)
                .onChange(of: grade_level) { grade in
                    print("Grade level changed to: \(grade)")
                    updateWorldSkillsForGrade(grade: grade)
                }
            }

            if importing && API.world_skills_cache.teams.isEmpty {
                ImportingData()
                    .onReceive(timer) { _ in
                        if API.imported_skills {
                            print("Data imported, updating teams")
                            world_skills_rankings.updateTeams(teams: API.world_skills_cache.teams)
                            importing = false
                        }
                    }
            } else if !importing && API.world_skills_cache.teams.isEmpty {
                NoData()
            } else {
                // Season Filter
                Menu("Filter") {
                    if API.season_id_map.isEmpty {
                        ProgressView()
                    } else {
                        // Season Filter
                        Menu("Season") {
                            Picker("Season", selection: $season_id) {
                                ForEach(API.season_id_map[0].keys.sorted().reversed(), id: \.self) { season_id in
                                    Text(API.season_id_map[0][season_id] ?? "Unknown").tag(season_id)
                                }
                            }
                            .onChange(of: season_id) { newSeason in
                                print("Selected season: \(newSeason)")
                                updateWorldSkillsForSeason(newSeason: newSeason)
                            }
                        }
                    }

                    // Favorites Filter
                    if !favorites.teams_as_array().isEmpty {
                        Button("Favorites") {
                            display_skills = "Favorites Skills"
                            navigation_bar_manager.title = display_skills
                            region_id = 0
                            letter = "0"
                            world_skills_rankings.updateTeams(teams: API.world_skills_cache.teams.filter { favorites.teams_as_array().contains($0.team.number) })
                        }
                    }

                    // Region Filter
                    Menu("Region") {
                        Button("World") {
                            display_skills = "World Skills"
                            navigation_bar_manager.title = display_skills
                            region_id = 0
                            letter = "0"
                            world_skills_rankings.updateTeams(teams: API.world_skills_cache.teams)
                        }
                        ForEach(API.regions_map.sorted(by: <), id: \.key) { region, id in
                            Button(region) {
                                display_skills = "\(region) Skills"
                                navigation_bar_manager.title = display_skills
                                region_id = id
                                letter = "0"
                                world_skills_rankings.updateTeams(teams: API.world_skills_cache.teams.filter { $0.event_region_id == id })
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
                                world_skills_rankings.updateTeams(teams: API.world_skills_cache.teams.filter { $0.team.number.last == char.first! })
                            }
                        }
                    }

                    Button("Clear Filters") {
                        display_skills = "World Skills"
                        navigation_bar_manager.title = display_skills
                        region_id = 0
                        letter = "0"
                        world_skills_rankings.updateTeams(teams: API.world_skills_cache.teams)
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
        }
        .onAppear {
            print("View appeared, populating caches and displaying data")
            self.show_leaderboard = true
            navigation_bar_manager.title = display_skills
            API.populate_all_world_skills_caches()
            if (API.selected_season_id() != season_id) || (UserSettings.getGradeLevel() != grade_level) || world_skills_rankings.world_skills_teams.isEmpty {
                display_skills = "World Skills"
                navigation_bar_manager.title = display_skills
                region_id = 0
                letter = "0"
                world_skills_rankings.updateTeams(teams: API.world_skills_cache.teams)
                season_id = API.selected_season_id()
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
                    if !API.middle_school_world_skills_cache.teams.isEmpty {
                        world_skills_rankings.updateTeams(teams: API.middle_school_world_skills_cache.teams)
                    }
                case "High School":
                    if !API.high_school_world_skills_cache.teams.isEmpty {
                        world_skills_rankings.updateTeams(teams: API.high_school_world_skills_cache.teams)
                    }
                default:
                    break
                }
                importing = false
            }
        }
    }
    
    private func updateWorldSkillsForSeason(newSeason: Int) {
        settings.setSelectedSeasonID(id: newSeason)
        API.current_skills_season_id = newSeason
        API.populate_all_world_skills_caches()
        updateWorldSkillsForGrade(grade: grade_level)
    }
}

struct WorldSkillsRankings_Previews: PreviewProvider {
    static var previews: some View {
        WorldSkillsRankings()
    }
}
