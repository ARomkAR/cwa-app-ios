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

extension URLSession {
	typealias Completion = Response.Completion

	// This method executes HTTP GET requests.
	func GET(_ url: URL, extraHeaders: [String: String]? = nil, completion: @escaping Completion) {
		response(for: URLRequest(url: url), isFake: false, extraHeaders: extraHeaders, completion: completion)
	}

	// This method executes HTTP POST requests.
	func POST(_ url: URL, extraHeaders: [String: String]? = nil, completion: @escaping Completion) {
		var request = URLRequest(url: url)
		request.httpMethod = "POST"

		response(for: request, isFake: false, extraHeaders: extraHeaders, completion: completion)
	}

	// This method executes HTTP POST with HTTP BODY requests.
	func POST(_ url: URL, _ body: Data, extraHeaders: [String: String]? = nil, completion: @escaping Completion) {
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.httpBody = body
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		response(for: request, isFake: false, extraHeaders: extraHeaders, completion: completion)
	}

	// This method executes HTTP requests.
	// It does some additional checks - purely for convenience:
	// - if there is an error it aborts
	// - if there is either no HTTP body and/or HTTPURLResponse it aborts
	// Note that, if we send out a fake request, we omit
	// the response and give back a fakeResponse failure.
	func response(
		for request: URLRequest,
		isFake: Bool = false,
		extraHeaders: [String: String]? = nil,
		completion: @escaping Completion
	) {
		// modify request - if needed
		var request = request
		extraHeaders?.forEach {
			request.addValue($1, forHTTPHeaderField: $0)
		}

		dataTask(with: request) { data, response, error in
			guard !isFake else {
				completion(.failure(.fakeResponse))
				return
			}

			if let error = error {
				completion(.failure(.httpError(error)))
				return
			}
			guard
				let data = data,
				let response = response as? HTTPURLResponse
			else {
				completion(.failure(.noResponse))
				return
			}
			completion(
				.success(
					.init(body: data, statusCode: response.statusCode, httpResponse: response)
				)
			)
		}
		.resume()
	}
}

extension URLSession {
	/// Represents a response produced by the convenience extensions on `URLSession`.
	struct Response {
		// MARK: Properties

		let body: Data?
		let statusCode: Int
		let httpResponse: HTTPURLResponse

		// MARK: Working with a Response

		var hasAcceptableStatusCode: Bool {
			type(of: self).acceptableStatusCodes.contains(statusCode)
		}

		private static let acceptableStatusCodes = (200 ... 299)
	}
}

extension URLSession.Response {
	/// Raised when `URLSession` was unable to get an actual response.
	enum Failure: Error {
		/// The session received an `Error`. In that case the body and response is discarded.
		case httpError(Error)
		/// The session did not receive an error but nor either an `HTTPURLResponse`/HTTP body.
		case noResponse
		case teleTanAlreadyUsed
		case qRAlreadyUsed
		case qRNotExist
		case regTokenNotExist
		case invalidResponse
		case serverError(Int)
		case fakeResponse
	}

	typealias Completion = (Result<URLSession.Response, Failure>) -> Void
}
