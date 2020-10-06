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

#if !RELEASE

import UIKit

final class DMNoDiskSpaceViewController: UIViewController, UITextFieldDelegate {
	
	// MARK: Properties

	private let store: Store
	private var textField: UITextField!
	private var currentErrorCodeLabel: UILabel!

	init(store: Store) {
		self.store = store
		super.init(nibName: nil, bundle: nil)
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

    override func viewDidLoad() {
        super.viewDidLoad()

		view.backgroundColor = .systemBackground

		currentErrorCodeLabel = UILabel(frame: .zero)
		currentErrorCodeLabel.translatesAutoresizingMaskIntoConstraints = false
		updateCurrentErrorCodeLabel()

		let button = UIButton(frame: .zero)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setTitle("Save SQLite Error Code", for: .normal)
		button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
		button.setTitleColor(.enaColor(for: .buttonPrimary), for: .normal)

		textField = UITextField(frame: .zero)
		textField.translatesAutoresizingMaskIntoConstraints = false
		textField.delegate = self
		textField.borderStyle = .bezel

		let stackView = UIStackView(arrangedSubviews: [currentErrorCodeLabel, textField, button])
		stackView.translatesAutoresizingMaskIntoConstraints = false
		stackView.axis = .vertical
		stackView.spacing = 20

		view.addSubview(stackView)
		NSLayoutConstraint.activate([
			stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
		])

	}

	// MARK: - Private API

	private func updateCurrentErrorCodeLabel() {
		if let errorCode = store.fakeSQLiteError {
			currentErrorCodeLabel.text = "Current configured error code: \(errorCode)"
		} else {
			currentErrorCodeLabel.text = "No error code configured."
		}
	}

	@objc
	private func buttonTapped() {
		guard let errorCode = Int32(textField.text ?? "") else {
			let alert = UIAlertController(title: "Error", message: "No error code provided. Please enter error code.", preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "Ok", style: .cancel))
			present(alert, animated: true)
			return
		}

		store.fakeSQLiteError = errorCode
		updateCurrentErrorCodeLabel()

		let alert = UIAlertController(title: "Setup done", message: "Setup done for error code: \(errorCode)", preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "Ok", style: .cancel))
		present(alert, animated: true)
	}

}
#endif