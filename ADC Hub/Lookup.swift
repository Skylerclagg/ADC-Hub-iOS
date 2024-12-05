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

import SwiftUI

struct EventLookup: View {

    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var favorites: FavoriteStorage
    @EnvironmentObject var dataController: ADCHubDataController

    @StateObject private var eventSearch = EventSearch()
    @State private var selected_season: Int = API.selected_season_id()

    var body: some View {
        NavigationView {
            VStack {
                // Search Bar for Event Name
                TextField("Event Name", text: $eventSearch.name_query)
                    .frame(alignment: .center)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 36))
                    .padding()
                    .onChange(of: eventSearch.name_query) { _ in
                        eventSearch.filter_events()
                    }

                // Filters Menu
                Menu("Filters") {
                    // Season Filter Menu
                    Menu("Select Season") {
                        ForEach(API.season_id_map[0].keys.sorted().reversed(), id: \.self) { season_id in
                            Button(action: {
                                selected_season = season_id
                                eventSearch.fetch_events(season_query: selected_season)
                            }) {
                                Text(format_season_option(raw: API.season_id_map[0][season_id] ?? "Unknown"))
                            }
                        }
                    }
                    .font(.system(size: 20))
                    .padding()

                    // Level Filter Menu
                    Menu("Select Level") {
                        Button("All") {
                            eventSearch.level_query = ""
                            eventSearch.filter_events()
                        }
                        Button("Regional") {
                            eventSearch.level_query = "regional"
                            eventSearch.filter_events()
                        }
                        // Add more levels if needed
                    }

                    // Region Filter Menu
                    Menu("Select Region") {
                        Button("All Regions") {
                            eventSearch.region_query = ""
                            eventSearch.filter_events()
                        }
                        ForEach(eventSearch.regions_map, id: \.self) { region_name in
                            Button(action: {
                                eventSearch.region_query = region_name
                                eventSearch.filter_events()
                            }) {
                                Text(region_name)
                            }
                        }
                    }

                    // State Filter Menu
                    Menu("Select State") {
                        Button("All States") {
                            eventSearch.state_query = ""
                            eventSearch.filter_events()
                        }
                        ForEach(eventSearch.states_map, id: \.self) { state_name in
                            Button(action: {
                                eventSearch.state_query = state_name
                                eventSearch.filter_events()
                            }) {
                                Text(state_name)
                            }
                        }
                    }

                    // Date Filter Toggle
                    Button(action: {
                        // Toggle the date filter state
                        eventSearch.isDateFilterActive.toggle()
                        // Fetch events with the updated date filter
                        eventSearch.fetch_events(season_query: selected_season)
                    }) {
                        Text(eventSearch.isDateFilterActive ? "Remove Date Filter" : "Add Date Filter")
                    }

                    // Clear Filters Option
                    Button("Clear Filters") {
                        eventSearch.name_query = ""
                        eventSearch.region_query = ""
                        eventSearch.state_query = ""
                        eventSearch.level_query = ""
                        eventSearch.isDateFilterActive = true // Reset date filter to active
                        selected_season = API.selected_season_id()
                        eventSearch.fetch_events(season_query: selected_season)
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
                // Initialize selected_season with the value from eventSearch
                self.selected_season = eventSearch.selected_season
                eventSearch.fetch_events(season_query: selected_season)
            }
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
}





import Foundation
import SwiftUI

import Foundation
import SwiftUI

class EventSearch: ObservableObject {
    @Published var event_indexes: [String] = []
    @Published var all_events: [Event] = []
    @Published var filtered_events: [Event] = []
    @Published var states_map: [String] = []
    @Published var state_query: String = ""
    @Published var region_query: String = ""
    @Published var level_query: String = ""
    @Published var name_query: String = ""
    @Published var selected_season: Int
    @Published var isDateFilterActive: Bool = true
    
    // Regions and their associated states/provinces/territories
    let regions_map: [String] = [ "Northeast", "North Central", "Southeast", "South Central", "West"]
    
    let regionStatesMap: [String: [String]] = [
        "Northeast": [
            "Connecticut", "Delaware", "District of Columbia", "Kentucky", "Maryland", "Massachusetts",
            "Maine", "New Hampshire", "New Jersey", "New York", "Pennsylvania", "Rhode Island", "Vermont",
            "Virginia", "West Virginia",
            "Quebec", "Newfoundland and Labrador", "New Brunswick", "Prince Edward Island", "Nova Scotia"
        ],
        "North Central": [
            "Illinois", "Indiana", "Iowa", "Michigan", "Minnesota", "Nebraska", "North Dakota", "Ohio",
            "South Dakota", "Wisconsin",
            "Manitoba", "Ontario", "Nunavut"
        ],
        "Southeast": [
            "Alabama", "Arkansas", "Florida", "Georgia", "Louisiana", "Mississippi", "North Carolina",
            "South Carolina", "Tennessee"
        ],
        "South Central": [
            "Kansas", "Missouri", "New Mexico", "Oklahoma", "Texas"
        ],
        "West": [
            "Alaska", "American Samoa", "Arizona", "California", "Colorado", "Hawaii", "Idaho", "Montana",
            "Nevada", "Oregon", "Utah", "Washington", "Wyoming",
            "British Columbia", "Alberta", "Saskatchewan", "Yukon", "Northwest Territories"
        ]
    ]
    
    // Map for state/province name variations
    let stateNameVariations: [String: String] = [
        "DC": "District of Columbia",
        "Washington, D.C.": "District of Columbia",
        "Newfoundland": "Newfoundland and Labrador",
        "NWT": "Northwest Territories",
        "Yukon Territory": "Yukon",
        // Add more variations as needed
    ]
    
    // Store the current season ID
    private var current_season_id: Int = API.get_current_season_id()
    
    // Initialize with optional season query
    init(season_query: Int? = nil) {
        self.selected_season = season_query ?? API.selected_season_id()
        fetch_events(season_query: self.selected_season)
    }
    
    // Fetch events for the selected season
        func fetch_events(season_query: Int? = nil) {
            if let season = season_query {
                self.selected_season = season
            }
            
            // Prepare API request parameters
            var params: [String: Any] = ["per_page": 250]
            
            if isDateFilterActive {
                // Apply date filter to fetch events starting one week prior to the current date
                let defaultStartDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                let dateFormatter = ISO8601DateFormatter()
                dateFormatter.formatOptions = [.withInternetDateTime]
                let startDateString = dateFormatter.string(from: defaultStartDate)
                params["start"] = startDateString
                
                // Debugging: Print the start date
                print("Fetching events starting from: \(startDateString)")
            } else {
                print("Fetching all events for season \(self.selected_season)")
            }
            
            // Fetch events from the API
            let request_url = "/seasons/\(self.selected_season)/events"
            let data = ADCHubAPI.robotevents_request(request_url: request_url, params: params)
            
            // Clear existing events and states
            all_events.removeAll()
            states_map.removeAll()
            
            for event_data in data {
                // Initialize Event objects from the API response
                let event = Event(fetch: false, data: event_data)
                
                // Normalize event.region using variations mapping
                if let normalizedRegion = stateNameVariations[event.region] {
                    event.region = normalizedRegion
                }
                
                all_events.append(event)
                
                // Add state to states_map if not already present
                if !event.region.isEmpty && !states_map.contains(event.region) {
                    states_map.append(event.region)
                }
            }
            
            // Sort the states for better UI presentation
            states_map.sort()
            
            // Debugging: Print the number of events fetched
            print("Number of events fetched: \(all_events.count)")
            
            // Apply filters to the newly fetched events
            filter_events()
        }
    
    // Update event indexes for SwiftUI List
    private func update_event_indexes() {
        event_indexes = filtered_events.indices.map { String($0) }
    }
    
    func filter_events() {
        print("Filtering Events - Name: \(name_query), State: \(state_query), Level: \(level_query), Region: \(region_query)")
        
        filtered_events = all_events.filter { event in
            var matches = true
            
            // Event Type Filtering
            let eventType = event.type.lowercased()
            if eventType.contains("workshop") {
                print("Excluding event \(event.name) due to type: \(event.type)")
                return false
            }
            
            // Name filter
            if !name_query.isEmpty {
                if !event.name.lowercased().contains(name_query.lowercased()) {
                    print("Excluding event \(event.name) due to name filter")
                    matches = false
                }
            }
            
            // State filter
            if !state_query.isEmpty {
                if event.region.lowercased() != state_query.lowercased() {
                    print("Excluding event \(event.name) due to state filter")
                    matches = false
                }
            }
            
            // Level filter
            if !level_query.isEmpty {
                if event.level.lowercased() != level_query.lowercased() {
                    print("Excluding event \(event.name) due to level filter")
                    matches = false
                }
            }
            
            // Region filter
            if !region_query.isEmpty && region_query != "All Regions" {
                if let statesInRegion = regionStatesMap[region_query] {
                    let eventRegion = event.region.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                    let regionMatches = statesInRegion.contains { state in
                        state.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == eventRegion
                    }
                    if !regionMatches {
                        print("Excluding event \(event.name) due to region filter")
                        matches = false
                    }
                } else {
                    // Exclude if region not found
                    print("Region \(region_query) not found in regionStatesMap")
                    matches = false
                }
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
