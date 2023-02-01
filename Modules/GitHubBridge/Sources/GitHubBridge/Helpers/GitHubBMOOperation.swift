/*
Copyright 2018 happn

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. */

import Foundation
import os.log

import Alamofire
import BMO
import GenericJSON
import RetryingOperation
import UnwrapOrThrow



public class GitHubBMOOperation : RetryingOperation {
	
	public static var gitHubToken: String? = {
		/* Let's read the token from a hard-coded file. */
		let desktopPath = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true).first!
		let re = try! NSRegularExpression(pattern: "/Users/([^/]*)/.*", options: [])
		let username = re.stringByReplacingMatches(in: desktopPath, options: [], range: NSRange(location: 0, length: (desktopPath as NSString).length), withTemplate: "$1")
		return (
			(try? String(contentsOf: URL(fileURLWithPath: "github_clients_token.txt",                            isDirectory: false, relativeTo: URL(fileURLWithPath: desktopPath, isDirectory: true)))) ??
			(try? String(contentsOf: URL(fileURLWithPath: "/Users/\(username)/Desktop/github_clients_token.txt", isDirectory: false)))
		)
	}()
	
	public static func retrieveUsernameFromToken(_ handler: @escaping (_ username: String?) -> Void) {
		guard gitHubToken != nil else {handler(nil); return}
		if let u = cachedUsernameFromToken {handler(u); return}
		
		let retrieveUsernameOperation = GitHubBMOOperation(request: URLRequest(url: URL(string: "user", relativeTo: Conf.apiRoot)!))
		retrieveUsernameOperation.completionBlock = {
			cachedUsernameFromToken = (try? retrieveUsernameOperation.results.get())?["login"]?.stringValue
			handler(cachedUsernameFromToken)
		}
		retrieveUsernameOperation.start()
	}
	
	public let request: URLRequest
	public var responseHeaders: [AnyHashable: Any]?
	public var results: Result<JSON, Error> = .failure(OperationLifecycleError.notStarted)
	
	public convenience init?(pathComponents: [String?], queryItems: [URLQueryItem] = [], pageInfo: GitHubPageInfoRetriever.PageInfo?) {
		struct NilComponent : Error {}
		guard let pathComponents = (try? pathComponents.map{ try $0 ?! NilComponent() }) else {
			return nil
		}
		
		/* Note: We should not join the path components like so (what happens if one contains a “/”?). */
		let expectedURL = URL(string: pathComponents.joined(separator: "/"), relativeTo: GitHubBridgeConfig.apiRoot)!
		let url = pageInfo?.url ?? expectedURL
		if expectedURL.pathComponents != url.pathComponents {
			/* If the expected URL and the page info URL do not match, we log an info message.
			 * In theory, something’s not right; in practice GitHub returns the canonical URL for paging and it can be different than the one we use. */
			if #available(iOS 14.0, *) {
				Logger().info("Expected path components \(expectedURL.pathComponents, privacy: .public) but got \(url.pathExtension, privacy: .public). This usually not a big deal and only means GitHub returned a canonical URL for the paging URLs which can be different than the URL computed by the bridge.")
			}
		}
		
		var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
		components.queryItems = (components.queryItems ?? []) + queryItems
		self.init(request: URLRequest(url: components.url!))
	}
	
	public init(request: URLRequest) {
		self.request = request
	}
	
	public override func startBaseOperation(isRetry: Bool) {
		print("Starting GitHub BMO Operation with URLRequest \(request)")
		
		var authenticatedRequest = request
		if let token = Self.gitHubToken {
//			print("   -> Authenticating request with token found in Desktop file")
			authenticatedRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
		}
		
		AF.request(authenticatedRequest).validate().responseDecodable{ (response: DataResponse<JSON, AFError>) in
//			print(response.result.value)
			self.responseHeaders = response.response?.allHeaderFields
			self.results = response.result.mapError{ $0 as Error }
			self.baseOperationEnded()
		}
	}
	
	public override var isAsynchronous: Bool {
		return true
	}
	
	private static var cachedUsernameFromToken: String?
	
}
