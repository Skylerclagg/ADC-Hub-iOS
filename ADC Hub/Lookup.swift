//
//  TeamLookup.swift
//
//  ADC Hub
//
//  Based on
//  VRC RoboScout by William Castro
//
//  Created by Skyler Clagg on 9/26/24.
//

import SwiftUI
import OrderedCollections
import CoreML

struct TeamInfo: Identifiable {
    let id = UUID()
    let property: String
    let value: String
}

struct TeamInfoRow: View {
    var team_info: TeamInfo
    
    var body: some View {
        HStack{
            Text(team_info.property)
            Spacer()
            Text(team_info.value)
        }
    }
}

struct Lookup: View {
    
    @Binding var lookup_type: Int
    
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var favorites: FavoriteStorage
    @EnvironmentObject var dataController: ADCHubDataController
    @EnvironmentObject var navigation_bar_manager: NavigationBarManager
    @State private var selected_season: Int = API.selected_season_id()
    
    var body: some View {
        VStack {
            Picker("Lookup", selection: $lookup_type) {
                Text("Teams").tag(0)
                Text("Events").tag(1)
            }.pickerStyle(.segmented).padding()
            Spacer()
            if lookup_type == 0 {
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
                                DispatchQueue.main.async {
                                }
                            }
                        }
                    } else {
                        Text("No seasons available")
                    }
                }
                TeamLookup()
                    .environmentObject(favorites)
                    .environmentObject(settings)
                    .environmentObject(dataController)
               
            }
            else if lookup_type == 1 {
                EventLookup()
                    .environmentObject(favorites)
                    .environmentObject(settings)
                    .environmentObject(dataController)
            }
        }.onAppear{
            navigation_bar_manager.title = "Lookup"
        }
    }
}

struct EventLookup: View {
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var favorites: FavoriteStorage
    @EnvironmentObject var dataController: ADCHubDataController
    
    @StateObject private var eventSearch = EventSearch(season_query: API.selected_season_id())
    @State private var name_query: String = ""
    @State private var region_query: String = ""  // Store region name, will map this to ID
    @State private var level_query: String = ""   // Level filter, e.g., "Regional" or "All"
    @State private var selected_season: Int = API.selected_season_id() // Selected season ID
    @State private var showFilters = false // To toggle the display of filter options

    var body: some View {
        VStack {
            // Search Bar for Event Name
            TextField("Event Name", text: $name_query, onCommit: {
                applyFilters()
            })
            .frame(alignment: .center)
            .multilineTextAlignment(.center)
            .font(.system(size: 36))
            .padding()

            // Filters Button with Nested Menus
            Menu("Filters") {
                // Season Filter Menu
                Menu("Select Season") {
                    ForEach(API.season_id_map[UserSettings.getGradeLevel() != "College" ? 0 : 1].keys.sorted().reversed(), id: \.self) { season_id in
                        Button(format_season_option(raw: API.season_id_map[UserSettings.getGradeLevel() != "College" ? 0 : 1][season_id] ?? "Unknown")) {
                            selected_season = season_id
                            fetchNewEventsForSeason()  // Fetch the new events for the selected season
                        }
                    }
                }
                .frame(alignment: .center)
                .multilineTextAlignment(.center)
                .font(.system(size: 20))
                .padding()

                // Level Filter Menu (Regional and All)
                Menu("Select Level") {
                    Button("All") {
                        level_query = ""  // Clear the level filter for "All"
                        applyFilters()
                    }
                    Button("Regional") {
                        level_query = "Regional"  // Set filter to "Regional"
                        applyFilters()
                    }
                }

                // Region Filter Menu - Alphabetized
                Menu("Select Region") {
                    ForEach(eventSearch.regions_map.sorted(), id: \.self) { region_name in
                        Button(region_name) {
                            region_query = region_name
                            applyFilters()
                        }
                    }
                }
                // Clear Filters Option
                Button("Clear Filters") {
                                name_query = ""
                                region_query = ""
                                level_query = ""
                                selected_season = API.selected_season_id() // Reset to the default season
                                applyFilters()
                        }
            }
            .font(.system(size: 20))
            .padding()

            // Event List
            List(eventSearch.event_indexes, id: \.self) { event_index in
                EventRow(event: eventSearch.filtered_events[Int(event_index)!])
                    .environmentObject(dataController)
            }
        }
        .onAppear {
            // When the view appears, load and display events
            applyFilters()
        }
    }

    // Helper function to format the season option
    func format_season_option(raw: String) -> String {
        let yearRange = raw.split(separator: "-")
        if yearRange.count == 2 {
            return "\(yearRange[0])-\(yearRange[1].suffix(2))"
        }
        return raw
    }
    

