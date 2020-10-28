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

import XCTest
@testable import ENA

// swiftlint:disable file_length
// swiftlint:disable:next type_body_length
class ExposureSubmissionCoordinatorModelTests: XCTestCase {

	// default provider for a static app configuration
	let configProvider = CachedAppConfiguration(client: CachingHTTPClientMock(), store: MockTestStore())

	override func setUp() {
		// No property needed, Store uses a common database file
		let store = MockTestStore()
		store.appConfig = nil
		store.lastAppConfigETag = nil
	}

	override func tearDown() {
		// No property needed, Store uses a common database file
		let store = MockTestStore()
		store.appConfig = nil
		store.lastAppConfigETag = nil
	}

	func testExposureSubmissionServiceHasRegistrationToken() {
		let exposureSubmissionService = MockExposureSubmissionService()
		exposureSubmissionService.hasRegistrationTokenCallback = { true }

		let model = ExposureSubmissionCoordinatorModel(
			exposureSubmissionService: exposureSubmissionService,
			appConfigurationProvider: configProvider
		)

		XCTAssertTrue(model.exposureSubmissionServiceHasRegistrationToken)
	}

	func testExposureSubmissionServiceHasNoRegistrationToken() {
		let exposureSubmissionService = MockExposureSubmissionService()
		exposureSubmissionService.hasRegistrationTokenCallback = { false }

		let model = ExposureSubmissionCoordinatorModel(
			exposureSubmissionService: exposureSubmissionService,
			appConfigurationProvider: configProvider
		)

		XCTAssertFalse(model.exposureSubmissionServiceHasRegistrationToken)
	}

	// MARK: -

	func testSymptomsOptionYesSelected() {
		let model = ExposureSubmissionCoordinatorModel(
			exposureSubmissionService: MockExposureSubmissionService(),
			appConfigurationProvider: configProvider
		)

		model.symptomsOptionSelected(.yes)

		XCTAssertTrue(model.shouldShowSymptomsOnsetScreen)
	}

	func testSymptomsOptionNoSelected() {
		let exposureSubmissionService = MockExposureSubmissionService()
		exposureSubmissionService.submitExposureCallback = { symptomsOnset, _, _ in
			XCTAssertEqual(symptomsOnset, .nonSymptomatic)
		}

		let model = ExposureSubmissionCoordinatorModel(
			exposureSubmissionService: exposureSubmissionService,
			appConfigurationProvider: configProvider
		)

		model.symptomsOptionSelected(.no)

		// Submit to check that correct symptoms onset is set
		model.warnOthersConsentGiven(isLoading: { _ in }, onSuccess: { }, onError: { _ in })

		XCTAssertFalse(model.shouldShowSymptomsOnsetScreen)
	}

	func testSymptomsOptionPreferNotToSaySelected() {
		let exposureSubmissionService = MockExposureSubmissionService()
		exposureSubmissionService.submitExposureCallback = { symptomsOnset, _, _ in
			XCTAssertEqual(symptomsOnset, .noInformation)
		}

		let model = ExposureSubmissionCoordinatorModel(
			exposureSubmissionService: exposureSubmissionService,
			appConfigurationProvider: configProvider
		)

		model.symptomsOptionSelected(.preferNotToSay)

		// Submit to check that correct symptoms onset is set
		model.warnOthersConsentGiven(isLoading: { _ in }, onSuccess: { }, onError: { _ in })

		XCTAssertFalse(model.shouldShowSymptomsOnsetScreen)
	}

	// MARK: -

	func testSymptomsOnsetOptionExactDateSelected() throws {
		let exposureSubmissionService = MockExposureSubmissionService()
		exposureSubmissionService.submitExposureCallback = { symptomsOnset, _, _ in
			XCTAssertEqual(symptomsOnset, .daysSinceOnset(1))
		}

		let model = ExposureSubmissionCoordinatorModel(
			exposureSubmissionService: exposureSubmissionService,
			appConfigurationProvider: configProvider
		)

		let yesterday = try XCTUnwrap(Calendar.gregorian().date(byAdding: .day, value: -1, to: Date()))

		model.symptomsOnsetOptionSelected(.exactDate(yesterday))

		// Submit to check that correct symptoms onset is set
		model.warnOthersConsentGiven(isLoading: { _ in }, onSuccess: { }, onError: { _ in })
	}

	func testSymptomsOnsetOptionLastSevenDaysSelected() throws {
		let exposureSubmissionService = MockExposureSubmissionService()
		exposureSubmissionService.submitExposureCallback = { symptomsOnset, _, _ in
			XCTAssertEqual(symptomsOnset, .lastSevenDays)
		}

		let model = ExposureSubmissionCoordinatorModel(
			exposureSubmissionService: exposureSubmissionService,
			appConfigurationProvider: configProvider
		)

		model.symptomsOnsetOptionSelected(.lastSevenDays)

		// Submit to check that correct symptoms onset is set
		model.warnOthersConsentGiven(isLoading: { _ in }, onSuccess: { }, onError: { _ in })
	}

