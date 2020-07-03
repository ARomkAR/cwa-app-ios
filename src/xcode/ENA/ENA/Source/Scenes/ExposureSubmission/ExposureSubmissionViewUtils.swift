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

import Foundation
import UIKit

enum ExposureSubmissionViewUtils {

	static func setupErrorAlert(title: String? = nil, message: String, okTitle: String? = nil, retryTitle: String? = nil, retry: Bool = false, completion: (() -> Void)? = nil, retryActionHandler: (() -> Void)? = nil) -> UIAlertController {
		let alert = UIAlertController(
			title: title ?? AppStrings.ExposureSubmission.generalErrorTitle,
			message: message,
			preferredStyle: .alert
		)
		let ok = UIAlertAction(
			title: okTitle ?? AppStrings.Common.alertActionOk,
			style: .cancel,
			handler: { _ in
				alert.dismiss(animated: true, completion: completion)
			}
		)

		alert.addAction(ok)
		if retry {
			let retryAction = UIAlertAction(
				title: retryTitle ?? AppStrings.Common.alertActionRetry,
				style: .default,
				handler: { _ in
					alert.dismiss(animated: true, completion: retryActionHandler)

				}
			)
			alert.addAction(retryAction)
		}
		return alert
	}
}
