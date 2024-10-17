//
//  EventDivisionRankings.swift
//
//  ADC Hub
//
//  Based on
//  VRC RoboScout by William Castro
//
//  Created by Skyler Clagg on 9/26/24.
//

import SwiftUI

class EventDivisionRankingsList: ObservableObject {
    @Published var rankings_indexes: [Int]
    
    init(rankings_indexes: [Int] = [Int]()) {
        self.rankings_indexes = rankings_indexes.sorted()
    }
    
    func sort_by(option: Int, event: Event, division: Division) {
        var sorted = [Int]()
        
        // Create an array of team performance ratings from the event.team_performance_ratings[division] dictionary
        
        // By rank
        if option == 0 {
            // Create the indexes of the rankings in order
            for i in 0..<event.rankings[division]!.count {
                sorted.append(i)
            }
        }
        
    }
}

struct EventDivisionRankings: View {
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var favorites: FavoriteStorage
    @EnvironmentObject var dataController: ADCHubDataController
    @EnvironmentObject var navigation_bar_manager: NavigationBarManager
    
    @State var event: Event
    @State var division: Division
    @State var teams_map: [String: String]
    @State var event_rankings_list: EventDivisionRankingsList
    @State var showLoading = true
    @State var showingSheet = false
    @State var sortingOption = 0
    @State var teamNumberQuery = ""
    
    var searchResults: [Int] {
        if teamNumberQuery.isEmpty {
            return event_rankings_list.rankings_indexes.reversed()
        }
        else {
            return event_rankings_list.rankings_indexes.reversed().filter{ (teams_map[String(team_ranking(rank: $0).team.id)] ?? "").lowercased().contains(teamNumberQuery.lowercased()) }
        }
    }
    
    init(event: Event, division: Division, teams_map: [String: String]) {
        self.event = event
        self.division = division
        self.teams_map = teams_map
        self.event_rankings_list = EventDivisionRankingsList()
    }
    
    func fetch_rankings() {
        DispatchQueue.global(qos: .userInteractive).async { [self] in
            event.fetch_rankings(division: division)
            var fetched_rankings_indexes = [Int]()
            var counter = 0
            for _ in (event.rankings[division] ?? [TeamRanking]()) {
                fetched_rankings_indexes.append(counter)
                counter += 1
            }
            DispatchQueue.main.async {
                self.event_rankings_list = EventDivisionRankingsList(rankings_indexes: fetched_rankings_indexes)
                self.showLoading = false
            }
        }
    }
    
    func team_ranking(rank: Int) -> TeamRanking {
        return event.rankings[division]![rank]
    }
    
    var body: some View {
        VStack {
            if showLoading {
                ProgressView().padding()
                Spacer()
            }
            else if (event.rankings[division] ?? [TeamRanking]()).isEmpty {
                NoData()
            }
            else {
                Picker("Sort", selection: $sortingOption) {
                    Text("Rank").tag(0)
                }.pickerStyle(.segmented).padding([.top, .leading, .trailing], 10)
                    .onChange(of: sortingOption) { option in
                        self.event_rankings_list.sort_by(option: option, event: self.event, division: self.division)
                        self.showLoading = true
                        self.showLoading = false
                    }.onShake{
                        self.sortingOption = 6
                        self.event_rankings_list.sort_by(option: self.sortingOption, event: self.event, division: self.division)
                        self.showLoading = true
                        self.showLoading = false
                        let sel = UISelectionFeedbackGenerator()
                        sel.selectionChanged()
                    }
                NavigationView {
                    List {
                        ForEach(searchResults, id: \.self) { rank in
                            NavigationLink(destination: EventTeamMatches(teams_map: $teams_map, event: self.event, team: Team(id: team_ranking(rank: rank).team.id, fetch: false), division: self.division).environmentObject(settings).environmentObject(dataController)) {
                                VStack {
                                    HStack {
                                        Text(teams_map[String(team_ranking(rank: rank).team.id)] ?? "").font(.system(size: 20)).minimumScaleFactor(0.01).frame(width: 70, alignment: .leading).bold()
                                        Text((event.get_team(id: team_ranking(rank: rank).team.id) ?? Team()).name).frame(alignment: .leading)
                                        Spacer()
                                        if favorites.favorite_teams.contains(teams_map[String(team_ranking(rank: rank).team.id)] ?? "") {
                                            Image(systemName: "star.fill")
                                        }
                                    }.frame(maxWidth: .infinity, alignment: .leading).frame(height: 20)
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text("# \(team_ranking(rank: rank).rank)").frame(alignment: .leading).font(.system(size: 32))
                                        }.frame(alignment: .leading)
                                        Spacer()
                                        VStack(alignment: .leading) {
                                            Text("AVG Points:" + displayRounded(number: team_ranking(rank: rank).average_points)).frame(alignment: .leading).font(.system(size: 30)).foregroundColor(.secondary)
                                        }.frame(alignment: .leading)
                                    }
                                }
                            }
                        }
                    }
                }.navigationViewStyle(StackNavigationViewStyle())
                    .searchable(text: $teamNumberQuery, prompt: "Enter a team number...")
                    .tint(settings.topBarContentColor())
            }
        }.task{
            fetch_rankings()
        }.onAppear{
            navigation_bar_manager.title = "\(division.name) Rankings"
        }
    }
}

struct EventDivisionRankings_Previews: PreviewProvider {
    static var previews: some View {
        EventDivisionRankings(event: Event(), division: Division(), teams_map: [String: String]())
    }
}
