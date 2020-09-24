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
import XCTest

// swiftlint:disable:next type_body_length
class ExposureSubmissionCoordinatorModelTests: XCTestCase {

	func testExposureSubmissionServiceHasRegistrationToken() {
		let exposureSubmissionService = MockExposureSubmissionService()
		exposureSubmissionService.hasRegistrationTokenCallback = { true }

		let model = ExposureSubmissionCoordinatorModel(
			exposureSubmissionService: exposureSubmissionService,
			appConfigurationProvider: MockAppConfiguration(mockSAPApplicationConfiguration: nil)
		)

		XCTAssertTrue(model.exposureSubmissionServiceHasRegistrationToken)
	}

	func testExposureSubmissionServiceHasNoRegistrationToken() {
		let exposureSubmissionService = MockExposureSubmissionService()
		exposureSubmissionService.hasRegistrationTokenCallback = { false }

		let model = ExposureSubmissionCoordinatorModel(
			exposureSubmissionService: exposureSubmissionService,
			appConfigurationProvider: MockAppConfiguration(mockSAPApplicationConfiguration: nil)
		)

		XCTAssertFalse(model.exposureSubmissionServiceHasRegistrationToken)
	}

	func testSymptomsOptionYesSelected() {
		let exposureSubmissionService = MockExposureSubmissionService()
		exposureSubmissionService.submitExposureCallback = { completion in
			completion(nil)
		}

		let model = ExposureSubmissionCoordinatorModel(
			exposureSubmissionService: exposureSubmissionService,
			appConfigurationProvider: MockAppConfiguration(mockSAPApplicationConfiguration: nil)
		)

		let expectedIsLoadingValues = [Bool]()
		var isLoadingValues = [Bool]()

		let isLoadingExpectation = expectation(description: "isLoading is not called")
		isLoadingExpectation.isInverted = true

		let onSuccessExpectation = expectation(description: "onSuccess is called")

		let onErrorExpectation = expectation(description: "onError is not called")
		onErrorExpectation.isInverted = true

		model.symptomsOptionSelected(
			selectedSymptomsOption: .yes,
			isLoading: {
				isLoadingValues.append($0)
				isLoadingExpectation.fulfill()
			},
			onSuccess: { onSuccessExpectation.fulfill() },
			onError: { _ in onErrorExpectation.fulfill() }
		)

		waitForExpectations(timeout: .short)
		XCTAssertEqual(isLoadingValues, expectedIsLoadingValues)

		XCTAssertTrue(model.shouldShowSymptomsOnsetScreen)
	}

	func testSymptomsOptionNoOrPreferNotToSaySelectedSupportedCountriesLoadSucceeds() {
		let symptomOptions: [ExposureSubmissionSymptomsViewController.SymptomsOption] = [.no, .preferNotToSay]
		for symptomOption in symptomOptions {
			let exposureSubmissionService = MockExposureSubmissionService()
			exposureSubmissionService.submitExposureCallback = { completion in
				completion(nil)
			}

			var sapApplicationConfiguration = SAP_ApplicationConfiguration()
			sapApplicationConfiguration.supportedCountries = ["DE", "IT", "ES"]
			let mockAppConfiguration = MockAppConfiguration(mockSAPApplicationConfiguration: sapApplicationConfiguration)

			let model = ExposureSubmissionCoordinatorModel(
				exposureSubmissionService: exposureSubmissionService,
				appConfigurationProvider: mockAppConfiguration
			)

			let expectedIsLoadingValues = [true, false]
			var isLoadingValues = [Bool]()

			let isLoadingExpectation = expectation(description: "isLoading is called twice")
			isLoadingExpectation.expectedFulfillmentCount = 2

			let onSuccessExpectation = expectation(description: "onSuccess is called")

			let onErrorExpectation = expectation(description: "onError is not called")
			onErrorExpectation.isInverted = true

			model.symptomsOptionSelected(
				selectedSymptomsOption: symptomOption,
				isLoading: {
					isLoadingValues.append($0)
					isLoadingExpectation.fulfill()
				},
				onSuccess: { onSuccessExpectation.fulfill() },
				onError: { _ in onErrorExpectation.fulfill() }
			)

			waitForExpectations(timeout: .short)
			XCTAssertEqual(isLoadingValues, expectedIsLoadingValues)

			XCTAssertFalse(model.shouldShowSymptomsOnsetScreen)
			XCTAssertEqual(model.supportedCountries, [Country(countryCode: "DE"), Country(countryCode: "IT"), Country(countryCode: "ES")])
		}
	}

