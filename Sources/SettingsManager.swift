import Foundation
import SwiftUI

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    @Published var completedTests: [String: Bool] = [:]
    @Published var testSettings: [String: [String: Any]] = [:]

    private let defaults = UserDefaults.standard
    private let completedTestsKey = "CompletedTests"
    private let testSettingsKey = "TestSettings"

    private init() {
        loadData()
    }

    func markTestCompleted(_ testId: String, completed: Bool = true) {
        completedTests[testId] = completed
        saveData()
    }

    func isTestCompleted(_ testId: String) -> Bool {
        return completedTests[testId] ?? false
    }

    func saveSetting(testId: String, key: String, value: Any) {
        if var settings = testSettings[testId] {
            settings[key] = value
            testSettings[testId] = settings
        } else {
            testSettings[testId] = [key: value]
        }
        // UserDefaults doesn't support [String: Any] directly if Any is not property list object.
        // For simple types (String, Int, Double, Bool), it works.
        saveData()
    }

    func getSetting<T>(testId: String, key: String, defaultValue: T) -> T {
        guard let settings = testSettings[testId],
              let value = settings[key] as? T else {
            return defaultValue
        }
        return value
    }

    private func saveData() {
        defaults.set(completedTests, forKey: completedTestsKey)
        defaults.set(testSettings, forKey: testSettingsKey)
    }

    private func loadData() {
        if let savedTests = defaults.dictionary(forKey: completedTestsKey) as? [String: Bool] {
            completedTests = savedTests
        }
        if let savedSettings = defaults.dictionary(forKey: testSettingsKey) as? [String: [String: Any]] {
            testSettings = savedSettings
        }
    }
}
