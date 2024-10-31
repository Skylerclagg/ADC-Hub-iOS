//
//  PilotingSkillsCalculator.swift
//  ADC Hub
//
//  Created by Skyler Clagg on 10/30/24.
//

import SwiftUI

struct PilotingSkillsCalculator: View {
    @EnvironmentObject var navigation_bar_manager: NavigationBarManager
    @EnvironmentObject var settings: UserSettings

    // State variables for tasks
    @State private var didTakeOff: Bool = false
    @State private var figure8Count: Int = 0
    @State private var smallHoleCount: Int = 0
    @State private var largeHoleCount: Int = 0
    @State private var keyholeCount: Int = 0

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

        // Take Off: 10 Points, Once
        if didTakeOff {
            score += 10
        }

        // Complete a Figure 8: 40 Points per completion
        score += figure8Count * 40

        // Fly Through Small Hole: 40 Points per completion
        score += smallHoleCount * 40

        // Fly Through Large Hole: 20 Points per completion
        score += largeHoleCount * 20

        // Fly Through Keyhole: 15 Points per completion
        score += keyholeCount * 15

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
            Section(header: Text("Total Score")) {
                Text("\(totalScore)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }

            Section(header: Text("Tasks:")) {
                Toggle("Take Off: ", isOn: $didTakeOff)
                    .toggleStyle(SwitchToggleStyle(tint: settings.buttonColor()))
                
                Stepper(value: $figure8Count, in: 0...100) {
                    HStack {
                        Text("Complete a Figure 8")
                        Spacer()
                        Text("\(figure8Count)")
                            .foregroundColor(.secondary)
                    }
                }
                Stepper(value: $smallHoleCount, in: 0...100) {
                    HStack {
                        Text("Fly Through Small Hole")
                        Spacer()
                        Text("\(smallHoleCount)")
                            .foregroundColor(.secondary)
                    }
                }
                Stepper(value: $largeHoleCount, in: 0...100) {
                    HStack {
                        Text("Fly Through Large Hole")
                        Spacer()
                        Text("\(largeHoleCount)")
                            .foregroundColor(.secondary)
                    }
                }
                Stepper(value: $keyholeCount, in: 0...100) {
                    HStack {
                        Text("Fly Through Keyhole")
                        Spacer()
                        Text("\(keyholeCount)")
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section(header: Text("Landing Options")) {
                Picker("Select Landing Option", selection: $selectedLandingOption) {
                    ForEach(LandingOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
        }
        .navigationTitle("Piloting Skills Calculator")
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
            navigation_bar_manager.title = "Piloting Skills Calculator"
        }
    }

    // Function to reset all inputs
    func clearInputs() {
        didTakeOff = false
        figure8Count = 0
        smallHoleCount = 0
        largeHoleCount = 0
        keyholeCount = 0
        selectedLandingOption = .none
    }
}

struct PilotingSkillsCalculator_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PilotingSkillsCalculator()
                .environmentObject(UserSettings())
                .environmentObject(NavigationBarManager(title: "Piloting Skills Calculator"))
        }
    }
}