    // Apply filters (name, region, level, and season)
    // Apply filters (name, region, level, and season)
    private func applyFilters() {
        print("Applying Filters: Name: \(name_query), Region: \(region_query), Level: \(level_query), Season: \(selected_season)")
        
        // Check if the season has changed
        if selected_season != API.selected_season_id() {
            fetchNewEventsForSeason() // Reload events for the selected season
        } else {
            // Filter events using existing data if the season hasn't changed
            eventSearch.filter_events(name_query: name_query, region_query: region_query, level_query: level_query)
        }
    }
    // Function to fetch new events for the selected season
    private func fetchNewEventsForSeason() {
        print("Fetching new events for season: \(selected_season)")
        
        // Clear existing events to avoid showing stale data
        eventSearch.all_events.removeAll()
        eventSearch.filtered_events.removeAll()
        eventSearch.event_indexes.removeAll()
        
        // Fetch the events for the selected season
        let data = ADCHubAPI.robotevents_request(request_url: "/seasons/\(selected_season)/events?page=1&per_page=250")
        
        // Populate the event search object with the newly fetched data
        for event_data in data {
            eventSearch.all_events.append(Event(fetch: false, data: event_data))
        }
        
        // Apply filters to the new list of events, if necessary
        eventSearch.filter_events(name_query: name_query, region_query: region_query, level_query: level_query)
        
        // Debugging: Check the count of fetched and filtered events
        print("Fetched \(eventSearch.all_events.count) events for season \(selected_season)")
        print("Filtered Events Count: \(eventSearch.filtered_events.count)")
    

    }
}

class EventSearch: ObservableObject {
    @Published var event_indexes: [String] = []
    @Published var all_events: [Event] = []  // Store all events fetched from the API
    @Published var filtered_events: [Event] = []  // Filtered events to be displayed
    @Published var regions_map: [String] = [] // Store the unique regions

    init(season_query: Int? = nil) {
        // Fetch all events for the selected season
        let data = ADCHubAPI.robotevents_request(request_url: "/seasons/\(season_query ?? API.selected_season_id())/events?")

        for event_data in data {
            // Initialize Event objects from the API response
            let event = Event(fetch: false, data: event_data)
            all_events.append(event)

            // Add region to the regions_map if it's not already there
            if !event.region.isEmpty && !regions_map.contains(event.region) {
                regions_map.append(event.region)
                print("region map:", regions_map)
                print("event.region", event.region)
            }
        }

        // Initially, display all events
        filtered_events = all_events
        update_event_indexes()
    }

    // Update event indexes for SwiftUI List
    private func update_event_indexes() {
        event_indexes.removeAll()
        for (index, _) in filtered_events.enumerated() {
            event_indexes.append(String(index))
        }
    }
    
    // Filter events locally by name, region, and level
    func filter_events(name_query: String, region_query: String, level_query: String) {
        print("Filtering Events - Name: \(name_query), Region: \(region_query), Level: \(level_query)")
        
        filtered_events = all_events.filter { event in
            var matches = true

            // Name filter
            if !name_query.isEmpty {
                matches = matches && event.name.lowercased().contains(name_query.lowercased())
            }

            // Region filter
            if !region_query.isEmpty {
                matches = matches && event.region.lowercased().contains(region_query.lowercased())
                print("Event Region: \(event.region), Selected Region: \(region_query)")
            }

            // Level filter
            if !level_query.isEmpty {
                matches = matches && event.level.lowercased() == level_query.lowercased()
                print("Event Level: \(event.level), Selected Level: \(level_query)")
            }

            return matches
        }

        update_event_indexes()
        print("Filtered Events Count: \(filtered_events.count)")
    }
}


struct TeamLookup: View {
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var favorites: FavoriteStorage
    @EnvironmentObject var dataController: ADCHubDataController
    
    @State var team_number: String
    @State var favorited: Bool = false
    @State var fetch: Bool
    @State var fetched: Bool = false
    @State private var team: Team = Team()
    @State private var world_skills = WorldSkills()
    @State private var avg_rank: Double = 0.0
    @State private var award_counts = OrderedDictionary<String, Int>()
    @State private var showLoading: Bool = false
    @State private var showingSheet = false
    @State private var editable: Bool
    @State private var selected_season: Int = API.selected_season_id()

    
    init(team_number: String = "", editable: Bool = true, fetch: Bool = false) {
        self._team_number = State(initialValue: team_number)
        self._editable = State(initialValue: editable)
        self._fetch = State(initialValue: fetch)
    }
    
    
    func fetch_info(number: String) {
        hideKeyboard()
        
        showLoading = true
        team_number = number.uppercased()
        
        DispatchQueue.global(qos: .userInteractive).async { [self] in
            
            let fetched_team = Team(number: number)
            
            if fetched_team.id == 0 {
                DispatchQueue.main.async {
                    showLoading = false
                }
                return
            }
            
            let fetched_world_skills = API.world_skills_for(team: fetched_team) ?? WorldSkills(team: fetched_team, data: [String: Any]())
            let fetched_avg_rank = fetched_team.average_ranking()
            fetched_team.fetch_awards()
            
            fetched_team.awards.sort(by: {
                $0.order < $1.order
            })
            
            var fetched_award_counts = OrderedDictionary<String, Int>()
            for award in fetched_team.awards {
                fetched_award_counts[award.title] = (fetched_award_counts[award.title] ?? 0) + 1
            }
            
            let is_favorited = favorites.favorite_teams.contains(fetched_team.number)
            
            DispatchQueue.main.async {
                team = fetched_team
                world_skills = fetched_world_skills
                avg_rank = fetched_avg_rank
                award_counts = fetched_award_counts
                favorited = is_favorited
                
                showLoading = false
                fetched = true
            }
        }
    }
    