	func testSymptomsOptionNoOrPreferNotToSaySelectedSupportedCountriesLoadEmpty() {
		let symptomOptions: [ExposureSubmissionSymptomsViewController.SymptomsOption] = [.no, .preferNotToSay]
		for symptomOption in symptomOptions {
			let exposureSubmissionService = MockExposureSubmissionService()
			exposureSubmissionService.submitExposureCallback = { completion in
				completion(nil)
			}

			var sapApplicationConfiguration = SAP_ApplicationConfiguration()
			sapApplicationConfiguration.supportedCountries = []
			let mockAppConfiguration = MockAppConfiguration(mockSAPApplicationConfiguration: sapApplicationConfiguration)

			let model = ExposureSubmissionCoordinatorModel(
				exposureSubmissionService: exposureSubmissionService,
				appConfigurationProvider: mockAppConfiguration
			)

			let expectedIsLoadingValues = [true, false]
			var isLoadingValues = [Bool]()

			let isLoadingExpectation = expectation(description: "isLoading is called twice")
			isLoadingExpectation.expectedFulfillmentCount = 2

			let onSuccessExpectation = expectation(description: "onSuccess is called")

			let onErrorExpectation = expectation(description: "onError is not called")
			onErrorExpectation.isInverted = true

			model.symptomsOptionSelected(
				selectedSymptomsOption: symptomOption,
				isLoading: {
					isLoadingValues.append($0)
					isLoadingExpectation.fulfill()
				},
				onSuccess: { onSuccessExpectation.fulfill() },
				onError: { _ in onErrorExpectation.fulfill() }
			)

			waitForExpectations(timeout: .short)
			XCTAssertEqual(isLoadingValues, expectedIsLoadingValues)

			XCTAssertFalse(model.shouldShowSymptomsOnsetScreen)
			XCTAssertEqual(model.supportedCountries, [Country(countryCode: "DE")])
		}
	}

	func testSymptomsOptionNoOrPreferNotToSaySelectedSupportedCountriesLoadFails() {
		let symptomOptions: [ExposureSubmissionSymptomsViewController.SymptomsOption] = [.no, .preferNotToSay]
		for symptomOption in symptomOptions {
			let exposureSubmissionService = MockExposureSubmissionService()
			exposureSubmissionService.submitExposureCallback = { completion in
				completion(nil)
			}

			let mockAppConfiguration = MockAppConfiguration(mockSAPApplicationConfiguration: nil)

			let model = ExposureSubmissionCoordinatorModel(
				exposureSubmissionService: exposureSubmissionService,
				appConfigurationProvider: mockAppConfiguration
			)

			let expectedIsLoadingValues = [true, false]
			var isLoadingValues = [Bool]()

			let isLoadingExpectation = expectation(description: "isLoading is called twice")
			isLoadingExpectation.expectedFulfillmentCount = 2

			let onSuccessExpectation = expectation(description: "onSuccess is not called")
			onSuccessExpectation.isInverted = true

			let onErrorExpectation = expectation(description: "onError is called")

			model.symptomsOptionSelected(
				selectedSymptomsOption: symptomOption,
				isLoading: {
					isLoadingValues.append($0)
					isLoadingExpectation.fulfill()
				},
				onSuccess: { onSuccessExpectation.fulfill() },
				onError: { _ in onErrorExpectation.fulfill() }
			)

			waitForExpectations(timeout: .short)
			XCTAssertEqual(isLoadingValues, expectedIsLoadingValues)

			XCTAssertFalse(model.shouldShowSymptomsOnsetScreen)
			XCTAssertEqual(model.supportedCountries, [])
		}
	}

