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
import Connectivity

protocol CoordinatorDelegate: AnyObject {
	func coordinatorUserDidRequestReset()
}

final class Coordinator: RequiresAppDependencies {
	private weak var delegate: CoordinatorDelegate?

	private let rootViewController: UINavigationController

	private var homeController: HomeViewController?
	private var settingsController: SettingsViewController?

	private var enStateUpdatingSet = NSHashTable<AnyObject>.weakObjects()

	init(_ delegate: CoordinatorDelegate, _ rootViewController: UINavigationController) {
		self.delegate = delegate
		self.rootViewController = rootViewController
	}

	deinit {
		enStateUpdatingSet.removeAllObjects()
	}

	func showHome(_ enStateHandler: ENStateHandler, state: SceneDelegate.State) {
		let vc = AppStoryboard.home.initiate(viewControllerType: HomeViewController.self) { [unowned self] coder in
			HomeViewController(
				coder: coder,
				delegate: self,
				detectionMode: state.detectionMode,
				exposureManagerState: state.exposureManager,
				initialEnState: enStateHandler.state,
				risk: state.risk
			)
		}

		homeController = vc // strong ref needed

		UIView.transition(with: rootViewController.view, duration: CATransaction.animationDuration(), options: [.transitionCrossDissolve], animations: {
			self.rootViewController.setViewControllers([vc], animated: false)
		})

		#if !RELEASE
		enableDeveloperMenuIfAllowed(in: vc)
		#endif
	}

	func showOnboarding() {
		rootViewController.navigationBar.prefersLargeTitles = false
		rootViewController.setViewControllers(
			[
				AppStoryboard.onboarding.initiateInitial { [unowned self] coder in
					OnboardingInfoViewController(
						coder: coder,
						pageType: .togetherAgainstCoronaPage,
						exposureManager: self.exposureManager,
						store: self.store
					)
				}
			],
			animated: false
		)
	}

	func updateState(detectionMode: DetectionMode, exposureManagerState: ExposureManagerState, risk: Risk?) {
		homeController?.updateState(detectionMode: detectionMode, exposureManagerState: exposureManagerState, risk: risk)
	}

	#if !RELEASE
	private var developerMenu: DMDeveloperMenu?
	private func enableDeveloperMenuIfAllowed(in controller: UIViewController) {
		developerMenu = DMDeveloperMenu(
			presentingViewController: controller,
			client: client,
			store: store,
			exposureManager: exposureManager
		)
		developerMenu?.enableIfAllowed()
	}
	#endif

	private func setExposureManagerEnabled(_ enabled: Bool, then completion: @escaping (ExposureNotificationError?) -> Void) {
		if enabled {
			exposureManager.enable(completion: completion)
		} else {
			exposureManager.disable(completion: completion)
		}
	}
}

extension Coordinator: SettingsViewControllerDelegate {
	func settingsViewController(_ controller: SettingsViewController, setExposureManagerEnabled enabled: Bool, then completion: @escaping Completion) {
		setExposureManagerEnabled(enabled, then: completion)
	}

	func settingsViewControllerUserDidRequestReset(_ controller: SettingsViewController) {
		delegate?.coordinatorUserDidRequestReset()
	}
}

extension Coordinator: ExposureNotificationSettingViewControllerDelegate {
	func exposureNotificationSettingViewController(_ controller: ExposureNotificationSettingViewController, setExposureManagerEnabled enabled: Bool, then completion: @escaping Completion) {
		setExposureManagerEnabled(enabled, then: completion)
	}
}

extension Coordinator: HomeViewControllerDelegate {
	func showSettings(enState: ENStateHandler.State) {
		let storyboard = AppStoryboard.settings.instance
		let vc = storyboard.instantiateViewController(identifier: "SettingsViewController") { coder in
			SettingsViewController(
				coder: coder,
				store: self.store,
				initialEnState: enState,
				delegate: self
			)
		}
		addToUpdatingSetIfNeeded(vc)
		settingsController = vc
		rootViewController.pushViewController(vc, animated: true)
	}

	func showInviteFriends() {
		rootViewController.pushViewController(
			FriendsInviteController.initiate(for: .inviteFriends),
			animated: true
		)
	}

	func showExposureNotificationSetting(enState: ENStateHandler.State) {
		let storyboard = AppStoryboard.exposureNotificationSetting.instance
		let vc = storyboard.instantiateViewController(identifier: "ExposureNotificationSettingViewController") { coder in
			ExposureNotificationSettingViewController(
					coder: coder,
					initialEnState: enState,
					store: self.store,
					delegate: self
			)
		}
		addToUpdatingSetIfNeeded(vc)
		rootViewController.pushViewController(vc, animated: true)
	}

	func showAppInformation() {
		rootViewController.pushViewController(
			AppInformationViewController(),
			animated: true
		)
	}

	func showWebPage(from viewController: UIViewController) {
		WebPageHelper.showWebPage(from: viewController)
	}

	func addToUpdatingSetIfNeeded(_ anyObject: AnyObject?) {
		if let anyObject = anyObject,
		   anyObject is ENStateHandlerUpdating {
			enStateUpdatingSet.add(anyObject)
		}
	}
}

extension Coordinator: ExposureStateUpdating {
	func updateExposureState(_ state: ExposureManagerState) {
		homeController?.updateExposureState(state)
		settingsController?.updateExposureState(state)
		//exposureDetectionController?.updateUI()
	}
}

extension Coordinator: ENStateHandlerUpdating {
	func updateEnState(_ state: ENStateHandler.State) {
		homeController?.updateEnState(state)
		updateAllState(state)
	}

	private func updateAllState(_ state: ENStateHandler.State) {
		enStateUpdatingSet.allObjects.forEach { anyObject in
			if let updating = anyObject as? ENStateHandlerUpdating {
				updating.updateEnState(state)
			}
		}
	}
}
