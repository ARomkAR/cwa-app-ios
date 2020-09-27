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
import Foundation
import ExposureNotification
import XCTest

final class ExposureKeysProcessingTests: XCTestCase {

	func testSubmissionPreprocess_ApplyNoInformationVector() {
		let symptomsOnset: SymptomsOnset = .noInformation
		let transmissionRiskVector = symptomsOnset.transmissionRiskVector

		let days = 0...14
		var keys = days.map { makeMockKey(daysUntilToday: $0) }
		keys = keys.processedForSubmission(with: symptomsOnset, today: Date(timeIntervalSinceReferenceDate: 0))

		keys.sort { $0.rollingStartNumber > $1.rollingStartNumber }

		for (key, day) in zip(keys, days) {
			XCTAssertEqual(
				key.transmissionRiskLevel,
				transmissionRiskVector[day],
				"Transmission Risk Level vector not applied correctly! Expected \(transmissionRiskVector[day]), got \(key.transmissionRiskLevel)"
			)
		}
	}

	func testSubmissionPreprocess_ApplyNonSymptomaticVector() {
		let symptomsOnset: SymptomsOnset = .nonSymptomatic
		let transmissionRiskVector = symptomsOnset.transmissionRiskVector

		let days = 0...14
		var keys = days.map { makeMockKey(daysUntilToday: $0) }
		keys = keys.processedForSubmission(with: symptomsOnset, today: Date(timeIntervalSinceReferenceDate: 0))

		keys.sort { $0.rollingStartNumber > $1.rollingStartNumber }

		for (key, day) in zip(keys, days) {
			XCTAssertEqual(
				key.transmissionRiskLevel,
				transmissionRiskVector[day],
				"Transmission Risk Level vector not applied correctly! Expected \(transmissionRiskVector[day]), got \(key.transmissionRiskLevel)"
			)
		}
	}

	func testSubmissionPreprocess_ApplySymptomaticWithUnknownOnsetDaysVector() {
		let symptomsOnset: SymptomsOnset = .symptomaticWithUnknownOnset
		let transmissionRiskVector = symptomsOnset.transmissionRiskVector

		let days = 0...14
		var keys = days.map { makeMockKey(daysUntilToday: $0) }
		keys = keys.processedForSubmission(with: symptomsOnset, today: Date(timeIntervalSinceReferenceDate: 0))

		keys.sort { $0.rollingStartNumber > $1.rollingStartNumber }

		for (key, day) in zip(keys, days) {
			XCTAssertEqual(
				key.transmissionRiskLevel,
				transmissionRiskVector[day],
				"Transmission Risk Level vector not applied correctly! Expected \(transmissionRiskVector[day]), got \(key.transmissionRiskLevel)"
			)
		}
	}

	func testSubmissionPreprocess_ApplyLastSevenDaysVector() {
		let symptomsOnset: SymptomsOnset = .lastSevenDays
		let transmissionRiskVector = symptomsOnset.transmissionRiskVector

		let days = 0...14
		var keys = days.map { makeMockKey(daysUntilToday: $0) }
		keys = keys.processedForSubmission(with: symptomsOnset, today: Date(timeIntervalSinceReferenceDate: 0))

		keys.sort { $0.rollingStartNumber > $1.rollingStartNumber }

		for (key, day) in zip(keys, days) {
			XCTAssertEqual(
				key.transmissionRiskLevel,
				transmissionRiskVector[day],
				"Transmission Risk Level vector not applied correctly! Expected \(transmissionRiskVector[day]), got \(key.transmissionRiskLevel)"
			)
		}
	}

	func testSubmissionPreprocess_ApplyOneToTwoWeeksAgoVector() {
		let symptomsOnset: SymptomsOnset = .oneToTwoWeeksAgo
		let transmissionRiskVector = symptomsOnset.transmissionRiskVector

		let days = 0...14
		var keys = days.map { makeMockKey(daysUntilToday: $0) }
		keys = keys.processedForSubmission(with: symptomsOnset, today: Date(timeIntervalSinceReferenceDate: 0))

		keys.sort { $0.rollingStartNumber > $1.rollingStartNumber }

		for (key, day) in zip(keys, days) {
			XCTAssertEqual(
				key.transmissionRiskLevel,
				transmissionRiskVector[day],
				"Transmission Risk Level vector not applied correctly! Expected \(transmissionRiskVector[day]), got \(key.transmissionRiskLevel)"
			)
		}
	}

	func testSubmissionPreprocess_ApplyMoreThanTwoWeeksAgoVector() {
		let symptomsOnset: SymptomsOnset = .moreThanTwoWeeksAgo
		let transmissionRiskVector = symptomsOnset.transmissionRiskVector

		let days = 0...14
		var keys = days.map { makeMockKey(daysUntilToday: $0) }
		keys = keys.processedForSubmission(with: symptomsOnset, today: Date(timeIntervalSinceReferenceDate: 0))

		keys.sort { $0.rollingStartNumber > $1.rollingStartNumber }

		for (key, day) in zip(keys, days) {
			XCTAssertEqual(
				key.transmissionRiskLevel,
				transmissionRiskVector[day],
				"Transmission Risk Level vector not applied correctly! Expected \(transmissionRiskVector[day]), got \(key.transmissionRiskLevel)"
			)
		}
	}

