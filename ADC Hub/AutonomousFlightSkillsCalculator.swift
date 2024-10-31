//
//  AutonomousFlightSkillsCalculator.swift
//  ADC Hub
//
//  Created by Skyler Clagg on 10/30/24.
//

import SwiftUI

struct AutonomousFlightSkillsCalculator: View {
    @EnvironmentObject var navigation_bar_manager: NavigationBarManager
    @EnvironmentObject var settings: UserSettings

    // State variables for tasks
    // Take off and Identify Color (per color mat)
    @State private var takeOffCount: Int = 0 // Max 2
    @State private var identifyColorCount: Int = 0 // Max 2

    // Tasks allowed twice
    @State private var figure8Count: Int = 0 // Max 2
    @State private var smallHoleCount: Int = 0 // Max 2
    @State private var largeHoleCount: Int = 0 // Max 2

    // Tasks allowed twice per object (2 objects)
    @State private var archGateCount: Int = 0 // Max 4 (2 per arch gate)
    @State private var keyholeCount: Int = 0 // Max 4 (2 per keyhole)

    // Landing options enumeration
    enum LandingOption: String, CaseIterable, Identifiable {
        case none = "None"
        case landOnPad = "Landing Pad"
        case landingCubeSmall = "Small Cube"
        case landingCubeLarge = "Large Cube"

        var id: String { self.rawValue }
    }

    @State private var selectedLandingOption: LandingOption = .none

    // Total score computed property
    var totalScore: Int {
        var score = 0

        // Take Off: 10 Points, Once per Color Mat (2 mats)
        score += takeOffCount * 10

        // Identify Color: 15 Points, Once per Color Mat (2 mats)
        score += identifyColorCount * 15

        // Complete a Figure 8: 40 Points, Max 2
        score += figure8Count * 40

        // Fly Under Arch Gate: 5 Points, 2 per Arch Gate (4 total)
        score += archGateCount * 5

        // Fly Through Keyhole: 15 Points, 2 per Keyhole (4 total)
        score += keyholeCount * 15

        // Fly Through Small Hole: 40 Points, Max 2
        score += smallHoleCount * 40

        // Fly Through Large Hole: 20 Points, Max 2
        score += largeHoleCount * 20

        // Landing Options
        switch selectedLandingOption {
        case .none:
            break // No points
        case .landOnPad:
            score += 15
        case .landingCubeSmall:
            score += 40
        case .landingCubeLarge:
            score += 25
        }

        return score
    }

    var body: some View {
        Form {
            // Display total score at the top
            Section(header: Text("Total Score")) {
                Text("\(totalScore)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }

            // Per Color Mat Tasks Section
            Section(header: Text("Tasks:")) {
                Stepper(value: $takeOffCount, in: 0...2) {
                    HStack {
                        Text("Take Off: ")
                        Spacer()
                        Text("\(takeOffCount)")
                            .foregroundColor(.secondary)
                    }
                }
                Stepper(value: $identifyColorCount, in: 0...2) {
                    HStack {
                        Text("Identify Color Count")
                        Spacer()
                        Text("\(identifyColorCount)")
                            .foregroundColor(.secondary)
                    }
                }
                Stepper(value: $figure8Count, in: 0...2) {
                    HStack {
                        Text("Complete a Figure 8")
                        Spacer()
                        Text("\(figure8Count)")
                            .foregroundColor(.secondary)
                    }
                }
                Stepper(value: $smallHoleCount, in: 0...2) {
                    HStack {
                        Text("Fly Through Small Hole")
                        Spacer()
                        Text("\(smallHoleCount)")
                            .foregroundColor(.secondary)
                    }
                }
                Stepper(value: $largeHoleCount, in: 0...2) {
                    HStack {
                        Text("Fly Through Large Hole")
                        Spacer()
                        Text("\(largeHoleCount)")
                            .foregroundColor(.secondary)
                    }
                }
                Stepper(value: $archGateCount, in: 0...4) {
                    HStack {
                        Text("Fly Under Arch Gate")
                        Spacer()
                        Text("\(archGateCount)")
                            .foregroundColor(.secondary)
                    }
                }
                .help("Max 2 per Arch Gate (2 Arch Gates)")

                Stepper(value: $keyholeCount, in: 0...4) {
                    HStack {
                        Text("Fly Through Keyhole")
                        Spacer()
                        Text("\(keyholeCount)")
                            .foregroundColor(.secondary)
                    }
                }
                .help("Max 2 per Keyhole (2 Keyholes)")
            }

            // Landing Options Section
            Section(header: Text("Landing Options")) {
                Picker("Select Landing Option", selection: $selectedLandingOption) {
                    ForEach(LandingOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
        }
        .navigationTitle("Autonomous Flight Calculator")
        .toolbar {
            // Clear Scores Button
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: clearInputs) {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("Clear Scores")
            }
        }
        .onAppear {
            navigation_bar_manager.title = "Autonomous Flight Calculator"
        }
    }

    // Function to reset all inputs
    func clearInputs() {
        takeOffCount = 0
        identifyColorCount = 0
        figure8Count = 0
        smallHoleCount = 0
        largeHoleCount = 0
        archGateCount = 0
        keyholeCount = 0
        selectedLandingOption = .none
    }
}

struct AutonomousFlightSkillsCalculator_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AutonomousFlightSkillsCalculator()
                .environmentObject(UserSettings())
                .environmentObject(NavigationBarManager(title: "Autonomous Flight Calculator"))
        }
    }
}