	func testSymptomsOnsetOptionOneToTwoWeeksAgoSelected() throws {
		let exposureSubmissionService = MockExposureSubmissionService()
		exposureSubmissionService.submitExposureCallback = { symptomsOnset, _, _ in
			XCTAssertEqual(symptomsOnset, .oneToTwoWeeksAgo)
		}

		let model = ExposureSubmissionCoordinatorModel(
			exposureSubmissionService: exposureSubmissionService,
			appConfigurationProvider: configProvider
		)

		model.symptomsOnsetOptionSelected(.oneToTwoWeeksAgo)

		// Submit to check that correct symptoms onset is set
		model.warnOthersConsentGiven(isLoading: { _ in }, onSuccess: { }, onError: { _ in })
	}

	func testSymptomsOnsetOptionMoreThanTwoWeeksAgoSelected() throws {
		let exposureSubmissionService = MockExposureSubmissionService()
		exposureSubmissionService.submitExposureCallback = { symptomsOnset, _, _ in
			XCTAssertEqual(symptomsOnset, .moreThanTwoWeeksAgo)
		}

		let model = ExposureSubmissionCoordinatorModel(
			exposureSubmissionService: exposureSubmissionService,
			appConfigurationProvider: configProvider
		)

		model.symptomsOnsetOptionSelected(.moreThanTwoWeeksAgo)

		// Submit to check that correct symptoms onset is set
		model.warnOthersConsentGiven(isLoading: { _ in }, onSuccess: { }, onError: { _ in })
	}

	func testSymptomsOnsetOptionPreferNotToSaySelected() throws {
		let exposureSubmissionService = MockExposureSubmissionService()
		exposureSubmissionService.submitExposureCallback = { symptomsOnset, _, _ in
			XCTAssertEqual(symptomsOnset, .symptomaticWithUnknownOnset)
		}

		let model = ExposureSubmissionCoordinatorModel(
			exposureSubmissionService: exposureSubmissionService,
			appConfigurationProvider: configProvider
		)

		model.symptomsOnsetOptionSelected(.preferNotToSay)

		// Submit to check that correct symptoms onset is set
		model.warnOthersConsentGiven(isLoading: { _ in }, onSuccess: { }, onError: { _ in })
	}

	// MARK: -

	func testSuccessfulSubmit() {
		let exposureSubmissionService = MockExposureSubmissionService()
		exposureSubmissionService.submitExposureCallback = { _, _, completion in
			completion(nil)
		}

		let model = ExposureSubmissionCoordinatorModel(
			exposureSubmissionService: exposureSubmissionService,
			appConfigurationProvider: configProvider
		)

		let expectedIsLoadingValues = [true, false]
		var isLoadingValues = [Bool]()

		let isLoadingExpectation = expectation(description: "isLoading is called twice")
		isLoadingExpectation.expectedFulfillmentCount = 2

		let onSuccessExpectation = expectation(description: "onSuccess is called")

		let onErrorExpectation = expectation(description: "onError is not called")
		onErrorExpectation.isInverted = true

		model.warnOthersConsentGiven(
			isLoading: {
				isLoadingValues.append($0)
				isLoadingExpectation.fulfill()
			},
			onSuccess: { onSuccessExpectation.fulfill() },
			onError: { _ in onErrorExpectation.fulfill() }
		)

		waitForExpectations(timeout: .short)
		XCTAssertEqual(isLoadingValues, expectedIsLoadingValues)
	}

	func testSuccessfulSubmitWithoutKeys() {
		let exposureSubmissionService = MockExposureSubmissionService()
		exposureSubmissionService.submitExposureCallback = { _, _, completion in
			completion(.noKeys)
		}

		let model = ExposureSubmissionCoordinatorModel(
			exposureSubmissionService: exposureSubmissionService,
			appConfigurationProvider: configProvider
		)

		let expectedIsLoadingValues = [true, false]
		var isLoadingValues = [Bool]()

		let isLoadingExpectation = expectation(description: "isLoading is called twice")
		isLoadingExpectation.expectedFulfillmentCount = 2

		let onSuccessExpectation = expectation(description: "onSuccess is called")

		let onErrorExpectation = expectation(description: "onError is not called")
		onErrorExpectation.isInverted = true

		model.warnOthersConsentGiven(
			isLoading: {
				isLoadingValues.append($0)
				isLoadingExpectation.fulfill()
			},
			onSuccess: { onSuccessExpectation.fulfill() },
			onError: { _ in onErrorExpectation.fulfill() }
		)

		waitForExpectations(timeout: .short)
		XCTAssertEqual(isLoadingValues, expectedIsLoadingValues)
	}

