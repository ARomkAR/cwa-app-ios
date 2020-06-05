//
// Corona-Warn-App
//
// SAP SE and all other contributors
// copyright owners license this file to you under the Apache
// License, Version 2.0 (the "License"); you may not use this
// file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.
//

@testable import ENA
import ExposureNotification
import XCTest

final class RiskExposureCalculationTests: XCTestCase {

	// MARK: - Tests for calculating raw risk score

	func testCalculateRawRiskScore_Zero() throws {
		let summaryZeroMaxRisk = makeExposureSummaryContainer(maxRiskScore: 0, ad_low: 10, ad_mid: 10, ad_high: 10)
		XCTAssertEqual(RiskExposureCalculation.calculateRawRisk(summary: summaryZeroMaxRisk, configuration: appConfig), 0.0)
	}

	func testCalculateRawRiskScore_Low() throws {
		XCTAssertEqual(RiskExposureCalculation.calculateRawRisk(summary: summaryLow, configuration: appConfig), 1.07)
	}

	func testCalculateRawRiskScore_Med() throws {
		XCTAssertEqual(RiskExposureCalculation.calculateRawRisk(summary: summaryMed, configuration: appConfig), 2.56)
	}

	func testCalculateRawRiskScore_High() throws {
		XCTAssertEqual(RiskExposureCalculation.calculateRawRisk(summary: summaryHigh, configuration: appConfig), 10.2)
	}

	// MARK: - Tests for calculating risk levels

	func testCalculateRisk_Inactive() throws {
		// Test the condition when the risk is returned as inactive
		// This occurs when the preconditions are not met, ex. when tracing is off.
		let risk = try RiskExposureCalculation.risk(
			summary: summaryHigh,
			configuration: appConfig,
			dateLastExposureDetection: Date(),
			numberOfTracingActiveDays: 2,
			preconditions: preconditions(.invalid)).get()

		XCTAssertEqual(risk.level, .inactive)
	}

	func testCalculateRisk_UnknownInitial() throws {
		// Test the condition when the risk is returned as unknownInitial

		// That will happen when:
		// 1. The number of hours tracing has been active for is less than one day
		// 2. There is no ENExposureDetectionSummary to use

		// Test case for tracing not being active long enough
		var risk = try RiskExposureCalculation.risk(
			summary: summaryLow,
			configuration: appConfig,
			dateLastExposureDetection: Date(),
			numberOfTracingActiveDays: 0,
			preconditions: preconditions(.valid)).get()

		XCTAssertEqual(risk.level, .unknownInitial)

		// Test case when summary is nil
		risk = try RiskExposureCalculation.risk(
			summary: nil,
			configuration: appConfig,
			dateLastExposureDetection: Date(),
			numberOfTracingActiveDays: 15,
			preconditions: preconditions(.valid)).get()

		XCTAssertEqual(risk.level, .unknownInitial)
	}

	func testCalculateRisk_UnknownOutdated() throws {
		// Test the condition when the risk is returned as unknownOutdated.

		// That will happen when the date of last exposure detection is older than one day
		let risk = try RiskExposureCalculation.risk(
			summary: summaryLow,
			configuration: appConfig,
			dateLastExposureDetection: Date().addingTimeInterval(.init(days: -1)),
			numberOfTracingActiveDays: 15,
			preconditions: preconditions(.valid)).get()

		XCTAssertEqual(risk.level, .unknownOutdated)
	}

	func testCalculateRisk_LowRisk() throws {
		// Test the case where preconditions pass and there is low risk
		let risk = try RiskExposureCalculation.risk(
			summary: summaryLow,
			configuration: appConfig,
			// arbitrary, but within limit
			dateLastExposureDetection: Date().addingTimeInterval(-3600),
			numberOfTracingActiveDays: 15,
			preconditions: preconditions(.valid)).get()

		XCTAssertEqual(risk.level, .low)
	}

	func testCalculateRisk_IncreasedRisk() throws {
		// Test the case where preconditions pass and there is increased risk
		let risk = try RiskExposureCalculation.risk(
			summary: summaryHigh,
			configuration: appConfig,
			// arbitrary, but within limit
			dateLastExposureDetection: Date().addingTimeInterval(-3600),
			numberOfTracingActiveDays: 15,
			preconditions: preconditions(.valid)).get()

		XCTAssertEqual(risk.level, .increased)
	}

	// MARK: - Risk Level Calculation Error Cases

	func testCalculateRisk_OutsideRangeError_Middle() throws {
		// Test the case where preconditions pass and there is increased risk
		// Values below are hand-picked to result in a raw risk score of 5.12 - within a gap in the range
		let summary = makeExposureSummaryContainer(maxRiskScore: 128, ad_low: 30, ad_mid: 30, ad_high: 30)
		let risk = RiskExposureCalculation.risk(
			summary: summary,
			configuration: appConfig,
			// arbitrary, but within limit
			dateLastExposureDetection: Date().addingTimeInterval(-3600),
			numberOfTracingActiveDays: 15,
			preconditions: preconditions(.valid))

		XCTAssertThrowsError(try risk.get())
	}

	func testCalculateRisk_OutsideRangeError_OffHigh() throws {
		// Test the case where preconditions pass and there is increased risk
		// Values below are hand-picked to result in a raw risk score of 13.6 - outside of the top range of the config
		let summary = makeExposureSummaryContainer(maxRiskScore: 255, ad_low: 40, ad_mid: 40, ad_high: 40)
		let risk = RiskExposureCalculation.risk(
			summary: summary,
			configuration: appConfig,
			// arbitrary, but within limit
			dateLastExposureDetection: Date().addingTimeInterval(-3600),
			numberOfTracingActiveDays: 15,
			preconditions: preconditions(.valid))

		XCTAssertThrowsError(try risk.get())
	}

