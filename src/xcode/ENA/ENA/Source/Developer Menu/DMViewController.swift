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

#if !RELEASE

import ExposureNotification
import UIKit

enum DMMenuItem: Int, CaseIterable {
	case keys = 0
	case checkSubmittedKeys
	case backendConfiguration
	case lastSubmissionRequest
	case lastRiskCalculation
	case settings
	case manuallyRequestRisk
	case errorLog
	case purgeRegistrationToken
	case sendFakeRequest
}

extension DMMenuItem {
	init?(indexPath: IndexPath) {
		self.init(rawValue: indexPath.row)
	}

	static func existingFromIndexPath(_ indexPath: IndexPath) -> DMMenuItem {
		guard let item = self.init(indexPath: indexPath) else {
			fatalError("Requested a menu item for an invalid index path. This is a programmer error.")
		}
		return item
	}

	var title: String {
		switch self {
		case .keys: return "Keys"
		case .checkSubmittedKeys: return "Check submitted Keys"
		case .backendConfiguration: return "Backend Configuration"
		case .lastSubmissionRequest: return "Last Submission Request"
		case .lastRiskCalculation: return "Last Risk Calculation"
		case .settings: return "Developer Settings"
		case .manuallyRequestRisk: return "Manually Request Risk"
		case .errorLog: return "Error Log"
		case .purgeRegistrationToken: return "Purge Registration Token"
		case .sendFakeRequest: return "Send fake Request"
		}
	}
	var subtitle: String {
		switch self {
		case .keys: return "View local Keys & generate test Keys"
		case .checkSubmittedKeys: return "Check the state of your local keys"
		case .backendConfiguration: return "See the current backend configuration"
		case .lastSubmissionRequest: return "Export the last executed submission request"
		case .lastRiskCalculation: return "View and export the last executed risk calculation"
		case .settings: return "Adjust the Developer Settings (e.g: hourly mode)"
		case .manuallyRequestRisk: return "Manually requests the current risk"
		case .errorLog: return "View all errors logged by the app"
		case .purgeRegistrationToken: return "Purge Registration Token"
		case .sendFakeRequest: return "Sends a fake request for testing plausible deniability"
		}
	}
}

/// The root view controller of the developer menu.
final class DMViewController: UITableViewController, RequiresAppDependencies {
	// MARK: Creating a developer menu view controller

	init(
		client: Client,
		store: Store,
		exposureManager: ExposureManager
	) {
		self.client = client
		super.init(style: .plain)
		title = "👩🏾‍💻 Developer Menu 🧑‍💻"
	}

	@available(*, unavailable)
	required init?(coder _: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: Properties

	private let client: Client
	private let consumer = RiskConsumer()

	// MARK: UIViewController

	override func viewDidLoad() {
		super.viewDidLoad()
		consumer.didCalculateRisk = { risk in
			print("new risk: \(risk)")
		}
	}

	// MARK: Clear Registration Token of Submission
	@objc
	private func clearRegToken() {
		store.registrationToken = nil
		let alert = UIAlertController(
			title: "Token Deleted",
			message: "Successfully deleted the submission registration token.",
			preferredStyle: .alert
		)
		alert.addAction(
			UIAlertAction(
				title: AppStrings.Common.alertActionOk,
				style: .cancel
			)
		)
		present(alert, animated: true, completion: nil)
	}

	// MARK: UITableView

	override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
		DMMenuItem.allCases.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "DMMenuCell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "DMMenuCell")

		let menuItem = DMMenuItem.existingFromIndexPath(indexPath)

		cell.textLabel?.text = menuItem.title
		cell.detailTextLabel?.text = menuItem.subtitle
		cell.accessoryType = .disclosureIndicator

		return cell
	}

	override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
		let menuItem = DMMenuItem.existingFromIndexPath(indexPath)
		let vc: UIViewController?

		switch menuItem {
		case .keys:
			vc = DMKeysViewController(
				client: client,
				store: store,
				exposureManager: exposureManager
			)
		case .checkSubmittedKeys:
			vc = DMSubmissionStateViewController(
				client: client,
				delegate: self
			)
		case .backendConfiguration:
			guard let client = client as? HTTPClient else {
				logError(message: "the developer menu only supports apps using a real http client")
				return
			}
			vc = DMConfigurationViewController(
				distributionURL: client.configuration.endpoints.distribution.baseURL.absoluteString,
				submissionURL: client.configuration.endpoints.submission.baseURL.absoluteString,
				verificationURL: client.configuration.endpoints.verification.baseURL.absoluteString
			)
		case .lastSubmissionRequest:
			vc = DMLastSubmissionRequestViewController(lastSubmissionRequest: UserDefaults.standard.dmLastSubmissionRequest)
		case .lastRiskCalculation:
			let appDelegate = UIApplication.shared.delegate as? AppDelegate
			vc = DMLastRiskCalculationViewController(lastRisk: appDelegate?.lastRiskCalculation)
		case .settings:
			vc = DMSettingsViewController(store: store)
		case .errorLog:
			vc = DMErrorsViewController()
		case .sendFakeRequest:
			vc = nil
		case .purgeRegistrationToken:
			clearRegToken()
			vc = nil
		case .manuallyRequestRisk:
			vc = nil
			let alert = UIAlertController(title: "Manually request risk?", message: "⚠️⚠️⚠️ WARNING ⚠️⚠️⚠️\n\nManually requesting the current risk works by purging the cache. This actually deletes the last calculated risk (among other things) from the store. Do you want to manually request your current risk?", preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
				alert.dismiss(animated: true, completion: nil)
			}))
			alert.addAction(UIAlertAction(title: "Purge Cache and request Risk", style: .destructive, handler: { _ in
				print("do it ")
				self.store.summary = nil
				self.riskProvider.requestRisk(userInitiated: true)

			}))
			present(alert, animated: true, completion: nil)
		}
		if let vc = vc {
			navigationController?.pushViewController(
				vc,
				animated: true
			)
		}

	}
}

extension DMViewController: DMSubmissionStateViewControllerDelegate {
	func submissionStateViewController(
		_: DMSubmissionStateViewController,
		getDiagnosisKeys completionHandler: @escaping ENGetDiagnosisKeysHandler
	) {
		exposureManager.getTestDiagnosisKeys(completionHandler: completionHandler)
	}
}

#endif
