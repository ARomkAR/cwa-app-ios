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

import Foundation
import XCTest
@testable import ENA

class ExposureSubmissionOverviewViewControllerTests: XCTestCase {

	override func setUp() {
		super.setUp()
	}

	func testQRCodeSanitization() {
		let vc = AppStoryboard.exposureSubmission.initiate(viewControllerType: ExposureSubmissionOverviewViewController.self)

		// Empty.
		var result = vc.sanitizeAndExtractGuid("")
		XCTAssertNil(result)

		// Input Length exceeded.
		result = vc.sanitizeAndExtractGuid(String(repeating: "x", count: 150))
		XCTAssertNil(result)

		// Missing ?.
		let guid = "61d4e0f7-a910-4b82-8b9b-39fdc76837a0"
		result = vc.sanitizeAndExtractGuid("https://abc.com/\(guid)")
		XCTAssertNil(result)

		// Additional space after ?
		result = vc.sanitizeAndExtractGuid("? \(guid)")
		XCTAssertNil(result)

		// GUID Length exceeded.
		result = vc.sanitizeAndExtractGuid("https://abc.com/\(guid)\(guid)")
		XCTAssertNil(result)

		// Success.
		result = vc.sanitizeAndExtractGuid("https://abc.com?\(guid)")
		XCTAssertEqual(result, guid)
		result = vc.sanitizeAndExtractGuid("?\(guid)")
		XCTAssertEqual(result, guid)
		result = vc.sanitizeAndExtractGuid(" ?\(guid)")
		XCTAssertEqual(result, guid)
		result = vc.sanitizeAndExtractGuid("some-string?\(guid)")
		XCTAssertEqual(result, guid)
		result = vc.sanitizeAndExtractGuid("https://abc.com?\(guid.uppercased())")
		XCTAssertEqual(result, guid.uppercased())
	}
}
