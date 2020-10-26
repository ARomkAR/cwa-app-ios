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

import UIKit
import Combine

class ExposureSubmissionTestResultViewModel {

	// MARK: - Init

	init(
		testResult: TestResult,
		exposureSubmissionService: ExposureSubmissionService,
		onContinueWithSymptomsFlowButtonTap: @escaping () -> Void,
		onContinueWithoutSymptomsFlowButtonTap: @escaping () -> Void,
		onTestDeleted: @escaping () -> Void
	) {
		self.testResult = testResult
		self.exposureSubmissionService = exposureSubmissionService
		self.onContinueWithSymptomsFlowButtonTap = onContinueWithSymptomsFlowButtonTap
		self.onContinueWithoutSymptomsFlowButtonTap = onContinueWithoutSymptomsFlowButtonTap
		self.onTestDeleted = onTestDeleted

		updateForCurrentTestResult()
	}

	// MARK: - Internal

	var testResult: TestResult {
		didSet {
			updateForCurrentTestResult()
		}
	}

	var isLoading: Bool = false {
		didSet {
			navigationFooterItem.isPrimaryButtonEnabled = !isLoading
			navigationFooterItem.isPrimaryButtonLoading = isLoading
		}
	}

	@Published var dynamicTableViewModel: DynamicTableViewModel = DynamicTableViewModel([])
	@Published var shouldShowDeletionConfirmationAlert: Bool = false
	@Published var error: Error?

	lazy var navigationFooterItem: ENANavigationFooterItem = {
		let item = ENANavigationFooterItem()

		item.title = AppStrings.ExposureSubmissionResult.title
		item.hidesBackButton = true
		item.largeTitleDisplayMode = .always

		return item
	}()

	func didTapPrimaryButton() {
		switch testResult {
		case .positive:
			onContinueWithSymptomsFlowButtonTap()
		case .negative, .invalid, .expired:
			shouldShowDeletionConfirmationAlert = true
		case .pending:
			refreshTest()
		}
	}

	func didTapSecondaryButton() {
		switch testResult {
		case .positive:
			onContinueWithoutSymptomsFlowButtonTap()
		case .pending:
			shouldShowDeletionConfirmationAlert = true
		default:
			break
		}
	}

	func refreshTest() {
		isLoading = true

		exposureSubmissionService.getTestResult { [weak self] result in
			self?.isLoading = false

			switch result {
			case let .failure(error):
				self?.error = error
			case let .success(testResult):
				self?.testResult = testResult
			}
		}
	}

	func deleteTest() {
		exposureSubmissionService.deleteTest()
		onTestDeleted()
	}

	// MARK: - Private

	private var exposureSubmissionService: ExposureSubmissionService

	private let onContinueWithSymptomsFlowButtonTap: () -> Void
	private let onContinueWithoutSymptomsFlowButtonTap: () -> Void
	private let onTestDeleted: () -> Void

	private var timeStamp: Int64? {
		exposureSubmissionService.devicePairingSuccessfulTimestamp
	}

	private func updateForCurrentTestResult() {
		self.dynamicTableViewModel = DynamicTableViewModel([currentTestResultSection])
		updateButtons()
	}

	private func updateButtons() {
		// Make sure to reset buttons to default state.
		navigationFooterItem.isPrimaryButtonLoading = false
		navigationFooterItem.isPrimaryButtonEnabled = true
		navigationFooterItem.isPrimaryButtonHidden = false

		navigationFooterItem.isSecondaryButtonLoading = false
		navigationFooterItem.isSecondaryButtonEnabled = false
		navigationFooterItem.isSecondaryButtonHidden = true
		navigationFooterItem.secondaryButtonHasBorder = false

		switch testResult {
		case .positive:
			navigationFooterItem.primaryButtonTitle = AppStrings.ExposureSubmissionResult.primaryButtonTitle
			navigationFooterItem.secondaryButtonTitle = AppStrings.ExposureSubmissionResult.secondaryButtonTitle
			navigationFooterItem.isSecondaryButtonEnabled = true
			navigationFooterItem.isSecondaryButtonHidden = false
			navigationFooterItem.secondaryButtonHasBorder = true
		case .negative, .invalid, .expired:
			navigationFooterItem.primaryButtonTitle = AppStrings.ExposureSubmissionResult.deleteButton
			navigationFooterItem.isSecondaryButtonHidden = true
		case .pending:
			navigationFooterItem.primaryButtonTitle = AppStrings.ExposureSubmissionResult.refreshButton
			navigationFooterItem.secondaryButtonTitle = AppStrings.ExposureSubmissionResult.deleteButton
			navigationFooterItem.isSecondaryButtonEnabled = true
			navigationFooterItem.isSecondaryButtonHidden = false
		}
	}

