import XCTest
@testable import TargetLock

final class TargetLockTests: XCTestCase {

    private var previousDisplayUnit: DisplayUnit?
    private var previousTheme: AppTheme?
    private var previousGrid: Bool?

    override func setUp() {
        super.setUp()
        previousDisplayUnit = AppSettings.shared.displayUnit
        previousTheme = AppSettings.shared.theme
        previousGrid = AppSettings.shared.showGridOverlay
    }

    override func tearDown() {
        if let unit = previousDisplayUnit { AppSettings.shared.displayUnit = unit }
        if let theme = previousTheme { AppSettings.shared.theme = theme }
        if let grid = previousGrid { AppSettings.shared.showGridOverlay = grid }
        super.tearDown()
    }

    func testMeasurementCalculatorDistance() {
        let calculator = MeasurementCalculator()
        let distance = calculator.calculateDistanceMeters(
            focalLengthPixels: 1000,
            realHeightMeters: 2.0,
            pixelHeight: 500
        )
        XCTAssertEqual(distance, 4.0, accuracy: 0.0001)
    }

    func testMeasurementCalculatorZeroPixelHeight() {
        let calculator = MeasurementCalculator()
        let distance = calculator.calculateDistanceMeters(
            focalLengthPixels: 1000,
            realHeightMeters: 1.7,
            pixelHeight: 0
        )
        XCTAssertEqual(distance, 0)
    }

    func testPresetManagerContainsExpectedPresets() {
        let presets = PresetManager().presets()
        let titles = presets.map { $0.title }
        XCTAssertTrue(titles.contains("Adult Male (1.75m)"))
        XCTAssertTrue(titles.contains("Adult Female (1.65m)"))
        XCTAssertTrue(titles.contains("Child (1.20m)"))
        XCTAssertTrue(titles.contains("Large Dog (0.70m)"))
        XCTAssertTrue(titles.contains("Medium Dog (0.50m)"))
        XCTAssertTrue(titles.contains("Small Dog (0.30m)"))
    }

    func testAppSettingsDefaults() {
        AppSettings.shared.displayUnit = .both
        AppSettings.shared.theme = .system
        AppSettings.shared.showGridOverlay = false
        XCTAssertEqual(AppSettings.shared.displayUnit, .both)
        XCTAssertEqual(AppSettings.shared.theme, .system)
        XCTAssertEqual(AppSettings.shared.showGridOverlay, false)
    }

    func testAppSettingsPersistence() {
        AppSettings.shared.displayUnit = .feet
        AppSettings.shared.theme = .dark
        AppSettings.shared.showGridOverlay = true
        XCTAssertEqual(AppSettings.shared.displayUnit, .feet)
        XCTAssertEqual(AppSettings.shared.theme, .dark)
        XCTAssertEqual(AppSettings.shared.showGridOverlay, true)
    }
}