	func testCalculateRisk_OutsideRangeError_TooLow() throws {
		// Test the case where preconditions pass and there is increased risk
		// Values below are hand-picked to result in a raw risk score of 0.85 - outside of the botton bound of the config
		let summary = makeExposureSummaryContainer(maxRiskScore: 64, ad_low: 10, ad_mid: 10, ad_high: 10)
		let risk = RiskExposureCalculation.risk(
			summary: summary,
			configuration: appConfig,
			// arbitrary, but within limit
			dateLastExposureDetection: Date().addingTimeInterval(-3600),
			numberOfTracingActiveDays: 15,
			preconditions: preconditions(.valid))

		XCTAssertThrowsError(try risk.get())
	}

	// MARK: - Risk Level Calculation Hierarchy Tests

	// There is a certain order to risk levels, and some override others. This is tested below.

	func testCalculateRisk_IncreasedOverridesUnknownOutdated() throws {
		// Test case where last exposure summary was gotten too far in the past,
		// But the risk is increased
		let risk = try RiskExposureCalculation.risk(
			summary: summaryHigh,
			configuration: appConfig,
			dateLastExposureDetection: Date().addingTimeInterval(.init(days: -2)),
			numberOfTracingActiveDays: 15,
			preconditions: preconditions(.valid)).get()

		XCTAssertEqual(risk.level, .increased)
	}

	func testCalculateRisk_UnknownInitialOverridesUnknownOutdated() throws {
		// Test case where last exposure summary was gotten too far in the past,
		let risk = try RiskExposureCalculation.risk(
			summary: nil,
			configuration: appConfig,
			dateLastExposureDetection: Date().addingTimeInterval(.init(days: -2)),
			numberOfTracingActiveDays: 15,
			preconditions: preconditions(.valid)).get()

		XCTAssertEqual(risk.level, .unknownInitial)
	}
}

// MARK: - Helpers

private extension RiskExposureCalculationTests {

	private var appConfig: SAP_ApplicationConfiguration {
		makeAppConfig(w_low: 1.0, w_med: 0.5, w_high: 0.5)
	}

	private var summaryLow: ENExposureDetectionSummaryContainer {
		makeExposureSummaryContainer(maxRiskScore: 80, ad_low: 10, ad_mid: 10, ad_high: 10)
	}

	private var summaryMed: ENExposureDetectionSummaryContainer {
		makeExposureSummaryContainer(maxRiskScore: 128, ad_low: 15, ad_mid: 15, ad_high: 15)
	}

	private var summaryHigh: ENExposureDetectionSummaryContainer {
		makeExposureSummaryContainer(maxRiskScore: 255, ad_low: 30, ad_mid: 30, ad_high: 30)
	}

	enum PreconditionState {
		case valid
		case invalid
	}

	private func preconditions(_ state: PreconditionState) -> ExposureManagerState {
		switch state {
		case .valid:
			return ExposureManagerState(authorized: true, enabled: true, status: .active)
		default:
			return ExposureManagerState(authorized: true, enabled: false, status: .disabled)
		}
	}

	private func makeExposureSummaryContainer(
		maxRiskScore: ENRiskScore,
		ad_low: Double,
		ad_mid: Double,
		ad_high: Double
	) -> ENExposureDetectionSummaryContainer {
		ENExposureDetectionSummaryContainer(daysSinceLastExposure: 0, matchedKeyCount: 0, maximumRiskScore: maxRiskScore, attenuationDurations: [ad_low, ad_mid, ad_high]
		)
	}

	/// Makes an mock `SAP_ApplicationConfiguration`
	///
	/// Some defaults are applied for ad_norm, w4, and low & high ranges
	private func makeAppConfig(
		ad_norm: Int32 = 25,
		w4: Int32 = 0,
		w_low: Double,
		w_med: Double,
		w_high: Double,
		riskRangeLow: ClosedRange<Int32> = 1...5,
		// Gap between the ranges is on purpose, this is an edge case to test
		riskRangeHigh: Range<Int32> = 6..<11
	) -> SAP_ApplicationConfiguration {
		var config = SAP_ApplicationConfiguration()
		config.attenuationDuration.defaultBucketOffset = w4
		config.attenuationDuration.riskScoreNormalizationDivisor = ad_norm
		config.attenuationDuration.weights.low = w_low
		config.attenuationDuration.weights.mid = w_med
		config.attenuationDuration.weights.high = w_high

		var riskScoreClassLow = SAP_RiskScoreClass()
		riskScoreClassLow.label = "LOW"
		riskScoreClassLow.min = riskRangeLow.lowerBound
		riskScoreClassLow.max = riskRangeLow.upperBound

		var riskScoreClassHigh = SAP_RiskScoreClass()
		riskScoreClassHigh.label = "HIGH"
		riskScoreClassHigh.min = riskRangeHigh.lowerBound
		riskScoreClassHigh.max = riskRangeHigh.upperBound

		config.riskScoreClasses.riskClasses = [
			riskScoreClassLow,
			riskScoreClassHigh
		]

		return config
	}
}

private extension TimeInterval {
	init(days: Int) {
		self = Double(days * 24 * 60 * 60)
	}
}
