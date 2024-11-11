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

    // List of possible landing options
    private let landingOptions = ["None", "Small Cube", "Large Cube", "Landing Pad", "Bullseye"]

    // Computed total score based on the rules
    var totalScore: Int {
        let basicScore = dropZoneTopCleared + neutralBalls + greenBeanBags + blueBeanBags
        let greenBasePoints = greenBalls
        let blueBasePoints = blueBalls
        let greenColorMatch = greenBeanBags > 0 ? (greenBalls * greenBeanBags * 2) : 0
        let blueColorMatch = blueBeanBags > 0 ? (blueBalls * blueBeanBags * 2) : 0
        let landingScore = combinedLandingScore()

        return basicScore + greenBasePoints + blueBasePoints + greenColorMatch + blueColorMatch + landingScore
    }

    // Function to calculate landing score while ensuring points are only counted once for shared selections
    func combinedLandingScore() -> Int {
        // Set to keep track of the unique landing selections
        var uniqueSelections = Set<String>()

        // Add both selections, ensuring they're not "None"
        if redDroneSelection != "None" {
            uniqueSelections.insert(redDroneSelection)
        }
        if blueDroneSelection != "None" {
            uniqueSelections.insert(blueDroneSelection)
        }

        // Handle the special case for "Landing Pad" and "Bullseye"
        if uniqueSelections.contains("Landing Pad") && uniqueSelections.contains("Bullseye") {
            // If both "Landing Pad" and "Bullseye" are selected, only count one of them
            uniqueSelections.remove("Bullseye") // Arbitrarily decide to remove "Bullseye"
        }

        // Calculate total landing score based on unique selections
        return uniqueSelections.reduce(0) { $0 + landingScore(for: $1) }
    }

    // Helper function to get landing score for a particular selection
    func landingScore(for selection: String) -> Int {
        switch selection {
        case "None": return 0
        case "Small Cube": return 25
        case "Large Cube": return 15
        case "Landing Pad": return 15
        case "Bullseye": return 25
        default: return 0
        }
    }

    var isBeanBagConstraintViolated: Bool {
        return (greenBeanBags + blueBeanBags) > dropZoneTopCleared
    }

    var body: some View {
        Form {
            Section(header: Text("Total Score").foregroundColor(.white)) {
                Text("\(totalScore)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }

            Section(header: Text("Bean Bags").foregroundColor(.green)) {
                Stepper(value: $dropZoneTopCleared, in: 0...7) {
                    HStack {
                        if isBeanBagConstraintViolated {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.red)
                        }
                        Text("Tops Cleared").foregroundColor(.green)
                        Spacer()
                        Text("\(dropZoneTopCleared)").foregroundColor(.secondary)
                    }
                }
                Stepper(value: $greenBeanBags, in: 0...maxGreenBeanBags) {
                    HStack {
                        if isBeanBagConstraintViolated {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.red)
                        }
                        Text("Bean Bags Green on Drop Zone").foregroundColor(.green)
                        Spacer()
                        Text("\(greenBeanBags)").foregroundColor(.secondary)
                    }
                }
                Stepper(value: $blueBeanBags, in: 0...maxBlueBeanBags) {
                    HStack {
                        if isBeanBagConstraintViolated {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.red)
                        }
                        Text("Bean Bags Blue on Drop Zone").foregroundColor(.blue)
                        Spacer()
                        Text("\(blueBeanBags)").foregroundColor(.secondary)
                    }
                }
                Text("Remaining Bean Bags: \(remainingBeanBags)")
                    .font(.subheadline)
                    .foregroundColor(.red)
            }

            Section(header: Text("Balls in Zones").foregroundColor(.green)) {
                Stepper(value: $neutralBalls, in: 0...maxNeutralBalls) {
                    HStack {
                        Text("Balls in Neutral Zones").foregroundColor(.white)
                        Spacer()
                        Text("\(neutralBalls)").foregroundColor(.secondary)
                    }
                }
                Stepper(value: $greenBalls, in: 0...maxGreenBalls) {
                    HStack {
                        Text("Balls in Green Zone").foregroundColor(.green)
                        Spacer()
                        Text("\(greenBalls)").foregroundColor(.secondary)
                    }
                }
                Stepper(value: $blueBalls, in: 0...maxBlueBalls) {
                    HStack {
                        Text("Balls in Blue Zone").foregroundColor(.blue)
                        Spacer()
                        Text("\(blueBalls)").foregroundColor(.secondary)
                    }
                }
                Text("Remaining Balls: \(remainingBalls)")
                    .font(.subheadline)
                    .foregroundColor(.red)
            }

            Section(header: Text("Red Drone Landing").foregroundColor(.red)) {
                Picker("Red Drone Landing", selection: $redDroneSelection) {
                    ForEach(landingOptions, id: \.self) { option in
                        Text(option)
                            .foregroundColor(.red)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }

            Section(header: Text("Blue Drone Landing").foregroundColor(.blue)) {
                Picker("Blue Drone Landing", selection: $blueDroneSelection) {
                    ForEach(landingOptions, id: \.self) { option in
                        Text(option)
                            .foregroundColor(.blue)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
        }
        .navigationTitle("Teamwork Score Calculator")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: clearInputs) {
                    Image(systemName: "trash")
                }.accessibilityLabel("Clear Scores")
            }
        }
        .onAppear {
            navigation_bar_manager.title = "Teamwork Score Calculator"
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

    // Remaining bean bags allowed (maximum 7 between green and blue)
    var remainingBeanBags: Int {
        return max(0, 7 - (greenBeanBags + blueBeanBags))
    }

    // Remaining balls allowed (maximum 10 between neutral, green, and blue)
    var remainingBalls: Int {
        return max(0, 10 - (neutralBalls + greenBalls + blueBalls))
    }

    // Max counts for bean bags
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
}

struct TeamworkScoreCalculator_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TeamworkScoreCalculator()
                .environmentObject(UserSettings())
                .environmentObject(NavigationBarManager(title: "Teamwork Score Calculator"))
        }
    }
}