    // Computed property to get world skills data and teams count
    var worldSkillsData: (worldSkills: WorldSkills, teamsCount: Int) {
        // First, try to find the team in the primary cache
        if let skills = API.high_school_world_skills_cache.teams.first(where: { $0.team.id == team.id }) {
            return (worldSkills: skills, teamsCount: API.high_school_world_skills_cache.teams.count)
        }
        // If not found, try to find the team in the secondary cache
        else if let skills = API.middle_school_world_skills_cache.teams.first(where: { $0.team.id == team.id }) {
            return (worldSkills: skills, teamsCount: API.middle_school_world_skills_cache.teams.count)
        }
        // If the team is not found in either cache
        else {
            // Return a default WorldSkills object and a teams count of zero
            return (worldSkills: WorldSkills(team: team), teamsCount: 0)
        }
    }
    
    var body: some View {
        VStack {
            
            HStack {
                if fetched && team.id != 0 {
                    Link(destination: URL(string: "https://www.robotevents.com/teams/ADC/\(team.number)")!) {
                        Image(systemName: "link").font(.system(size: 25)).padding(20).opacity(fetched ? 1 : 0)
                    }
                }
                TextField(
                    "12345a",
                    text: $team_number,
                    onEditingChanged: { _ in
                        team = Team()
                        world_skills = WorldSkills(team: Team())
                        avg_rank = 0.0
                        fetched = false
                        favorited = false
                        showLoading = false
                    },
                    onCommit: {
                        showLoading = true
                        fetch_info(number: team_number)
                    }
                ).disabled(!editable)
                .frame(alignment: .center)
                .multilineTextAlignment(.center)
                .font(.system(size: 36))
                .onAppear{
                    if fetch {
                        fetch_info(number: team_number)
                        fetch = false
                    }
                }
                Button(action: {
                    if team_number == "" {
                        return
                    }
                    
                    showLoading = true
                    
                    hideKeyboard()
                    team_number = team_number.uppercased()
                    if team.number != team_number {
                        fetch_info(number: team_number)
                        showLoading = true
                    }
                    
                    if team.number != team_number {
                        return
                    }
                    
                    if let index = favorites.favorite_teams.firstIndex(of: team.number) {
                        favorites.favorite_teams.remove(at: index)
                        favorites.sort_teams()
                        defaults.set(favorites.favorite_teams, forKey: "favorite_teams")
                        favorited = false
                        showLoading = false
                        return
                    }
                    Task {
                        favorites.favorite_teams.append(team_number)
                        favorites.sort_teams()
                        defaults.set(favorites.favorite_teams, forKey: "favorite_teams")
                        favorited = true
                        showLoading = false
                    }
                }, label: {
                    if favorited {
                        Image(systemName: "star.fill").font(.system(size: 25))
                    }
                    else {
                        Image(systemName: "star").font(.system(size: 25))
                    }
                }).padding(20)
            }
            VStack {
                if showLoading {
                    ProgressView()
                }
            }.frame(height: 10)
            List {
                Group {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(team.name)
                    }
                    HStack {
                        Text("Drone Name")
                        Spacer()
                        Text(team.robot_name)
                    }
                    HStack {
                        Text("Organization")
                        Spacer()
                        Text(team.organization)
                    }
                    HStack {
                        Text("Location")
                        Spacer()
                        Text(fetched ? "\(team.city), \(team.region)" : "")
                    }
                }
                HStack {
                    Text("World Skills Ranking")
                    Spacer()
                    Text(fetched ? (worldSkillsData.worldSkills.ranking != 0 ? "# \(worldSkillsData.worldSkills.ranking) of \(worldSkillsData.teamsCount)" : "No Data Available") : "")
                }
                HStack {
                    Menu("World Skills Score") {
                        Text("\(worldSkillsData.worldSkills.driver) Piloting")
                        Text("\(worldSkillsData.worldSkills.programming) Autonomous Flight")
                        Text("\(worldSkillsData.worldSkills.highest_driver) Highest Piloting")
                        Text("\(worldSkillsData.worldSkills.highest_programming) Highest Autonomous Flight")
                    }
                    Spacer()
                    Text(fetched ?( worldSkillsData.worldSkills.ranking != 0 ? "\(worldSkillsData.worldSkills.combined)" : "No Data Available") : "")
                }
                HStack {
                    Text("Awards")
                    Spacer()
                    Text(fetched ? "\(self.team.awards.count)" : "")
                };if editable {
                HStack {
                    NavigationLink(destination: TeamEventsView(team_number: team.number).environmentObject(settings).environmentObject(dataController)) {
                        Text("Events")
                    }
                }
            }
        }
    }.tint(settings.buttonColor())
        }
    }


struct Lookup_Previews: PreviewProvider {
    static var previews: some View {
        Lookup(lookup_type: .constant(0))
    }
}
