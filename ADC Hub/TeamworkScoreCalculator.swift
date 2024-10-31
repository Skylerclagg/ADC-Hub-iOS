//
//  TeamworkScoreCalculator.swift
//  ADC Hub
//
//  Created by Skyler Clagg on 9/26/24.
//

import SwiftUI

struct TeamworkScoreCalculator: View {
    @EnvironmentObject var navigation_bar_manager: NavigationBarManager
    @EnvironmentObject var settings: UserSettings

    // State variables for input fields
    @State private var dropZoneTopCleared = 0
    @State private var greenBeanBags = 0
    @State private var blueBeanBags = 0
    @State private var neutralBalls = 0
    @State private var greenBalls = 0
    @State private var blueBalls = 0
    @State private var redDroneSelection: String = "None"
    @State private var blueDroneSelection: String = "None"

    // Computed total score based on the rules
    var totalScore: Int {
        // Basic point scoring: Points for Neutral Balls, Bean Bags, and Drop Zone Top clearing
        let basicScore = dropZoneTopCleared + neutralBalls + greenBeanBags + blueBeanBags

        // Base points for balls always included (regardless of bean bags)
        let greenBasePoints = greenBalls
        let blueBasePoints = blueBalls

        // Color match calculation for green and blue (only if there are bean bags in the drop zone)
        let greenColorMatch = greenBeanBags > 0 ? (greenBalls * greenBeanBags * 2) : 0
        let blueColorMatch = blueBeanBags > 0 ? (blueBalls * blueBeanBags * 2) : 0

        // Landing points for Red Drone
        let redLandingScore = landingScore(for: redDroneSelection)

        // Landing points for Blue Drone
        let blueLandingScore = landingScore(for: blueDroneSelection)

        // Total score: Basic score + base points + color match (if any) + landing scores
        return basicScore + greenBasePoints + blueBasePoints + greenColorMatch + blueColorMatch + redLandingScore + blueLandingScore
    }

    // Helper function to calculate landing score based on selection
    func landingScore(for selection: String) -> Int {
        switch selection {
        case "None":
            return 0
        case "Small Cube":
            return 25
        case "Large Cube":
            return 15
        case "Landing Pad":
            return 15
        case "Bullseye":
            return 25
        default:
            return 0
        }
    }

    // Remaining bean bags allowed (maximum 7 between green and blue)
    var remainingBeanBags: Int {
        return max(0, 7 - (greenBeanBags + blueBeanBags))
    }

    // Remaining balls allowed (maximum 10 between neutral, green, and blue)
    var remainingBalls: Int {
        return max(0, 10 - (neutralBalls + greenBalls + blueBalls))
    }

    // Max counts for bean bags (do not limit based on tops cleared)
    var maxGreenBeanBags: Int {
        return greenBeanBags + remainingBeanBags
    }

    var maxBlueBeanBags: Int {
        return blueBeanBags + remainingBeanBags
    }

    // Max counts for balls
    var maxGreenBalls: Int {
        return greenBalls + remainingBalls
    }

    var maxBlueBalls: Int {
        return blueBalls + remainingBalls
    }

    var maxNeutralBalls: Int {
        return neutralBalls + remainingBalls
    }

    // Constraint check for bean bags and drone zone tops cleared
    var isBeanBagConstraintViolated: Bool {
        return (greenBeanBags + blueBeanBags) > dropZoneTopCleared
    }

    var body: some View {
        VStack(spacing: 0) {
            // Fixed Score View
            ScoreView(totalScore: totalScore, showWarning: isBeanBagConstraintViolated)
                .zIndex(1)

            // Scrollable Content
            ScrollView {
                VStack(spacing: 20) {
                    // Drone Zone Tops Cleared Section with Warning Signs
                    CounterSection(
                        title: "Drone Zone Tops Cleared",
                        count: $dropZoneTopCleared,
                        maxCount: 7,
                        showWarning: isBeanBagConstraintViolated
                    )

                    // Green Bean Bags on Drop Zone
                    CounterSection(
                        title: "Green Bean Bags on Drop Zone",
                        count: $greenBeanBags,
                        maxCount: maxGreenBeanBags,
                        showWarning: isBeanBagConstraintViolated
                    )

                    // Blue Bean Bags on Drop Zone
                    CounterSection(
                        title: "Blue Bean Bags on Drop Zone",
                        count: $blueBeanBags,
                        maxCount: maxBlueBeanBags,
                        showWarning: isBeanBagConstraintViolated
                    )

                    // Remaining Bean Bags Indicator
                    Text("Remaining Bean Bags: \(remainingBeanBags)")
                        .font(.subheadline)
                        .foregroundColor(.red)

                    // Green Balls in Zones
                    CounterSection(
                        title: "Green Balls in Zones",
                        count: $greenBalls,
                        maxCount: maxGreenBalls
                    )

                    // Neutral Balls in Zones
                    CounterSection(
                        title: "Neutral Balls in Zones",
                        count: $neutralBalls,
                        maxCount: maxNeutralBalls
                    )

                    // Blue Balls in Zones
                    CounterSection(
                        title: "Blue Balls in Zones",
                        count: $blueBalls,
                        maxCount: maxBlueBalls
                    )

                    // Remaining Balls Indicator
                    Text("Remaining Balls: \(remainingBalls)")
                        .font(.subheadline)
                        .foregroundColor(.red)

                    // Red Drone Box
                    DroneBox(
                        droneColor: "Red",
                        selectedOption: $redDroneSelection,
                        otherDroneSelection: blueDroneSelection
                    )

                    // Blue Drone Box
                    DroneBox(
                        droneColor: "Blue",
                        selectedOption: $blueDroneSelection,
                        otherDroneSelection: redDroneSelection
                    )
                }
                .padding()
            }
        }
        .navigationTitle("Teamwork Score Calculator") // Add this line
        .onAppear {
            navigation_bar_manager.title = "Teamwork Score Calculator"
        }
        .toolbar {
            // Clear Scores Button
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: clearInputs) {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("Clear Scores")
            }
        }
    }

    // Function to reset all inputs
    func clearInputs() {
        dropZoneTopCleared = 0
        greenBeanBags = 0
        blueBeanBags = 0
        neutralBalls = 0
        greenBalls = 0
        blueBalls = 0
        redDroneSelection = "None"
        blueDroneSelection = "None"
    }
}