	func testFailingSubmitWithNotAuthorizedError() {
		let exposureSubmissionService = MockExposureSubmissionService()
		exposureSubmissionService.submitExposureCallback = { _, _, completion in
			completion(.notAuthorized)
		}

		let model = ExposureSubmissionCoordinatorModel(
			exposureSubmissionService: exposureSubmissionService,
			appConfigurationProvider: configProvider
		)

		let expectedIsLoadingValues = [true, false]
		var isLoadingValues = [Bool]()

		let isLoadingExpectation = expectation(description: "isLoading is called twice")
		isLoadingExpectation.expectedFulfillmentCount = 2

		let onSuccessExpectation = expectation(description: "onSuccess is not called")
		onSuccessExpectation.isInverted = true

		// .notAuthorized should not trigger an error
		let onErrorExpectation = expectation(description: "onError is not called")
		onErrorExpectation.isInverted = true

		model.warnOthersConsentGiven(
			isLoading: {
				isLoadingValues.append($0)
				isLoadingExpectation.fulfill()
			},
			onSuccess: { onSuccessExpectation.fulfill() },
			onError: { _ in onErrorExpectation.fulfill() }
		)

		waitForExpectations(timeout: .short)
		XCTAssertEqual(isLoadingValues, expectedIsLoadingValues)
	}

	func testFailingSubmitWithInternalError() {
		let exposureSubmissionService = MockExposureSubmissionService()
		exposureSubmissionService.submitExposureCallback = { _, _, completion in
			completion(.internal)
		}

		let model = ExposureSubmissionCoordinatorModel(
			exposureSubmissionService: exposureSubmissionService,
			appConfigurationProvider: configProvider
		)

		let expectedIsLoadingValues = [true, false]
		var isLoadingValues = [Bool]()

		let isLoadingExpectation = expectation(description: "isLoading is called twice")
		isLoadingExpectation.expectedFulfillmentCount = 2

		let onSuccessExpectation = expectation(description: "onSuccess is not called")
		onSuccessExpectation.isInverted = true

		let onErrorExpectation = expectation(description: "onError is called")

		model.warnOthersConsentGiven(
			isLoading: {
				isLoadingValues.append($0)
				isLoadingExpectation.fulfill()
			},
			onSuccess: { onSuccessExpectation.fulfill() },
			onError: { _ in onErrorExpectation.fulfill() }
		)

		waitForExpectations(timeout: .short)
		XCTAssertEqual(isLoadingValues, expectedIsLoadingValues)
	}

	func testGetTestResultSucceeds() {
		let expectedTestResult: TestResult = .positive

		let exposureSubmissionService = MockExposureSubmissionService()
		exposureSubmissionService.getTestResultCallback = { completion in
			completion(.success(expectedTestResult))
		}

		let model = ExposureSubmissionCoordinatorModel(
			exposureSubmissionService: exposureSubmissionService,
			appConfigurationProvider: configProvider
		)

		let expectedIsLoadingValues = [true, false]
		var isLoadingValues = [Bool]()

		let isLoadingExpectation = expectation(description: "isLoading is called twice")
		isLoadingExpectation.expectedFulfillmentCount = 2

		let onSuccessExpectation = expectation(description: "onSuccess is called")

		let onErrorExpectation = expectation(description: "onError is not called")
		onErrorExpectation.isInverted = true

		model.getTestResults(
			for: .guid(""),
			isLoading: {
				isLoadingValues.append($0)
				isLoadingExpectation.fulfill()
			},
			onSuccess: { testResult in
				XCTAssertEqual(testResult, expectedTestResult)

				onSuccessExpectation.fulfill()
			},
			onError: { _ in onErrorExpectation.fulfill() }
		)

		waitForExpectations(timeout: .short)
		XCTAssertEqual(isLoadingValues, expectedIsLoadingValues)
	}

	func testGetTestResultFails() {
		let expectedError: ExposureSubmissionError = .unknown

		let exposureSubmissionService = MockExposureSubmissionService()
		exposureSubmissionService.getTestResultCallback = { completion in
			completion(.failure(expectedError))
		}

		let model = ExposureSubmissionCoordinatorModel(
			exposureSubmissionService: exposureSubmissionService,
			appConfigurationProvider: configProvider
		)

		let expectedIsLoadingValues = [true, false]
		var isLoadingValues = [Bool]()

		let isLoadingExpectation = expectation(description: "isLoading is called twice")
		isLoadingExpectation.expectedFulfillmentCount = 2

		let onSuccessExpectation = expectation(description: "onSuccess is not called")
		onSuccessExpectation.isInverted = true

		let onErrorExpectation = expectation(description: "onError is called")

		model.getTestResults(
			for: .guid(""),
			isLoading: {
				isLoadingValues.append($0)
				isLoadingExpectation.fulfill()
			},
			onSuccess: { _ in onSuccessExpectation.fulfill() },
			onError: { error in
				XCTAssertEqual(error, expectedError)

				onErrorExpectation.fulfill()
			}
		)

		waitForExpectations(timeout: .short)
		XCTAssertEqual(isLoadingValues, expectedIsLoadingValues)
	}

}
