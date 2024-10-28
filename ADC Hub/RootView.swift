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
        NavigationView {
            TabView(selection: $tab_selection) {
                // Favorites Tab
                Favorites(tab_selection: $tab_selection, lookup_type: $lookup_type)
                    .tabItem {
                        if UserSettings.getMinimalistic() {
                            Image(systemName: "star")
                        } else {
                            Label("Favorites", systemImage: "star")
                        }
                    }
                    .tag(0)
                    .environmentObject(favorites)
                    .environmentObject(settings)
                    .environmentObject(dataController)
                    .environmentObject(navigation_bar_manager)
                    .tint(settings.buttonColor())

                // World Skills Rankings Tab
                WorldSkillsRankings()
                    .tabItem {
                        if UserSettings.getMinimalistic() {
                            Image(systemName: "globe")
                        } else {
                            Label("World Skills", systemImage: "globe")
                        }
                    }
                    .tag(1)
                    .environmentObject(favorites)
                    .environmentObject(settings)
                    .environmentObject(dataController)
                    .environmentObject(navigation_bar_manager)
                    .tint(settings.buttonColor())

                // Lookup Tab
                Lookup(lookup_type: $lookup_type)
                    .tabItem {
                        if UserSettings.getMinimalistic() {
                            Image(systemName: "magnifyingglass")
                        } else {
                            Label("Lookup", systemImage: "magnifyingglass")
                        }
                    }
                    .tag(2)
                    .environmentObject(favorites)
                    .environmentObject(settings)
                    .environmentObject(dataController)
                    .environmentObject(navigation_bar_manager)
                    .tint(settings.buttonColor())

                // Game Manual Tab
                GameManual()
                    .tabItem {
                        if UserSettings.getMinimalistic() {
                            Image(systemName: "book")
                        } else {
                            Label("Game Manual", systemImage: "book")
                        }
                    }
                    .tag(3)
                    .environmentObject(favorites)
                    .environmentObject(settings)
                    .environmentObject(dataController)
                    .environmentObject(navigation_bar_manager)
                    .tint(settings.buttonColor())

                // Score Calculator Tab
                ScoreCalculator()
                    .tabItem {
                        if UserSettings.getMinimalistic() {
                            Image(systemName: "ipad")
                        } else {
                            Label("Calculator", systemImage: "ipad")
                        }
                    }
                    .tag(4)
                    .environmentObject(favorites)
                    .environmentObject(settings)
                    .environmentObject(dataController)
                    .environmentObject(navigation_bar_manager)
                    .tint(settings.buttonColor())
            }
            .onAppear {
                let tabBarAppearance = UITabBarAppearance()
                tabBarAppearance.configureWithDefaultBackground()
                UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            }
            .tint(settings.buttonColor())
            .background(Color.clear)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(navigation_bar_manager.title)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack {
                        Text(navigation_bar_manager.title)
                            .fontWeight(.medium)
                            .font(.system(size: 19))
                            .foregroundColor(settings.topBarContentColor())
                        // Add any subtitle or additional text if needed
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: Settings()
                        .environmentObject(favorites)
                        .environmentObject(settings)
                        .environmentObject(dataController)
                        .environmentObject(navigation_bar_manager)
                        .tint(settings.buttonColor())
                    ) {
                        Image(systemName: "gearshape")
                    }
                }
                if navigation_bar_manager.title.contains("Skills") {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Link(destination: URL(string: "https://www.robotevents.com/robot-competitions/adc/standings/skills")!) {
                            Image(systemName: "link")
                        }
                        .foregroundColor(settings.topBarContentColor())
                    }
                }
            }
            .toolbarBackground(settings.tabColor(), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Ensures consistent behavior on iPad
        .tint(settings.topBarContentColor())
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