// Score View with Warning Sign
struct ScoreView: View {
    let totalScore: Int
    let showWarning: Bool

    var body: some View {
        HStack {
            if showWarning {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
            }
            Text("Score: \(totalScore)")
                .font(.largeTitle)
                .bold()
            if showWarning {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
    }
}

// Counter Section with Optional Warning Signs
struct CounterSection: View {
    let title: String
    @Binding var count: Int
    let maxCount: Int
    var showWarning: Bool = false

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                if showWarning {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                }
                Text(title)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .center)
                if showWarning {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                }
            }

            HStack {
                Spacer()

                Button(action: {
                    if count > 0 {
                        count -= 1
                    }
                }) {
                    Image(systemName: "minus.circle")
                        .font(.largeTitle)
                }

                Text("\(count)")
                    .font(.title)
                    .frame(width: 50, alignment: .center)

                Button(action: {
                    if count < maxCount {
                        count += 1
                    }
                }) {
                    Image(systemName: "plus.circle")
                        .font(.largeTitle)
                }

                Spacer()
            }
        }
    }
}

// Drone Box
struct DroneBox: View {
    let droneColor: String
    @Binding var selectedOption: String
    let otherDroneSelection: String

    var body: some View {
        VStack(spacing: 10) {
            Text("\(droneColor) Drone")
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray5))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(droneUIColor(), lineWidth: 2) // Outline of the box
                )

            // First Row: None and Small Cube
            HStack {
                DroneOptionButton(
                    label: "None",
                    isSelected: selectedOption == "None",
                    isDisabled: false,
                    droneColor: droneUIColor()
                ) {
                    selectedOption = "None"
                }
                DroneOptionButton(
                    label: "Small Cube",
                    isSelected: selectedOption == "Small Cube",
                    isDisabled: isOptionDisabled(option: "Small Cube"),
                    droneColor: droneUIColor()
                ) {
                    selectedOption = "Small Cube"
                }
            }

            // Second Row: Large Cube (Centered)
            HStack {
                Spacer()
                DroneOptionButton(
                    label: "Large Cube",
                    isSelected: selectedOption == "Large Cube",
                    isDisabled: isOptionDisabled(option: "Large Cube"),
                    droneColor: droneUIColor()
                ) {
                    selectedOption = "Large Cube"
                }
                Spacer()
            }

            // Third Row: Landing Pad and Bullseye
            HStack {
                DroneOptionButton(
                    label: "Landing Pad",
                    isSelected: selectedOption == "Landing Pad",
                    isDisabled: isOptionDisabled(option: "Landing Pad"),
                    droneColor: droneUIColor()
                ) {
                    selectedOption = "Landing Pad"
                }
                DroneOptionButton(
                    label: "Bullseye",
                    isSelected: selectedOption == "Bullseye",
                    isDisabled: isOptionDisabled(option: "Bullseye"),
                    droneColor: droneUIColor()
                ) {
                    selectedOption = "Bullseye"
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }

    // Function to determine if an option should be disabled
    func isOptionDisabled(option: String) -> Bool {
        // If the current drone has selected the option, it should not be disabled
        if selectedOption == option {
            return false
        }

        // Disable the same option if selected by the other drone
        if otherDroneSelection == option {
            return true
        }

        // If the other drone has selected "Landing Pad" or "Bullseye",
        // disable both "Landing Pad" and "Bullseye" for this drone
        if (otherDroneSelection == "Landing Pad" || otherDroneSelection == "Bullseye") &&
            (option == "Landing Pad" || option == "Bullseye") {
            return true
        }

        return false
    }

    // Helper function to get Color from droneColor
    func droneUIColor() -> Color {
        return droneColor == "Red" ? .red : .blue
    }
}

// Drone Option Button
struct DroneOptionButton: View {
    let label: String
    let isSelected: Bool
    let isDisabled: Bool
    let droneColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }) {
            Text(label)
                .padding()
                .frame(maxWidth: .infinity)
                .background(isSelected ? droneColor : Color.clear)
                .foregroundColor(isDisabled ? .gray : (isSelected ? .white : droneColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(droneColor, lineWidth: 2) // Outline of the button
                )
        }
        .disabled(isDisabled)
    }
}

struct TeamworkScoreCalculator_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TeamworkScoreCalculator()
                .environmentObject(NavigationBarManager(title: "Teamwork Score Calculator"))
                .environmentObject(UserSettings())
        }
    }
}
