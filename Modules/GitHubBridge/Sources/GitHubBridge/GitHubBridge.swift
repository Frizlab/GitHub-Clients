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
import LinkHeaderParser



public struct GitHubBridge : BridgeProtocol {
	
	public typealias LocalDb = GitHubLocalDb
	public typealias RemoteDb = GitHubRemoteDb
	
	public typealias BridgeObjects = GitHubBridgeObjects
	
	public typealias LocalDbImporter = BMOCoreDataImporter<LocalDb, Metadata>
	
	public struct RequestUserInfo {
		public var pageInfo: GitHubPageInfoRetriever.PageInfo?
		public init(pageInfo: GitHubPageInfoRetriever.PageInfo? = nil) {
			self.pageInfo = pageInfo
		}
	}
	
	public struct Metadata {
		public var previousPageURL: URL?
		public var nextPageURL: URL?
	}
	
	public struct UserInfo {
		var requestEntity: NSEntityDescription
		var bridgeObjectsUserInfo: GitHubBridgeObjects.UserInfo?
	}
	
	public static var coreDataModel: NSManagedObjectModel {
		NSManagedObjectModel(contentsOf: Bundle.module.url(forResource: "GitHub", withExtension: "momd")!)!
	}
	
	public init() {
	}
	
	public func requestHelper(for request: Request<LocalDb, RequestUserInfo>) -> any RequestHelperProtocol<NSManagedObjectContext, NSManagedObject, Metadata> {
		switch request.localRequest {
			case let .fetch(fetchRequest):                                return BMOCoreDataFetchRequestHelper(request: fetchRequest, fetchType: .always)
			case let .create(_, w), let .update(_, w), let .delete(_, w): return BMOCoreDataSaveRequestHelper(saveWorkflow: w)
		}
	}
	
	public func onContext_remoteOperation(for bmoRequest: Request<LocalDb, RequestUserInfo>) throws -> (GitHubBMOOperation, UserInfo)? {
		switch bmoRequest.localRequest {
			case let .fetch(request):
				guard let entity = request.safeEntity(using: Self.coreDataModel) else {
					struct NoEntityInRequest : Error {}
					throw NoEntityInRequest()
				}
				return try ((NSClassFromString(entity.managedObjectClassName) as? GitHubBridgeObject.Type)?
					.onContext_operation(for: request, userInfo: bmoRequest.remoteUserInfo))
					.flatMap{ ($0.0, UserInfo(requestEntity: entity, bridgeObjectsUserInfo: $0.1)) }
				
			case let .create(object, _): return try ((object as? GitHubBridgeObject)?.onContext_operationForCreation(userInfo: bmoRequest.remoteUserInfo)).flatMap{ ($0, UserInfo(requestEntity: object.entity)) }
			case let .update(object, _): return try ((object as? GitHubBridgeObject)?.onContext_operationForUpdate(  userInfo: bmoRequest.remoteUserInfo)).flatMap{ ($0, UserInfo(requestEntity: object.entity)) }
			case let .delete(object, _): return try ((object as? GitHubBridgeObject)?.onContext_operationForDeletion(userInfo: bmoRequest.remoteUserInfo)).flatMap{ ($0, UserInfo(requestEntity: object.entity)) }
		}
	}
	
	public func bridgeObjects(for finishedRemoteOperation: GitHubBMOOperation, userInfo: UserInfo) throws -> GitHubBridgeObjects? {
		let operationResult = try finishedRemoteOperation.results.get()
		let objects = operationResult.arrayValue ?? operationResult["items"]?.arrayValue ?? [operationResult]
		
		/* Let’s parse the Link header. */
		var metadata = Metadata()
		if let linkHeader = finishedRemoteOperation.responseHeaders?["Link"] as? String,
			let linkValues = LinkHeaderParser.parseLinkHeader(linkHeader, defaultContext: nil, contentLanguageHeader: nil)
		{
			metadata.nextPageURL     = linkValues.first{ $0.rel.contains("next") }?.link
			metadata.previousPageURL = linkValues.first{ $0.rel.contains("prev") }?.link
		}
		
		return GitHubBridgeObjects(remoteObjects: objects, localMetadata: metadata, localEntity: userInfo.requestEntity, userInfo: userInfo.bridgeObjectsUserInfo ?? .init())
	}
	
	public func importerForRemoteResults(localRepresentations: [GenericLocalDbObject<NSManagedObject, String, Metadata>], rootMetadata: Metadata?, uniquingIDsPerEntities: [NSEntityDescription : Set<String>], updatedObjectIDsPerEntities: [NSEntityDescription : Set<NSManagedObjectID>], cancellationCheck throwIfCancelled: () throws -> Void) throws -> BMOCoreDataImporter<LocalDb, Metadata> {
		return try BMOCoreDataImporter(
			uniquingProperty: "bmoID",
			localRepresentations: localRepresentations,
			rootMetadata: rootMetadata,
			uniquingIDsPerEntities: uniquingIDsPerEntities,
			updatedObjectIDsPerEntities: updatedObjectIDsPerEntities,
			cancellationCheck: throwIfCancelled
		)
	}
	
}
