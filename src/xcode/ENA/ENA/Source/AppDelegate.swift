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

import Combine
import ExposureNotification
import FMDB
import UIKit

protocol CoronaWarnAppDelegate: AnyObject {
	var client: HTTPClient { get }
	var downloadedPackagesStore: DownloadedPackagesStore { get }
	var store: Store & AppConfigCaching { get }
	var appConfigurationProvider: AppConfigurationProviding { get }
	var riskProvider: RiskProvider { get }
	var exposureManager: ExposureManager { get }
	var taskScheduler: ENATaskScheduler { get }
	var lastRiskCalculation: String { get set } // TODO: REMOVE ME
	var serverEnvironment: ServerEnvironment { get }
}

extension AppDelegate: CoronaWarnAppDelegate {
	// required - otherwise app will crash because cast will fail.
}

extension AppDelegate: ExposureSummaryProvider {
	func detectExposure(
		activityStateDelegate: ActivityStateProviderDelegate? = nil,
		completion: @escaping (ENExposureDetectionSummary?) -> Void
	) -> CancellationToken {

		exposureDetection = ExposureDetection(
			delegate: exposureDetectionExecutor,
			appConfigurationProvider: appConfigurationProvider
		)
		
		exposureDetection?
			.$activityState
			.removeDuplicates()
			.subscribe(on: RunLoop.main)
			.sink { activityStateDelegate?.provideActivityState($0) }
			.store(in: &subscriptions)

		let token = CancellationToken { [weak self] in
			self?.exposureDetection?.cancel()
		}
		exposureDetection?.start { [weak self] result in
			switch result {
			case .success(let summary):
				completion(summary)
			case .failure(let error):
				self?.showError(exposure: error)
				completion(nil)
			}
			self?.exposureDetection = nil
		}
		return token
	}

	private func showError(exposure didEndPrematurely: ExposureDetection.DidEndPrematurelyReason) {

		guard
			let scene = UIApplication.shared.connectedScenes.first,
			let delegate = scene.delegate as? SceneDelegate,
			let rootController = delegate.window?.rootViewController,
			let alert = didEndPrematurely.errorAlertController(rootController: rootController)
		else {
			return
		}

		func _showError() {
			rootController.present(alert, animated: true, completion: nil)
		}

		if rootController.presentedViewController != nil {
			rootController.dismiss(
				animated: true,
				completion: _showError
			)
		} else {
			rootController.present(alert, animated: true, completion: nil)
		}
	}
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	let store: Store & AppConfigCaching
	let serverEnvironment: ServerEnvironment
	
	private let consumer = RiskConsumer()
	let taskScheduler: ENATaskScheduler = ENATaskScheduler.shared

	lazy var appConfigurationProvider: AppConfigurationProviding = {
		// use a custom http client that uses/recognized caching mechanisms
		let appFetchingClient = CachingHTTPClient(clientConfiguration: client.configuration)

		return CachedAppConfiguration(client: appFetchingClient, store: store)
	}()

	lazy var riskProvider: RiskProvider = {
		let exposureDetectionInterval = self.store.hourlyFetchingEnabled ? DateComponents(minute: 45) : DateComponents(hour: 24)

		let config = RiskProvidingConfiguration(
			exposureDetectionValidityDuration: DateComponents(day: 2),
			exposureDetectionInterval: exposureDetectionInterval,
			detectionMode: .default
		)

		return RiskProvider(
			configuration: config,
			store: self.store,
			exposureSummaryProvider: self,
			appConfigurationProvider: appConfigurationProvider,
			exposureManagerState: self.exposureManager.preconditions()
		)
	}()

	#if targetEnvironment(simulator) || COMMUNITY
	// Enable third party contributors that do not have the required
	// entitlements to also use the app
	let exposureManager: ExposureManager = {
		let keys = [ENTemporaryExposureKey()]
		return MockExposureManager(exposureNotificationError: nil, diagnosisKeysResult: (keys, nil))
	}()
	#else
	let exposureManager: ExposureManager = ENAExposureManager()
	#endif

	private var exposureDetection: ExposureDetection?
	private var subscriptions = Set<AnyCancellable>()

	let downloadedPackagesStore: DownloadedPackagesStore = DownloadedPackagesSQLLiteStore(fileName: "packages")

	let client: HTTPClient

	// TODO: REMOVE ME
	var lastRiskCalculation: String = ""

	private lazy var exposureDetectionExecutor: ExposureDetectionExecutor = {
		ExposureDetectionExecutor(
			client: self.client,
			downloadedPackagesStore: self.downloadedPackagesStore,
			store: self.store,
			exposureDetector: self.exposureManager
		)
	}()

	override init() {
		self.serverEnvironment = ServerEnvironment()

		self.store = SecureStore(subDirectory: "database", serverEnvironment: serverEnvironment)

		let configuration = HTTPClient.Configuration.makeDefaultConfiguration(store: store)
		self.client = HTTPClient(configuration: configuration)

		#if !RELEASE
		downloadedPackagesStore.keyValueStore = self.store
		#endif
	}

	func application(
		_: UIApplication,
		didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
	) -> Bool {
		UIDevice.current.isBatteryMonitoringEnabled = true

		taskScheduler.delegate = self

		riskProvider.observeRisk(consumer)
		
		// Setup DeadmanNotification after AppLaunch
		UNUserNotificationCenter.current().scheduleDeadmanNotificationIfNeeded()

		return true
	}

	// MARK: UISceneSession Lifecycle

	func application(
		_: UIApplication,
		configurationForConnecting connectingSceneSession: UISceneSession,
		options _: UIScene.ConnectionOptions
	) -> UISceneConfiguration {
		UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
	}

	func application(_: UIApplication, didDiscardSceneSessions _: Set<UISceneSession>) {}
}