	private var currentTestResultSection: DynamicSection {
		switch testResult {
		case .positive:
			return positiveTestResultSection
		case .negative:
			return negativeTestResultSection
		case .invalid:
			return invalidTestResultSection
		case .pending:
			return pendingTestResultSection
		case .expired:
			return expiredTestResultSection
		}
	}

	private var positiveTestResultSection: DynamicSection {
		.section(
			header: .identifier(
				ExposureSubmissionTestResultViewController.HeaderReuseIdentifier.testResult,
				configure: { view, _ in
					(view as? ExposureSubmissionTestResultHeaderView)?.configure(testResult: .positive, timeStamp: self.timeStamp)
				}
			),
			separators: .none,
			cells: [
				.title2(text: AppStrings.ExposureSubmissionResult.procedure,
						accessibilityIdentifier: AccessibilityIdentifiers.ExposureSubmissionResult.procedure),

				ExposureSubmissionDynamicCell.stepCell(
					title: AppStrings.ExposureSubmissionResult.testAdded,
					description: AppStrings.ExposureSubmissionResult.testAddedDesc,
					icon: UIImage(named: "Icons_Grey_Check"),
					hairline: .iconAttached
				),

				ExposureSubmissionDynamicCell.stepCell(
					title: AppStrings.ExposureSubmissionResult.warnOthers,
					description: AppStrings.ExposureSubmissionResult.warnOthersDesc,
					icon: UIImage(named: "Icons_Grey_Warnen"),
					hairline: .none
				)
			]
		)
	}

	private var negativeTestResultSection: DynamicSection {
		.section(
			header: .identifier(
				ExposureSubmissionTestResultViewController.HeaderReuseIdentifier.testResult,
				configure: { view, _ in
					(view as? ExposureSubmissionTestResultHeaderView)?.configure(testResult: .negative, timeStamp: self.timeStamp)
				}
			),
			separators: .none,
			cells: [
				.title2(text: AppStrings.ExposureSubmissionResult.procedure,
						accessibilityIdentifier: AccessibilityIdentifiers.ExposureSubmissionResult.procedure),


				ExposureSubmissionDynamicCell.stepCell(
					title: AppStrings.ExposureSubmissionResult.testAdded,
					description: AppStrings.ExposureSubmissionResult.testAddedDesc,
					icon: UIImage(named: "Icons_Grey_Check"),
					hairline: .iconAttached
				),

				ExposureSubmissionDynamicCell.stepCell(
					title: AppStrings.ExposureSubmissionResult.testNegative,
					description: AppStrings.ExposureSubmissionResult.testNegativeDesc,
					icon: UIImage(named: "Icons_Grey_Error"),
					hairline: .topAttached
				),

				ExposureSubmissionDynamicCell.stepCell(
					title: AppStrings.ExposureSubmissionResult.testRemove,
					description: AppStrings.ExposureSubmissionResult.testRemoveDesc,
					icon: UIImage(named: "Icons_Grey_Entfernen"),
					hairline: .none
				),

				.title2(text: AppStrings.ExposureSubmissionResult.furtherInfos_Title,
						accessibilityIdentifier: AccessibilityIdentifiers.ExposureSubmissionResult.furtherInfos_Title),

				.bulletPoint(text: AppStrings.ExposureSubmissionResult.furtherInfos_ListItem1, spacing: .large),
				.bulletPoint(text: AppStrings.ExposureSubmissionResult.furtherInfos_ListItem2, spacing: .large),
				.bulletPoint(text: AppStrings.ExposureSubmissionResult.furtherInfos_ListItem3, spacing: .large),
				.bulletPoint(text: AppStrings.ExposureSubmissionResult.furtherInfos_TestAgain, spacing: .large)
			]
		)
	}

