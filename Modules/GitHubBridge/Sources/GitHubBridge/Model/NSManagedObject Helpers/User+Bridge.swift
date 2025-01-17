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
import UnwrapOrThrow



extension User : GitHubBridgeObject {
	
	public struct BridgeObjectsUserInfo {
		var starredRepositoryID: Int64?
		var watchedRepositoryID: Int64?
	}
	
	public static func onContext_operation(for fetchRequest: NSFetchRequest<NSFetchRequestResult>, userInfo: GitHubBridge.RequestUserInfo) throws -> (GitHubBMOOperation, GitHubBridgeObjects.UserInfo?)? {
		/* /users/:username <-- Get one user */
		/* /users           <-- Lists all the users */
		/* /user            <-- Get the authenticated user */
//		.restPath("/users(/|username|)"),
		if let usernamePredicates = fetchRequest.predicate?.firstLevelComparisonSubpredicates
								.filter({ $0.keyPathExpression?.keyPath == "username" && $0.predicateOperatorType == .like && $0.comparisonPredicateModifier == .direct }),
			let usernamePredicate = usernamePredicates.first, usernamePredicates.count == 1,
			let searchedUsernameWithStar = usernamePredicate.constantValueExpression?.constantValue as? String,
			searchedUsernameWithStar.hasSuffix("*"), searchedUsernameWithStar != "*"
		{
			/* ****************
			   Search for Users
			   **************** */
			let searchedUsername = searchedUsernameWithStar.dropLast()
			return GitHubBMOOperation(pathComponents: ["search", "users"], queryItems: [.init(name: "q", value: searchedUsername + " in:login")], pageInfo: userInfo.pageInfo).flatMap{ ($0, nil) }
			
		} else if let starredRepositoriesPredicates = fetchRequest.predicate?.firstLevelComparisonSubpredicates
								.filter({ $0.keyPathExpression?.keyPath == "starredRepositories" && $0.predicateOperatorType == .contains }),
					 let starredRepositoriesPredicate = starredRepositoriesPredicates.first, starredRepositoriesPredicates.count == 1,
					 let starredRepository = starredRepositoriesPredicate.constantValueExpression?.constantValue as? Repository
		{
			/* ****************************************************
			   Search for Users Who Have Starred a Given Repository
			   **************************************************** */
			return GitHubBMOOperation(pathComponents: ["repos", starredRepository.owner?.username, starredRepository.name, "stargazers"], pageInfo: userInfo.pageInfo).flatMap{
				(
					$0,
					.init(objectSpecific: BridgeObjectsUserInfo(starredRepositoryID: starredRepository.remoteID))
				)
			}
			
		} else if let watchedRepositoriesPredicates = fetchRequest.predicate?.firstLevelComparisonSubpredicates
								.filter({ $0.keyPathExpression?.keyPath == "watchedRepositories" && $0.predicateOperatorType == .contains }),
					 let watchedRepositoriesPredicate = watchedRepositoriesPredicates.first, watchedRepositoriesPredicates.count == 1,
					 let watchedRepository = watchedRepositoriesPredicate.constantValueExpression?.constantValue as? Repository
		{
			/* ********************************************************
			   Search for Users Who Have Subscribed to Given Repository
			   ******************************************************** */
			return GitHubBMOOperation(pathComponents: ["repos", watchedRepository.owner?.username, watchedRepository.name, "subscribers"], pageInfo: userInfo.pageInfo).flatMap{
				(
					$0,
					.init(objectSpecific: BridgeObjectsUserInfo(watchedRepositoryID: watchedRepository.remoteID))
				)
			}
			
		} else {
			/* ************************************************************
			   Generic Case: List Users or Get One If Username Is Specified
			   ************************************************************ */
			let username: String?
			if let selfUsernames = fetchRequest.predicate?.firstLevelComparisonSubpredicates
				.filter({ $0.leftExpression.expressionType == .evaluatedObject || $0.rightExpression.expressionType == .evaluatedObject })
				.compactMap({ ($0.constantValueExpression?.constantValue as? User)?.username }),
				let selfUsername = selfUsernames.first, selfUsernames.count == 1
			{
				username = selfUsername
			} else {
				username = fetchRequest.predicate?.firstLevelConstants(forKeyPath: "username").last as? String
			}
			return GitHubBMOOperation(pathComponents: ["users", username].compactMap{ $0 } as [String], pageInfo: userInfo.pageInfo).flatMap{ ($0, nil) }
		}
	}
	
