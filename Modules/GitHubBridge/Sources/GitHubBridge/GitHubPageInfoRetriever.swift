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

import CoreData
import Foundation

import BMO
import BMOCoreData
import CollectionLoader



public class GitHubPageInfoRetriever : PageInfoRetrieverProtocol {
	
	public typealias CompletionResults = LocalDbChanges<NSManagedObject, GitHubBridge.Metadata>?
	
	public enum PageInfo : PageInfoProtocol {
		case initial
		case fixedURL(URL)
		var url: URL? {
			switch self {
				case .initial:           return nil
				case .fixedURL(let url): return url
			}
		}
	}
	
	public init() {
	}
	
	public func initialPageInfo() -> PageInfo {
		return .initial
	}
	
	public func nextPageInfo(for completionResults: CompletionResults, from pageInfo: PageInfo) -> PageInfo? {
		return completionResults?.metadata?.nextPageURL.flatMap{ .fixedURL($0) } ?? .none
	}
	
	public func previousPageInfo(for completionResults: CompletionResults, from pageInfo: PageInfo) -> PageInfo? {
		return completionResults?.metadata?.previousPageURL.flatMap{ .fixedURL($0) } ?? .none
	}
	
}