	private var invalidTestResultSection: DynamicSection {
		.section(
			header: .identifier(
				ExposureSubmissionTestResultViewController.HeaderReuseIdentifier.testResult,
				configure: { view, _ in
					(view as? ExposureSubmissionTestResultHeaderView)?.configure(testResult: .invalid, timeStamp: self.timeStamp)
				}
			),
			separators: .none,
			cells: [
				.title2(text: AppStrings.ExposureSubmissionResult.procedure,
						accessibilityIdentifier: AccessibilityIdentifiers.ExposureSubmissionResult.procedure),

				ExposureSubmissionDynamicCell.stepCell(
					title: AppStrings.ExposureSubmissionResult.testAdded,
					description: AppStrings.ExposureSubmissionResult.testAddedDesc,
					icon: UIImage(named: "Icons_Grey_Check"),
					hairline: .iconAttached
				),

				ExposureSubmissionDynamicCell.stepCell(
					title: AppStrings.ExposureSubmissionResult.testInvalid,
					description: AppStrings.ExposureSubmissionResult.testInvalidDesc,
					icon: UIImage(named: "Icons_Grey_Error"),
					hairline: .topAttached
				),

				ExposureSubmissionDynamicCell.stepCell(
					title: AppStrings.ExposureSubmissionResult.testRemove,
					description: AppStrings.ExposureSubmissionResult.testRemoveDesc,
					icon: UIImage(named: "Icons_Grey_Entfernen"),
					hairline: .none
				)
			]
		)
	}

	private var pendingTestResultSection: DynamicSection {
		.section(
			header: .identifier(
				ExposureSubmissionTestResultViewController.HeaderReuseIdentifier.testResult,
				configure: { view, _ in
					(view as? ExposureSubmissionTestResultHeaderView)?.configure(testResult: .pending, timeStamp: self.timeStamp)
				}
			),
			cells: [
				.title2(text: AppStrings.ExposureSubmissionResult.procedure,
						accessibilityIdentifier: AccessibilityIdentifiers.ExposureSubmissionResult.procedure),

				ExposureSubmissionDynamicCell.stepCell(
					title: AppStrings.ExposureSubmissionResult.testAdded,
					description: AppStrings.ExposureSubmissionResult.testAddedDesc,
					icon: UIImage(named: "Icons_Grey_Check"),
					hairline: .iconAttached
				),

				ExposureSubmissionDynamicCell.stepCell(
					title: AppStrings.ExposureSubmissionResult.testPending,
					description:
						AppStrings.ExposureSubmissionResult.testPendingDescParagraph1 +
						AppStrings.ExposureSubmissionResult.testPendingDescParagraph2 +
						AppStrings.ExposureSubmissionResult.testPendingDescParagraph3,
					icon: UIImage(named: "Icons_Grey_Wait"),
					hairline: .none
				)
			]
		)
	}

	private var expiredTestResultSection: DynamicSection {
		.section(
			header: .identifier(
				ExposureSubmissionTestResultViewController.HeaderReuseIdentifier.testResult,
				configure: { view, _ in
					(view as? ExposureSubmissionTestResultHeaderView)?.configure(testResult: .invalid, timeStamp: self.timeStamp)
				}
			),
			separators: .none,
			cells: [
				.title2(text: AppStrings.ExposureSubmissionResult.procedure,
						accessibilityIdentifier: AccessibilityIdentifiers.ExposureSubmissionResult.procedure),

				ExposureSubmissionDynamicCell.stepCell(
					title: AppStrings.ExposureSubmissionResult.testAdded,
					description: AppStrings.ExposureSubmissionResult.testAddedDesc,
					icon: UIImage(named: "Icons_Grey_Check"),
					hairline: .iconAttached
				),

				ExposureSubmissionDynamicCell.stepCell(
					title: AppStrings.ExposureSubmissionResult.testExpired,
					description: AppStrings.ExposureSubmissionResult.testExpiredDesc,
					icon: UIImage(named: "Icons_Grey_Error"),
					hairline: .topAttached
				),

				ExposureSubmissionDynamicCell.stepCell(
					title: AppStrings.ExposureSubmissionResult.testRemove,
					description: AppStrings.ExposureSubmissionResult.testRemoveDesc,
					icon: UIImage(named: "Icons_Grey_Entfernen"),
					hairline: .none
				)
			]
		)
	}

}
