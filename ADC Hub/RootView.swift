//
//  RootView.swift
//
//  ADC Hub
//
//  Based on
//  VRC RoboScout by William Castro
//
//  Created by Skyler Clagg on 9/26/24.
//

import SwiftUI

class NavigationBarManager: ObservableObject {
    @Published var title: String
    init(title: String) {
        self.title = title
    }
}

struct RootView: View {
    
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var favorites: FavoriteStorage
    @EnvironmentObject var dataController: ADCHubDataController
    
    @StateObject var navigation_bar_manager = NavigationBarManager(title: "Favorites")
    
    @State private var tab_selection = 0
    @State private var lookup_type = 0 // 0 is teams, 1 is events
        
    var body: some View {
        NavigationStack {
            TabView(selection: $tab_selection) {
                Favorites(tab_selection: $tab_selection, lookup_type: $lookup_type)
                    .tabItem {
                        if UserSettings.getMinimalistic() {
                            Image(systemName: "star")
                        }
                        else {
                            Label("Favorites", systemImage: "star")
                        }
                    }
                    .environmentObject(favorites)
                    .environmentObject(settings)
                    .environmentObject(dataController)
                    .environmentObject(navigation_bar_manager)
                    .tint(settings.buttonColor())
                    .tag(0)
                WorldSkillsRankings()
                    .tabItem {
                        if UserSettings.getMinimalistic() {
                            Image(systemName: "globe")
                        }
                        else {
                            Label("World Skills", systemImage: "globe")
                        }
                    }
                    .environmentObject(favorites)
                    .environmentObject(settings)
                    .environmentObject(dataController)
                    .environmentObject(navigation_bar_manager)
                    .tint(settings.buttonColor())
                    .tag(1)
                Lookup(lookup_type: $lookup_type)
                    .tabItem {
                        if UserSettings.getMinimalistic() {
                            Image(systemName: "magnifyingglass")
                        }
                        else {
                            Label("Lookup", systemImage: "magnifyingglass")
                        }
                    }
                    .environmentObject(favorites)
                    .environmentObject(settings)
                    .environmentObject(dataController)
                    .environmentObject(navigation_bar_manager)
                    .tint(settings.buttonColor())
                    .tag(2)
                GameManual()
                    .tabItem{
                        if UserSettings.getMinimalistic(){
                            Image(systemName: "book")
                        }
                        else{
                            Label("Game Manual", systemImage: "book")
                        }
                    }
                    .environmentObject(favorites)
                    .environmentObject(settings)
                    .environmentObject(dataController)
                    .environmentObject(navigation_bar_manager)
                    .tint(settings.buttonColor())
                    .tag(3)
                ScoreCalculator()
                    .tabItem {
                        if UserSettings.getMinimalistic(){
                            Image(systemName: "ipad")
                        }else{
                            Label("Calculator", systemImage: "ipad")
                        }
                    }
                    .environmentObject(favorites)
                    .environmentObject(settings)
                    .environmentObject(dataController)
                    .environmentObject(navigation_bar_manager)
                    .tint(settings.buttonColor())
                    .tag(4)
            }.onAppear {
                let tabBarAppearance = UITabBarAppearance()
                tabBarAppearance.configureWithDefaultBackground()
                UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            }.tint(settings.buttonColor())
                .background(.clear)
                        .toolbar {
                            ToolbarItem(placement: .principal) {
                                VStack {
                                    Text(navigation_bar_manager.title)
                                        .fontWeight(.medium)
                                        .font(.system(size: 19))
                                        .foregroundColor(settings.topBarContentColor())
                                }
                            }
                            ToolbarItem(placement: .topBarTrailing) {
                                NavigationLink(destination: Settings().environmentObject(favorites).environmentObject(settings).environmentObject(dataController).environmentObject(navigation_bar_manager).tint(settings.buttonColor()).tag(4)) { // Referencing Settings struct from another file
                                    Image(systemName: "gearshape")
                                }
                            }
                            if navigation_bar_manager.title.contains("Skills") {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Link(destination: URL(string: "https://www.robotevents.com/robot-competitions/adc/standings/skills")!) {
                                        Image(systemName: "link")
                                    }.foregroundColor(settings.topBarContentColor())
                                }
                            }
                        }
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbarBackground(settings.tabColor(), for: .navigationBar)
                        .toolbarBackground(.visible, for: .navigationBar)
        }.tint(settings.topBarContentColor())
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
