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

class BackgroundAppRefreshViewController: UIViewController {

	// MARK: - Overrides
	
	override func viewDidLoad() {
		setupView()
		setupBindings()
	}
	
	// MARK: - Private

	private let viewModel = BackgroundAppRefreshViewModel(onOpenSettings: {}, onOpenAppSettings: {})
    private var subscriptions = Set<AnyCancellable>()
	private let infoBox = InfoBoxView()
	
	@IBOutlet private weak var subTitleLabel: ENALabel!
	@IBOutlet private weak var descriptionLabel: ENALabel!
	@IBOutlet private weak var settingsHeaderLabel: ENALabel!
	@IBOutlet private weak var backgroundAppRefreshTitleLabel: ENALabel!
	@IBOutlet private weak var backgroundAppRefreshStatusLabel: ENALabel!
	@IBOutlet private weak var imageView: UIImageView!
	@IBOutlet private weak var contentStackView: UIStackView!
	
	private func setupView() {
		title = viewModel.title
		subTitleLabel.text = viewModel.subTitle
		descriptionLabel.text = viewModel.description
		settingsHeaderLabel.text = viewModel.settingsHeader
		backgroundAppRefreshTitleLabel.text = viewModel.backgroundAppRefreshTitle
	}
	
	private func setupBindings() {
		subscriptions = [
			viewModel.$backgroundAppRefreshStatusText.sink { [weak self] in
				self?.backgroundAppRefreshStatusLabel.text = $0
			},
			viewModel.$image.sink { [weak self] in
					self?.imageView.image = $0
			},
			viewModel.$infoBoxViewModel.sink { [weak self] in
				self?.updateInfoxBox(with: $0)
			}
		]
		
	}
	
	private func updateInfoxBox(with viewModel: InfoBoxViewModel?) {
		if let viewModel = viewModel {
			if !contentStackView.arrangedSubviews.contains(infoBox) { contentStackView.addArrangedSubview(infoBox) }
			infoBox.update(with: viewModel)
		} else {
			infoBox.removeFromSuperview()

		}
	}

}
