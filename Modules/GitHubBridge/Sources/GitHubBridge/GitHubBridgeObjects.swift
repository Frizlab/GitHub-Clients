/*
Copyright 2023 happn

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
import GenericJSON



public struct GitHubBridgeObjects : BridgeObjectsProtocol {
	
	public typealias LocalDb = GitHubBridge.LocalDb
	public typealias RemoteDb = GitHubBridge.RemoteDb
	
	public typealias Metadata = GitHubBridge.Metadata
	
	public struct UserInfo {
		public init() {
		}
	}
	
	public let remoteObjects: [JSON]
	
	public let localEntity: NSEntityDescription
	public let localMetadata: GitHubBridge.Metadata?
	
	public let userInfo: UserInfo
	
	public static func forRelationshipsDictionary(
		remoteObjects: JSON?,
		localMetadata: GitHubBridge.Metadata? = nil,
		localEntity: NSEntityDescription,
		localMergeType: RelationshipMergeType<NSManagedObject, LocalDb.DbObject.DbRelationshipDescription>,
		userInfo: UserInfo = .init()
	) -> (Self, RelationshipMergeType<NSManagedObject, LocalDb.DbObject.DbRelationshipDescription>)? {
		guard let remoteObjects,
				let bridgeObjects = Self(remoteObjects: remoteObjects.arrayValue ?? [remoteObjects], localMetadata: localMetadata, localEntity: localEntity, userInfo: userInfo)
		else {
			return nil
		}
		return (bridgeObjects, localMergeType)
	}
	
	public init?(
		remoteObjects: [JSON],
		localMetadata: GitHubBridge.Metadata?,
		localEntity: NSEntityDescription,
		userInfo: UserInfo = .init()
	) {
		guard let entityClass = NSClassFromString(localEntity.managedObjectClassName) as? GitHubBridgeObject.Type else {
			return nil
		}
		
		self.remoteObjects = remoteObjects
		self.localMetadata = localMetadata
		self.localEntity = localEntity
		
		self.userInfo = userInfo
		
		self.entityClass = entityClass
	}
	
	public func mixedRepresentation(from remoteObject: GitHubRemoteDb.RemoteObject) throws -> MixedRepresentation<GitHubBridgeObjects>? {
		return try entityClass.mixedRepresentation(from: remoteObject, userInfo: userInfo)
	}
	
	private let entityClass: GitHubBridgeObject.Type
	
}