	func testSubmissionPreprocess_ApplyDaysSinceOnsetVector() {
		for daysSinceOnset in 0..<22 {
			let symptomsOnset: SymptomsOnset = .daysSinceOnset(daysSinceOnset)
			let transmissionRiskVector = symptomsOnset.transmissionRiskVector

			let days = 0...14
			var keys = days.map { makeMockKey(daysUntilToday: $0) }
			keys = keys.processedForSubmission(with: symptomsOnset, today: Date(timeIntervalSinceReferenceDate: 0))

			keys.sort { $0.rollingStartNumber > $1.rollingStartNumber }

			for (key, day) in zip(keys, days) {
				XCTAssertEqual(
					key.transmissionRiskLevel,
					transmissionRiskVector[day],
					"Transmission Risk Level vector not applied correctly! Expected \(transmissionRiskVector[day]), got \(key.transmissionRiskLevel)"
				)
			}
		}
	}

	func testSubmissionPreprocess_NoKeys() {
		var keys = [ENTemporaryExposureKey]()
		keys = keys.processedForSubmission(with: .noInformation)

		XCTAssertEqual(keys.count, 0)
	}

	func testSubmissionPreprocess_TodaysKeyMissing() {
		let symptomsOnset: SymptomsOnset = .daysSinceOnset(7)
		let transmissionRiskVector = symptomsOnset.transmissionRiskVector

		let days = 1...14
		var keys = days.map { makeMockKey(daysUntilToday: $0) }
		keys = keys.processedForSubmission(with: symptomsOnset, today: Date(timeIntervalSinceReferenceDate: 0))

		keys.sort { $0.rollingStartNumber > $1.rollingStartNumber }

		for (key, day) in zip(keys, days) {
			XCTAssertEqual(
				key.transmissionRiskLevel,
				transmissionRiskVector[day],
				"Transmission Risk Level vector not applied correctly! Expected \(transmissionRiskVector[day]), got \(key.transmissionRiskLevel)"
			)
		}
	}

	func testSubmissionPreprocess_14DaysAgoKeyMissing() {
		let symptomsOnset: SymptomsOnset = .daysSinceOnset(7)
		let transmissionRiskVector = symptomsOnset.transmissionRiskVector

		let days = 1...13
		var keys = days.map { makeMockKey(daysUntilToday: $0) }
		keys = keys.processedForSubmission(with: symptomsOnset, today: Date(timeIntervalSinceReferenceDate: 0))

		keys.sort { $0.rollingStartNumber > $1.rollingStartNumber }

		for (key, day) in zip(keys, days) {
			XCTAssertEqual(
				key.transmissionRiskLevel,
				transmissionRiskVector[day],
				"Transmission Risk Level vector not applied correctly! Expected \(transmissionRiskVector[day]), got \(key.transmissionRiskLevel)"
			)
		}
	}

	func testSubmissionPreprocess_InBetweenKeyMissing() {
		 let symptomsOnset: SymptomsOnset = .daysSinceOnset(7)
		 let transmissionRiskVector = symptomsOnset.transmissionRiskVector

		 let days = [0, 1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 12, 13, 14]
		 var keys = days.map { makeMockKey(daysUntilToday: $0) }
		 keys = keys.processedForSubmission(with: symptomsOnset, today: Date(timeIntervalSinceReferenceDate: 0))

		 keys.sort { $0.rollingStartNumber > $1.rollingStartNumber }

		 for (key, day) in zip(keys, days) {
			 XCTAssertEqual(
				 key.transmissionRiskLevel,
				 transmissionRiskVector[day],
				 "Transmission Risk Level vector not applied correctly! Expected \(transmissionRiskVector[day]), got \(key.transmissionRiskLevel)"
			 )
		}
	}

	func testSubmissionPreprocess_MultipleKeysMissing() {
		 let symptomsOnset: SymptomsOnset = .daysSinceOnset(7)
		 let transmissionRiskVector = symptomsOnset.transmissionRiskVector

		 let days = [1, 2, 3, 4, 5, 8, 9, 10, 11, 13, 14]
		 var keys = days.map { makeMockKey(daysUntilToday: $0) }
		 keys = keys.processedForSubmission(with: symptomsOnset, today: Date(timeIntervalSinceReferenceDate: 0))

		 keys.sort { $0.rollingStartNumber > $1.rollingStartNumber }

		 for (key, day) in zip(keys, days) {
			 XCTAssertEqual(
				 key.transmissionRiskLevel,
				 transmissionRiskVector[day],
				 "Transmission Risk Level vector not applied correctly! Expected \(transmissionRiskVector[day]), got \(key.transmissionRiskLevel)"
			 )
		}
	}

