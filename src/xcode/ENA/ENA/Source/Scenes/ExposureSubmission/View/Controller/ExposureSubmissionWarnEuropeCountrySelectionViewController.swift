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

import UIKit
import Combine

class ExposureSubmissionWarnEuropeCountrySelectionViewController: DynamicTableViewController, ENANavigationControllerWithFooterChild {

	enum CountrySelectionOption {
		case visitedCountries([Country])
		case preferNotToSay
	}

	// MARK: - Init

	init?(
		coder: NSCoder,
		onPrimaryButtonTap: @escaping (CountrySelectionOption, @escaping () -> Void) -> Void,
		availableCountries: [Country] = ["IT", "ES", "NL", "CZ", "AT", "DK", "IE", "LV", "EE"].compactMap { Country(countryCode: $0) }
	) {
		self.onPrimaryButtonTap = onPrimaryButtonTap
		self.availableCountries = availableCountries.sorted { $0.localizedName.localizedCompare($1.localizedName) == .orderedAscending }

		super.init(coder: coder)
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - Overrides

	override func viewDidLoad() {
		super.viewDidLoad()

		setupView()
	}

	// MARK: - Protocol ENANavigationControllerWithFooterChild

	func navigationController(_ navigationController: ENANavigationControllerWithFooter, didTapPrimaryButton button: UIButton) {
		guard let selectedCountrySelectionOption = selectedCountrySelectionOption else {
			fatalError("Primary button must not be enabled before the user has selected an option")
		}

		navigationFooterItem?.isPrimaryButtonLoading = true
		navigationFooterItem?.isPrimaryButtonEnabled = false

		onPrimaryButtonTap(selectedCountrySelectionOption) { [weak self] in
		   self?.navigationFooterItem?.isPrimaryButtonLoading = false
		   self?.navigationFooterItem?.isPrimaryButtonEnabled = true
		}
	}

	// MARK: - Internal

	private let onPrimaryButtonTap: (CountrySelectionOption, @escaping () -> Void) -> Void

	// MARK: - Private

	private let availableCountries: [Country]

	@Published private var selectedCountrySelectionOption: CountrySelectionOption?

	private var optionGroupSelection: OptionGroupViewModel.Selection? {
		didSet {
			switch optionGroupSelection {
			case .multipleChoiceOption(index: 0, selectedChoices: let selectedCountryIndices):
				// Filtering out "Other countries" option
				let filteredCountryIndices = selectedCountryIndices.filter { $0 != availableCountries.count }
				selectedCountrySelectionOption = .visitedCountries(filteredCountryIndices.map { availableCountries[$0] })
			case .option(index: 1):
				selectedCountrySelectionOption = .preferNotToSay
			case .none:
				selectedCountrySelectionOption = nil
			default:
				fatalError("This selection has not yet been handled.")
			}
		}
	}

	private var countrySelectionButtonStateSubscription: AnyCancellable?
	private var optionGroupSelectionSubscription: AnyCancellable?

	private func setupView() {
		navigationItem.title = AppStrings.ExposureSubmissionWarnEuropeCountrySelection.title
		navigationFooterItem?.primaryButtonTitle = AppStrings.ExposureSubmissionWarnEuropeCountrySelection.continueButton

		setupTableView()

		countrySelectionButtonStateSubscription = $selectedCountrySelectionOption.receive(on: RunLoop.main).sink {
			self.navigationFooterItem?.isPrimaryButtonEnabled = $0 != nil
		}
	}

	private func setupTableView() {
		tableView.delegate = self
		tableView.dataSource = self

		tableView.register(
			DynamicTableViewOptionGroupCell.self,
			forCellReuseIdentifier: CustomCellReuseIdentifiers.optionGroupCell.rawValue
		)

		dynamicTableViewModel = dynamicTableViewModel()
	}

	private func dynamicTableViewModel() -> DynamicTableViewModel {
		DynamicTableViewModel.with {
			$0.add(
				.section(
					header: .none,
					cells: [
						.headline(
							text: AppStrings.ExposureSubmissionWarnEuropeCountrySelection.description1,
							accessibilityIdentifier: AccessibilityIdentifiers.ExposureSubmissionWarnEuropeCountrySelection.description1
						),
						.custom(
							withIdentifier: CustomCellReuseIdentifiers.optionGroupCell,
							configure: { [weak self] _, cell, _ in
								guard let self = self, let cell = cell as? DynamicTableViewOptionGroupCell else { return }

								cell.configure(
									options: [
										.multipleChoiceOption(
											title: AppStrings.ExposureSubmissionWarnEuropeCountrySelection.answerOptionCountrySelection,
											choices: self.availableCountries.map { (iconImage: $0.flag, title: $0.localizedName) }
												+ [(iconImage: nil, title: AppStrings.ExposureSubmissionWarnEuropeCountrySelection.answerOptionOtherCountries)]
										),
										.option(
											title: AppStrings.ExposureSubmissionWarnEuropeCountrySelection.answerOptionNone
										)
									],
									// The current selection needs to be provided in case the cell is recreated after leaving and reentering the screen
									initialSelection: self.optionGroupSelection
								)

								self.optionGroupSelectionSubscription = cell.$selection.sink {
									self.optionGroupSelection = $0
								}
							}
						),
						.body(
							text: AppStrings.ExposureSubmissionWarnEuropeCountrySelection.description2,
							accessibilityIdentifier: AccessibilityIdentifiers.ExposureSubmissionWarnEuropeCountrySelection.description2
						)
					]
				)
			)
		}
	}

}

// MARK: - Cell reuse identifiers.

extension ExposureSubmissionWarnEuropeCountrySelectionViewController {
	enum CustomCellReuseIdentifiers: String, TableViewCellReuseIdentifiers {
		case optionGroupCell
	}
}