	public func onContext_operationForCreation(userInfo: GitHubBridge.RequestUserInfo) throws -> GitHubBMOOperation? {
		return nil
	}
	
	public func onContext_operationForUpdate(userInfo: GitHubBridge.RequestUserInfo) throws -> GitHubBMOOperation? {
		return nil
	}
	
	public func onContext_operationForDeletion(userInfo: GitHubBridge.RequestUserInfo) throws -> GitHubBMOOperation? {
		return nil
	}
	
	public static func mixedRepresentation(from remoteObject: GitHubRemoteDb.RemoteObject, userInfo: GitHubBridgeObjects.UserInfo) throws -> MixedRepresentation<GitHubBridgeObjects>? {
		struct InvalidRemoteObject : Error {}
		
		let bmoID = try String(remoteObject["id"]?.doubleValue ?! InvalidRemoteObject())
		let allAttributes: [String: Any??] = [
			#keyPath(User.bmoID):            bmoID,
			#keyPath(User.avatarURL):        try remoteObject["avatar_url"]  .flatMap(Converters.convertJSONToURL),
			#keyPath(User.company):          try remoteObject["company"]     .flatMap(Converters.convertJSONToOptionalString),
			#keyPath(User.creationDate):     try remoteObject["created_at"]  .flatMap(Converters.convertJSONToDate),
			#keyPath(User.followersCount):   try remoteObject["followers"]   .flatMap(Converters.convertJSONToInt),
			#keyPath(User.followingCount):   try remoteObject["following"]   .flatMap(Converters.convertJSONToInt),
			#keyPath(User.name):             try remoteObject["name"]        .flatMap(Converters.convertJSONToOptionalString),
			#keyPath(User.nodeID):           try remoteObject["node_id"]     .flatMap(Converters.convertJSONToString),
			#keyPath(User.publicGistsCount): try remoteObject["public_gists"].flatMap(Converters.convertJSONToInt),
			#keyPath(User.publicReposCount): try remoteObject["public_repos"].flatMap(Converters.convertJSONToInt),
			#keyPath(User.remoteID):         try remoteObject["id"]          .flatMap(Converters.convertJSONToInt),
			#keyPath(User.updateDate):       try remoteObject["updated_at"]  .flatMap(Converters.convertJSONToDate),
			#keyPath(User.username):         try remoteObject["login"]       .flatMap(Converters.convertJSONToString),
			#keyPath(User.zDeletionDateInUsersList): .some(nil),
			#keyPath(User.zEphemeralDeletionDate):   .some(nil),
		]
		var allRelationships: [String: (GitHubBridgeObjects, RelationshipMergeType<NSManagedObject, String>)?] = [:]
		if let bridgeObjectsInfo = userInfo.objectSpecific as? BridgeObjectsUserInfo {
			if let id = bridgeObjectsInfo.starredRepositoryID {
				allRelationships[#keyPath(User.starredRepositories)] = (GitHubBridgeObjects(remoteObjects: [.object(["id": .number(Double(id))])], localMetadata: nil, localEntity: Repository.entity())!, .append)
			}
			if let id = bridgeObjectsInfo.watchedRepositoryID {
				allRelationships[#keyPath(User.watchedRepositories)] = (GitHubBridgeObjects(remoteObjects: [.object(["id": .number(Double(id))])], localMetadata: nil, localEntity: Repository.entity())!, .append)
			}
		}
		Self.assertAttributesValidity(allAttributes)
		Self.assertRelationshipsValidity(allRelationships)
		let attributes = allAttributes.compactMapValues{ $0 }
		let relationships = allRelationships.compactMapValues{ $0 }
		return MixedRepresentation(
			entity: entity(),
			uniquingID: bmoID,
			attributes: attributes,
			relationships: relationships
		)
	}
	
}
