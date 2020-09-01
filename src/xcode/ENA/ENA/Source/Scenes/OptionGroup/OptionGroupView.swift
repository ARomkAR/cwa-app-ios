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

class OptionGroupView: UIView {

	// MARK: - Init

	@available(*, unavailable)
	override init(frame: CGRect) {
		fatalError("init(frame:) has not been implemented")
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	init(viewModel: OptionGroupViewModel) {
		self.viewModel = viewModel

		super.init(frame: .zero)

		setUp()
	}

	// MARK: - Private

	private let viewModel: OptionGroupViewModel

	private let contentStackView = UIStackView()
	private var optionViews: [OptionGroupViewModel.OptionViewType] = []

	private var selectionSubscription: AnyCancellable?

	private func setUp() {
		contentStackView.axis = .vertical
		contentStackView.spacing = 14

		contentStackView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(contentStackView)

		NSLayoutConstraint.activate([
			contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
			contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
			contentStackView.topAnchor.constraint(equalTo: topAnchor),
			contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
		])

		for optionIndex in 0..<viewModel.options.count {
			let option = viewModel.options[optionIndex]

			switch option {
			case .option(title: let title):
				let view = optionView(title: title, index: optionIndex)
				optionViews.append(.option(view))
				contentStackView.addArrangedSubview(view)
			case let .multipleChoiceOption(title: title, choices: choices):
				let view = multipleChoiceOptionView(title: title, choices: choices, index: optionIndex)
				optionViews.append(.multipleChoiceOption(view))
				contentStackView.addArrangedSubview(view)
			}
		}

		selectionSubscription = viewModel.$selection.sink { [weak self] selection in
			DispatchQueue.main.async {
				self?.updateOptionViews(for: selection)
			}
		}
	}

	private func optionView(title: String, index: Int) -> OptionView {
		return OptionView(
			title: title,
			onTap: { [weak self] in
				self?.viewModel.optionTapped(index: index)
			}
		)
	}

	private func multipleChoiceOptionView(title: String, choices: [(iconImage: UIImage?, title: String)], index: Int) -> MultipleChoiceOptionView {
		return MultipleChoiceOptionView(
			title: title,
			choices: choices,
			onTapOnChoice: { [weak self] choiceIndex in
				self?.viewModel.multiopleChoiceOptionTapped(index: index, choiceIndex: choiceIndex)
			}
		)
	}

	private func deselectAllViews() {
		for viewIndex in 0..<self.optionViews.count {
			switch optionViews[viewIndex] {
			case .option(let view):
				view.isSelected = false
			case .multipleChoiceOption(let view):
				view.selectedChoices = []
			}

		}
	}

	private func updateOptionViews(for selection: OptionGroupViewModel.Selection?) {
		deselectAllViews()

		if case let .option(index: index) = selection, case let .option(view) = optionViews[index] {
			view.isSelected = true
		}

		if case let .multipleChoiceOption(index: index, selectedChoices: selectedChoices) = selection, case let .multipleChoiceOption(view) = optionViews[index] {
			view.selectedChoices = selectedChoices
		}
	}

}
