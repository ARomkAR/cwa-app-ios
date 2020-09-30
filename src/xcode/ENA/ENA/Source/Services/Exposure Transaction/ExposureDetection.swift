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

import ExposureNotification
import Foundation

/// Every time the user wants to know the own risk the app creates an `ExposureDetection`.
final class ExposureDetection {

	// MARK: Properties
	@Published var activityState: RiskProvider.ActivityState = .idle
	private weak var delegate: ExposureDetectionDelegate?
	private var completion: Completion?
	private var progress: Progress?
	private var countryKeypackageDownloader: CountryKeypackageDownloading

	// MARK: Creating a Transaction
	init(
		delegate: ExposureDetectionDelegate,
		countryKeypackageDownloader: CountryKeypackageDownloading? = nil
	) {
		self.delegate = delegate

		if let countryKeypackageDownloader = countryKeypackageDownloader {
			self.countryKeypackageDownloader = countryKeypackageDownloader
		} else {
			self.countryKeypackageDownloader = CountryKeypackageDownloader(delegate: delegate)
		}
	}

	func cancel() {
		activityState = .idle
		progress?.cancel()
	}

	private func getSupportedCountries(completion: @escaping ([Country]) -> Void) {
		delegate?.exposureDetection(supportedCountries: { [weak self] result in
			guard let self = self else { return }

			switch result {
			case .success(let supportedCountries):
				var _supportedCountries = supportedCountries

				// If supported countries is empty for some reason, we add the default country (DE).
				if _supportedCountries.isEmpty {
					_supportedCountries.append(Country.defaultCountry())
				}

				completion(_supportedCountries)
			case.failure:
				self.endPrematurely(reason: .noSupportedCountries)
			}
		})
	}

	private func downloadKeyPackages(for countries: [Country.ID], completion: @escaping () -> Void) {

		let dispatchGroup = DispatchGroup()
		var errors = [ExposureDetection.DidEndPrematurelyReason]()

		for country in countries {
			dispatchGroup.enter()

			self.countryKeypackageDownloader.downloadKeypackages(for: country) { result in
				switch result {
				case .failure(let didEndPrematurelyReason):
					errors.append(didEndPrematurelyReason)
				case .success:
					break
				}

				dispatchGroup.leave()
			}
		}

		dispatchGroup.notify(queue: .main) {
			if let error = errors.first {
				self.endPrematurely(reason: error)
			} else {
				completion()
			}
		}
	}

	private func writeKeyPackagesToFileSystem(for countries: [Country.ID], completion: (WrittenPackages) -> Void) {
		var urls = [URL]()
		var writePackagesSuccess = true

		for country in countries {
			guard let writtenPackages = self.delegate?.exposureDetectionWriteDownloadedPackages(country: country) else {
				self.endPrematurely(reason: .unableToWriteDiagnosisKeys)
				writePackagesSuccess = false
				break
			}
			urls.append(contentsOf: writtenPackages.urls)
		}

		if writePackagesSuccess {
			completion(WrittenPackages(urls: urls))
		}
	}

	private func detectSummary(writtenPackages: WrittenPackages) {
		delegate?.exposureDetection(downloadConfiguration: { [weak self] configuration in
			guard let self = self else { return }

			guard let configuration = configuration else {
				self.endPrematurely(reason: .noExposureConfiguration)
				return
			}

			self.progress = self.delegate?.exposureDetection(
				self,
				detectSummaryWithConfiguration: configuration,
				writtenPackages: writtenPackages
			) { [weak self] result in
				writtenPackages.cleanUp()
				self?.useSummaryResult(result)
			}

		})
	}

	private func useSummaryResult(_ result: Result<ENExposureDetectionSummary, Error>) {
		switch result {
		case .success(let summary):
			didDetectSummary(summary)
		case .failure(let error):
			endPrematurely(reason: .noSummary(error))
		}
	}

	typealias Completion = (Result<ENExposureDetectionSummary, DidEndPrematurelyReason>) -> Void

	func start(completion: @escaping Completion) {
		self.completion = completion

		#if EUROPEMODE

		activityState = .downloading

		let countryIDs = ["EUR"]
		self.downloadKeyPackages(for: countryIDs) { [weak self] in
			guard let self = self else { return }

			self.writeKeyPackagesToFileSystem(for: countryIDs) {  [weak self] writtenPackages in
				guard let self = self else { return }

				self.activityState = .detecting
				self.detectSummary(writtenPackages: writtenPackages)
			}
		}

		#else

		activityState = .downloading

		self.getSupportedCountries { [weak self] supportedCountries in
			guard let self = self else { return }

			let countryIDs = Set(supportedCountries.map { $0.id })

			self.downloadKeyPackages(for: Array(countryIDs)) { [weak self] in
				guard let self = self else { return }

				self.writeKeyPackagesToFileSystem(for: Array(countryIDs)) {  [weak self] writtenPackages in
					guard let self = self else { return }

					self.activityState = .detecting
					self.detectSummary(writtenPackages: writtenPackages)
				}
			}
		}

		#endif
	}

	// MARK: Working with the Completion Handler

	// Ends the transaction prematurely with a given reason.
	private func endPrematurely(reason: DidEndPrematurelyReason) {
		precondition(
			completion != nil,
			"Tried to end a detection prematurely is only possible if a detection is currently running."
		)

		activityState = .idle

		DispatchQueue.main.async {
			self.completion?(.failure(reason))
			self.completion = nil
		}
	}

	// Informs the delegate about a summary.
	private func didDetectSummary(_ summary: ENExposureDetectionSummary) {
		precondition(
			completion != nil,
			"Tried report a summary but no completion handler is set."
		)

		activityState = .idle

		DispatchQueue.main.async {
			self.completion?(.success(summary))
			self.completion = nil
		}
	}
}
