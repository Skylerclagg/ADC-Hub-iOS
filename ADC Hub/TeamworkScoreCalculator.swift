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

            // Content
            VStack(spacing: 10) {
                // Counters Grid
                CountersGrid(
                    dropZoneTopCleared: $dropZoneTopCleared,
                    greenBeanBags: $greenBeanBags,
                    blueBeanBags: $blueBeanBags,
                    neutralBalls: $neutralBalls,
                    greenBalls: $greenBalls,
                    blueBalls: $blueBalls,
                    maxGreenBeanBags: maxGreenBeanBags,
                    maxBlueBeanBags: maxBlueBeanBags,
                    maxGreenBalls: maxGreenBalls,
                    maxNeutralBalls: maxNeutralBalls,
                    maxBlueBalls: maxBlueBalls,
                    remainingBeanBags: remainingBeanBags,
                    remainingBalls: remainingBalls,
                    isBeanBagConstraintViolated: isBeanBagConstraintViolated
                )

                // Drones Section
                HStack(spacing: 10) {
                    DroneBox(
                        droneColor: "Red",
                        selectedOption: $redDroneSelection,
                        otherDroneSelection: blueDroneSelection
                    )
                    DroneBox(
                        droneColor: "Blue",
                        selectedOption: $blueDroneSelection,
                        otherDroneSelection: redDroneSelection
                    )
                }
                .frame(maxHeight: 220)
                .padding(.horizontal)
            }
            .padding(.vertical, 10)
            .background(Color(.systemGroupedBackground))
        }
        .navigationTitle("Teamwork Score Calculator")
        .toolbar {
            // Clear Scores Button
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: clearInputs) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
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

// MARK: - Score View

struct ScoreView: View {
    let totalScore: Int
    let showWarning: Bool

    var body: some View {
        ZStack {
            // Background with gradient
            RoundedRectangle(cornerRadius: 15)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
                .padding(.horizontal)

            HStack {
                if showWarning {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                        .scaleEffect(1.2)
                }
                Text("Score: \(totalScore)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                if showWarning {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                        .scaleEffect(1.2)
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 80)
        .padding(.vertical)
    }
}

// MARK: - Counters Grid

struct CountersGrid: View {
    @Binding var dropZoneTopCleared: Int
    @Binding var greenBeanBags: Int
    @Binding var blueBeanBags: Int
    @Binding var neutralBalls: Int
    @Binding var greenBalls: Int
    @Binding var blueBalls: Int
    let maxGreenBeanBags: Int
    let maxBlueBeanBags: Int
    let maxGreenBalls: Int
    let maxNeutralBalls: Int
    let maxBlueBalls: Int
    let remainingBeanBags: Int
    let remainingBalls: Int
    let isBeanBagConstraintViolated: Bool

    var body: some View {
        VStack(spacing: 10) {
            // Bean Bags and Drone Zone Tops Cleared
            VStack(alignment: .leading, spacing: 10) {
                Text("Bean Bags")
                    .font(.headline)
                    .padding(.horizontal)
                HStack(spacing: 5) {
                    CounterSection(
                        title: "Drop Zone Tops Cleared",
                        count: $dropZoneTopCleared,
                        maxCount: 7,
                        showWarning: isBeanBagConstraintViolated,
                        accentColor: .orange
                    )
                    CounterSection(
                        title: "Green Bean Bags on Drop Zone",
                        count: $greenBeanBags,
                        maxCount: maxGreenBeanBags,
                        showWarning: isBeanBagConstraintViolated,
                        accentColor: .green
                    )
                    CounterSection(
                        title: "Blue Bean Bags on Drop Zone",
                        count: $blueBeanBags,
                        maxCount: maxBlueBeanBags,
                        showWarning: isBeanBagConstraintViolated,
                        accentColor: .blue
                    )
                }
                .padding(.horizontal, 5)
                if isBeanBagConstraintViolated {
                    Text("Bean bags exceed tops cleared!")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                } else {
                    Text("Remaining Bean Bags: \(remainingBeanBags)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical, 5)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(15)
            .padding(.horizontal, 5)
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)

            // Balls Counters
            VStack(alignment: .leading, spacing: 10) {
                Text("Balls")
                    .font(.headline)
                    .padding(.horizontal)
                HStack(spacing: 5) {
                    CounterSection(
                        title: "Balls in Green Zone",
                        count: $greenBalls,
                        maxCount: maxGreenBalls,
                        accentColor: .green
                    )
                    CounterSection(
                        title: "Balls in Neutral Zone",
                        count: $neutralBalls,
                        maxCount: maxNeutralBalls,
                        accentColor: .gray
                    )
                    CounterSection(
                        title: "Balls in Blue Zone",
                        count: $blueBalls,
                        maxCount: maxBlueBalls,
                        accentColor: .blue
                    )
                }
                .padding(.horizontal, 5)
                Text("Remaining Balls: \(remainingBalls)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            .padding(.vertical, 5)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(15)
            .padding(.horizontal, 5)
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        }
    }
}

// MARK: - Counter Section

struct CounterSection: View {
    let title: String
    @Binding var count: Int
    let maxCount: Int
    var showWarning: Bool = false
    var accentColor: Color = .primary

    var body: some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .foregroundColor(accentColor)
                .lineLimit(2)
                .minimumScaleFactor(0.5)

            HStack(spacing: 10) {
                Button(action: {
                    if count > 0 {
                        count -= 1
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.red)
                }

                Text("\(count)")
                    .font(.title2)
                    .frame(width: 30, alignment: .center)

                Button(action: {
                    if count < maxCount {
                        count += 1
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.green)
                }
            }
            if showWarning {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 3)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Drone Box

struct DroneBox: View {
    let droneColor: String
    @Binding var selectedOption: String
    let otherDroneSelection: String

    var body: some View {
        VStack(spacing: 10) {
            Text("\(droneColor) Drone")
                .font(.headline)
                .foregroundColor(droneUIColor())

            // Options Grid
            let columns = [
                GridItem(.flexible()),
                GridItem(.flexible())
            ]

            LazyVGrid(columns: columns, spacing: 5) {
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
                DroneOptionButton(
                    label: "Large Cube",
                    isSelected: selectedOption == "Large Cube",
                    isDisabled: isOptionDisabled(option: "Large Cube"),
                    droneColor: droneUIColor()
                ) {
                    selectedOption = "Large Cube"
                }
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
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: droneUIColor().opacity(0.2), radius: 5, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(droneUIColor(), lineWidth: 1)
        )
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

// MARK: - Drone Option Button

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
                .font(.caption)
                .padding(6)
                .frame(maxWidth: .infinity)
                .background(isSelected ? droneColor.opacity(0.7) : Color(.systemGray5))
                .foregroundColor(isDisabled ? .gray : (isSelected ? .white : droneColor))
                .cornerRadius(6)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .disabled(isDisabled)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(droneColor, lineWidth: isSelected ? 0 : 1)
        )
        .shadow(color: isSelected ? droneColor.opacity(0.3) : Color.clear, radius: 2, x: 0, y: 1)
    }
}

// MARK: - Preview

struct TeamworkScoreCalculator_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TeamworkScoreCalculator()
                .environmentObject(NavigationBarManager(title: "Teamwork Score Calculator"))
                .environmentObject(UserSettings())
        }
    }
}