	func testSymptomsOnsetOptionsSelectedSupportedCountriesLoadSucceeds() {
		let symptomsOnsetOptions: [ExposureSubmissionSymptomsOnsetViewController.SymptomsOnsetOption] = [.exactDate(Date()), .lastSevenDays, .oneToTwoWeeksAgo, .moreThanTwoWeeksAgo, .preferNotToSay]
		for symptomsOnsetOption in symptomsOnsetOptions {
			let exposureSubmissionService = MockExposureSubmissionService()
			exposureSubmissionService.submitExposureCallback = { completion in
				completion(nil)
			}

			var sapApplicationConfiguration = SAP_ApplicationConfiguration()
			sapApplicationConfiguration.supportedCountries = ["DE", "IT", "ES"]
			let mockAppConfiguration = MockAppConfiguration(mockSAPApplicationConfiguration: sapApplicationConfiguration)

			let model = ExposureSubmissionCoordinatorModel(
				exposureSubmissionService: exposureSubmissionService,
				appConfigurationProvider: mockAppConfiguration
			)

			let expectedIsLoadingValues = [true, false]
			var isLoadingValues = [Bool]()

			let isLoadingExpectation = expectation(description: "isLoading is called twice")
			isLoadingExpectation.expectedFulfillmentCount = 2

			let onSuccessExpectation = expectation(description: "onSuccess is called")

			let onErrorExpectation = expectation(description: "onError is not called")
			onErrorExpectation.isInverted = true

			model.symptomsOnsetOptionSelected(
				selectedSymptomsOnsetOption: symptomsOnsetOption,
				isLoading: {
					isLoadingValues.append($0)
					isLoadingExpectation.fulfill()
				},
				onSuccess: { onSuccessExpectation.fulfill() },
				onError: { _ in onErrorExpectation.fulfill() }
			)

			waitForExpectations(timeout: .short)
			XCTAssertEqual(isLoadingValues, expectedIsLoadingValues)

			XCTAssertFalse(model.shouldShowSymptomsOnsetScreen)
			XCTAssertEqual(model.supportedCountries, [Country(countryCode: "DE"), Country(countryCode: "IT"), Country(countryCode: "ES")])
		}
	}

	func testSymptomsOnsetOptionsSelectedSupportedCountriesLoadEmpty() {
		let symptomsOnsetOptions: [ExposureSubmissionSymptomsOnsetViewController.SymptomsOnsetOption] = [.exactDate(Date()), .lastSevenDays, .oneToTwoWeeksAgo, .moreThanTwoWeeksAgo, .preferNotToSay]
		for symptomsOnsetOption in symptomsOnsetOptions {
			let exposureSubmissionService = MockExposureSubmissionService()
			exposureSubmissionService.submitExposureCallback = { completion in
				completion(nil)
			}

			var sapApplicationConfiguration = SAP_ApplicationConfiguration()
			sapApplicationConfiguration.supportedCountries = []
			let mockAppConfiguration = MockAppConfiguration(mockSAPApplicationConfiguration: sapApplicationConfiguration)

			let model = ExposureSubmissionCoordinatorModel(
				exposureSubmissionService: exposureSubmissionService,
				appConfigurationProvider: mockAppConfiguration
			)

			let expectedIsLoadingValues = [true, false]
			var isLoadingValues = [Bool]()

			let isLoadingExpectation = expectation(description: "isLoading is called twice")
			isLoadingExpectation.expectedFulfillmentCount = 2

			let onSuccessExpectation = expectation(description: "onSuccess is called")

			let onErrorExpectation = expectation(description: "onError is not called")
			onErrorExpectation.isInverted = true

			model.symptomsOnsetOptionSelected(
				selectedSymptomsOnsetOption: symptomsOnsetOption,
				isLoading: {
					isLoadingValues.append($0)
					isLoadingExpectation.fulfill()
				},
				onSuccess: { onSuccessExpectation.fulfill() },
				onError: { _ in onErrorExpectation.fulfill() }
			)

			waitForExpectations(timeout: .short)
			XCTAssertEqual(isLoadingValues, expectedIsLoadingValues)

			XCTAssertFalse(model.shouldShowSymptomsOnsetScreen)
			XCTAssertEqual(model.supportedCountries, [Country(countryCode: "DE")])
		}
	}