	func testSubmissionPreprocess_MultipleKeysForOneDay() {
		 let symptomsOnset: SymptomsOnset = .daysSinceOnset(7)
		 let transmissionRiskVector = symptomsOnset.transmissionRiskVector

		 let days = [0, 0, 0, 1, 2, 3, 4, 5, 6, 6, 7, 7, 7, 8, 9, 10, 11, 12, 12, 13, 14, 14]
		 var keys = days.map { makeMockKey(daysUntilToday: $0) }
		 keys = keys.processedForSubmission(with: symptomsOnset, today: Date(timeIntervalSinceReferenceDate: 0))

		 keys.sort { $0.rollingStartNumber > $1.rollingStartNumber }

		 for (key, day) in zip(keys, days) {
			 XCTAssertEqual(
				 key.transmissionRiskLevel,
				 transmissionRiskVector[day],
				 "Transmission Risk Level vector not applied correctly! Expected \(transmissionRiskVector[day]), got \(key.transmissionRiskLevel)"
			 )
		}
	}

	func testSubmissionPreprocess_KeysFromTheFutureAreIgnored() {
		 let symptomsOnset: SymptomsOnset = .daysSinceOnset(7)
		 let transmissionRiskVector = symptomsOnset.transmissionRiskVector

		 let days = [-6, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
		 var keys = days.map { makeMockKey(daysUntilToday: $0) }
		 keys = keys.processedForSubmission(with: symptomsOnset, today: Date(timeIntervalSinceReferenceDate: 0))

		 keys.sort { $0.rollingStartNumber > $1.rollingStartNumber }

		let filteredDays = days.filter { (0...14).contains($0) }
		for (key, day) in zip(keys, filteredDays) {
			 XCTAssertEqual(
				 key.transmissionRiskLevel,
				 transmissionRiskVector[day],
				 "Transmission Risk Level vector not applied correctly! Expected \(transmissionRiskVector[day]), got \(key.transmissionRiskLevel)"
			 )
		}
	}

	func testSubmissionPreprocess_KeysOlderThan14DaysAreeIgnored() {
		 let symptomsOnset: SymptomsOnset = .daysSinceOnset(7)
		 let transmissionRiskVector = symptomsOnset.transmissionRiskVector

		 let days = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 32, 167]
		 var keys = days.map { makeMockKey(daysUntilToday: $0) }
		 keys = keys.processedForSubmission(with: symptomsOnset, today: Date(timeIntervalSinceReferenceDate: 0))

		 keys.sort { $0.rollingStartNumber > $1.rollingStartNumber }

		let filteredDays = days.filter { (0...14).contains($0) }
		for (key, day) in zip(keys, filteredDays) {
			 XCTAssertEqual(
				 key.transmissionRiskLevel,
				 transmissionRiskVector[day],
				 "Transmission Risk Level vector not applied correctly! Expected \(transmissionRiskVector[day]), got \(key.transmissionRiskLevel)"
			 )
		}
	}

	func testSubmissionPreprocess_ManyEdgeCases() {
		 let symptomsOnset: SymptomsOnset = .daysSinceOnset(7)
		 let transmissionRiskVector = symptomsOnset.transmissionRiskVector

		 let days = [-54, -3, 1, 2, 3, 4, 6, 6, 6, 6, 6, 6, 7, 8, 9, 10, 11, 15, 16, 32, 167]
		 var keys = days.map { makeMockKey(daysUntilToday: $0) }
		 keys = keys.processedForSubmission(with: symptomsOnset, today: Date(timeIntervalSinceReferenceDate: 0))

		 keys.sort { $0.rollingStartNumber > $1.rollingStartNumber }

		let filteredDays = days.filter { (0...14).contains($0) }
		for (key, day) in zip(keys, filteredDays) {
			 XCTAssertEqual(
				 key.transmissionRiskLevel,
				 transmissionRiskVector[day],
				 "Transmission Risk Level vector not applied correctly! Expected \(transmissionRiskVector[day]), got \(key.transmissionRiskLevel)"
			 )
		}
	}

}

// MARK: - Helpers

extension ExposureKeysProcessingTests {

	private func makeMockKey(daysUntilToday: Int, today: Date = Date(timeIntervalSinceReferenceDate: 0)) -> ENTemporaryExposureKey {
		var calendar = Calendar(identifier: .gregorian)
		// swiftlint:disable:next force_unwrapping
		calendar.timeZone = TimeZone(secondsFromGMT: 0)!

		guard let date = calendar.date(byAdding: .day, value: -daysUntilToday, to: today) else { fatalError("Could not create date") }

		return TemporaryExposureKeyMock(rollingStartNumber: ENIntervalNumber(date.timeIntervalSince1970 / 600))
	}
}
