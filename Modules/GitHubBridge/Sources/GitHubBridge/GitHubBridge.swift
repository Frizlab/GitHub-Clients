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



public struct GitHubBridge : BridgeProtocol {
	
	public typealias LocalDb = GitHubLocalDb
	public typealias RemoteDb = GitHubRemoteDb
	
	public typealias BridgeObjects = GitHubBridgeObjects
	
	public typealias LocalDbImporter = BMOCoreDataImporter<LocalDb, Metadata>
	
	public struct RequestUserInfo {
		public init() {
		}
	}
	
	public enum Metadata {
		case none
	}
	
	public struct UserInfo {
		var requestEntity: NSEntityDescription
	}
	
	public static var coreDataModel: NSManagedObjectModel {
		NSManagedObjectModel(contentsOf: Bundle.module.url(forResource: "GitHub", withExtension: "momd")!)!
	}
	
	public init() {
	}
	
	public func requestHelper(for request: Request<LocalDb, RequestUserInfo>) -> any RequestHelperProtocol<NSManagedObject, Metadata> {
		switch request.localRequest {
			case let .fetch(fetchRequest):  return BMOCoreDataFetchRequestHelper(request: fetchRequest, context: request.localDb.context, fetchType: .always)
			case .create, .update, .delete: return BMOCoreDataSaveRequestHelper(context: request.localDb.context, saveWorkflow: .saveBeforeBackReturns)
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
					.flatMap{ ($0, UserInfo(requestEntity: entity)) }
				
			case let .create(object): return try ((object as? GitHubBridgeObject)?.onContext_operationForCreation(userInfo: bmoRequest.remoteUserInfo)).flatMap{ ($0, UserInfo(requestEntity: object.entity)) }
			case let .update(object): return try ((object as? GitHubBridgeObject)?.onContext_operationForUpdate(  userInfo: bmoRequest.remoteUserInfo)).flatMap{ ($0, UserInfo(requestEntity: object.entity)) }
			case let .delete(object): return try ((object as? GitHubBridgeObject)?.onContext_operationForDeletion(userInfo: bmoRequest.remoteUserInfo)).flatMap{ ($0, UserInfo(requestEntity: object.entity)) }
		}
	}
	
	public func bridgeObjects(for finishedRemoteOperation: GitHubBMOOperation, userInfo: UserInfo) throws -> GitHubBridgeObjects? {
		let operationResult = try finishedRemoteOperation.results.get()
		let objects = operationResult.arrayValue ?? [operationResult]
		return GitHubBridgeObjects(remoteObjects: objects, localMetadata: nil, localEntity: userInfo.requestEntity, localMergeType: .replace)
	}
	
	public func importerForRemoteResults(localRepresentations: [GenericLocalDbObject<NSManagedObject, String, Metadata>], rootMetadata: Metadata?, uniquingIDsPerEntities: [NSEntityDescription : Set<String>], cancellationCheck throwIfCancelled: () throws -> Void) throws -> BMOCoreData.BMOCoreDataImporter<LocalDb, Metadata> {
		return try BMOCoreDataImporter(
			uniquingProperty: "bmoID",
			localRepresentations: localRepresentations,
			rootMetadata: rootMetadata,
			uniquingIDsPerEntities: uniquingIDsPerEntities,
			cancellationCheck: throwIfCancelled
		)
	}
	
}