	func testSymptomsOnsetOptionsSelectedSupportedCountriesLoadFails() {
		let symptomsOnsetOptions: [ExposureSubmissionSymptomsOnsetViewController.SymptomsOnsetOption] = [.exactDate(Date()), .lastSevenDays, .oneToTwoWeeksAgo, .moreThanTwoWeeksAgo, .preferNotToSay]
		for symptomsOnsetOption in symptomsOnsetOptions {
			let exposureSubmissionService = MockExposureSubmissionService()
			exposureSubmissionService.submitExposureCallback = { completion in
				completion(nil)
			}

			let mockAppConfiguration = MockAppConfiguration(mockSAPApplicationConfiguration: nil)

			let model = ExposureSubmissionCoordinatorModel(
				exposureSubmissionService: exposureSubmissionService,
				appConfigurationProvider: mockAppConfiguration
			)

			let expectedIsLoadingValues = [true, false]
			var isLoadingValues = [Bool]()

			let isLoadingExpectation = expectation(description: "isLoading is called twice")
			isLoadingExpectation.expectedFulfillmentCount = 2

			let onSuccessExpectation = expectation(description: "onSuccess is not called")
			onSuccessExpectation.isInverted = true

			let onErrorExpectation = expectation(description: "onError is called")

			model.symptomsOnsetOptionSelected(
				selectedSymptomsOnsetOption: symptomsOnsetOption,
				isLoading: {
					isLoadingValues.append($0)
					isLoadingExpectation.fulfill()
				},
				onSuccess: { onSuccessExpectation.fulfill() },
				onError: { _ in onErrorExpectation.fulfill() }
			)

			waitForExpectations(timeout: .short)
			XCTAssertEqual(isLoadingValues, expectedIsLoadingValues)

			XCTAssertFalse(model.shouldShowSymptomsOnsetScreen)
			XCTAssertEqual(model.supportedCountries, [])
		}
	}

	func testSuccessfulSubmit() {
		let exposureSubmissionService = MockExposureSubmissionService()
		exposureSubmissionService.submitExposureCallback = { completion in
			completion(nil)
		}

		let model = ExposureSubmissionCoordinatorModel(
			exposureSubmissionService: exposureSubmissionService,
			appConfigurationProvider: MockAppConfiguration(mockSAPApplicationConfiguration: nil)
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
		exposureSubmissionService.submitExposureCallback = { completion in
			completion(.noKeys)
		}

		let model = ExposureSubmissionCoordinatorModel(
			exposureSubmissionService: exposureSubmissionService,
			appConfigurationProvider: MockAppConfiguration(mockSAPApplicationConfiguration: nil)
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
		exposureSubmissionService.submitExposureCallback = { completion in
			completion(.notAuthorized)
		}

		let model = ExposureSubmissionCoordinatorModel(
			exposureSubmissionService: exposureSubmissionService,
			appConfigurationProvider: MockAppConfiguration(mockSAPApplicationConfiguration: nil)
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
		exposureSubmissionService.submitExposureCallback = { completion in
			completion(.internal)
		}

		let model = ExposureSubmissionCoordinatorModel(
			exposureSubmissionService: exposureSubmissionService,
			appConfigurationProvider: MockAppConfiguration(mockSAPApplicationConfiguration: nil)
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

}
