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
	
	public static func onContext_operation(for fetchRequest: NSFetchRequest<NSFetchRequestResult>, userInfo: GitHubBridge.RequestUserInfo) throws -> GitHubBMOOperation? {
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
			return GitHubBMOOperation(pathComponents: ["search", "users"], queryItems: [.init(name: "q", value: searchedUsername + " in:login")])
			
		} else if let starredRepositoriesPredicates = fetchRequest.predicate?.firstLevelComparisonSubpredicates
								.filter({ $0.keyPathExpression?.keyPath == "starredRepositories" && $0.predicateOperatorType == .contains }),
					 let starredRepositoriesPredicate = starredRepositoriesPredicates.first, starredRepositoriesPredicates.count == 1,
					 let starredRepository = starredRepositoriesPredicate.constantValueExpression?.constantValue as? Repository
		{
			/* ****************************************************
			   Search for Users Who Have Starred a Given Repository
			   **************************************************** */
			return GitHubBMOOperation(pathComponents: ["repos", starredRepository.owner?.username, starredRepository.name, "stargazers"])
//			userInfo.addedToMixedRepresentations = userInfo.addedToMixedRepresentations ?? [:]
//			userInfo.addedToMixedRepresentations!["starredRepositories"] = ["id": starredRepository.remoteId]
			
		} else if let watchedRepositoriesPredicates = fetchRequest.predicate?.firstLevelComparisonSubpredicates
								.filter({ $0.keyPathExpression?.keyPath == "watchedRepositories" && $0.predicateOperatorType == .contains }),
					 let watchedRepositoriesPredicate = watchedRepositoriesPredicates.first, watchedRepositoriesPredicates.count == 1,
					 let watchedRepository = watchedRepositoriesPredicate.constantValueExpression?.constantValue as? Repository
		{
			/* ********************************************************
			   Search for Users Who Have Subscribed to Given Repository
			   ******************************************************** */
			return GitHubBMOOperation(pathComponents: ["repos", watchedRepository.owner?.username, watchedRepository.name, "subscribers"])
//			userInfo.addedToMixedRepresentations = userInfo.addedToMixedRepresentations ?? [:]
//			userInfo.addedToMixedRepresentations!["watchedRepositories"] = ["id": watchedRepository.remoteId]
			
		} else {
			/* ***********************************************************
			   Generic Case: List User Or Get One If username Is Specified
			   *********************************************************** */
			let username: String?
			if let selfUsernames = fetchRequest.predicate?.firstLevelComparisonSubpredicates
				.filter({ $0.leftExpression.expressionType == .evaluatedObject || $0.rightExpression.expressionType == .evaluatedObject })
				.compactMap({ ($0.constantValueExpression?.constantValue as? User)?.username }),
				let selfUsername = selfUsernames.first, selfUsernames.count == 1
			{
				/* But we have a “SELF == user” predicate, so we set that in the REST path resolving info (not supported by the REST mapper). */
				username = selfUsername
			} else {
				username = fetchRequest.predicate?.firstLevelConstants(forKeyPath: "username").last as? String
			}
			return GitHubBMOOperation(pathComponents: ["users", username].compactMap{ $0 } as [String])
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
		let allAttributes: [String: Any?] = [
			#keyPath(User.bmoID):            bmoID,
			#keyPath(User.avatarURL):        try remoteObject["avatar_url"]  .flatMap(Converters.convertJSONToURL),
			#keyPath(User.company):          try remoteObject["company"]     .flatMap(Converters.convertJSONToString),
			#keyPath(User.creationDate):     try remoteObject["created_at"]  .flatMap(Converters.convertJSONToDate),
			#keyPath(User.followersCount):   try remoteObject["followers"]   .flatMap(Converters.convertJSONToInt),
			#keyPath(User.followingCount):   try remoteObject["following"]   .flatMap(Converters.convertJSONToInt),
			#keyPath(User.name):             try remoteObject["name"]        .flatMap(Converters.convertJSONToString),
			#keyPath(User.nodeID):           try remoteObject["node_id"]     .flatMap(Converters.convertJSONToString),
			#keyPath(User.publicGistsCount): try remoteObject["public_gists"].flatMap(Converters.convertJSONToInt),
			#keyPath(User.publicReposCount): try remoteObject["public_repos"].flatMap(Converters.convertJSONToInt),
			#keyPath(User.remoteID):         try remoteObject["id"]          .flatMap(Converters.convertJSONToInt),
			#keyPath(User.updateDate):       try remoteObject["updated_at"]  .flatMap(Converters.convertJSONToDate),
			#keyPath(User.username):         try remoteObject["login"]       .flatMap(Converters.convertJSONToString),
			#keyPath(User.zDeletionDateInUsersList): nil,
			#keyPath(User.zEphemeralDeletionDate):   nil,
		]
		let allRelationships: [String: (GitHubBridgeObjects, RelationshipMergeType<NSManagedObject, String>)?] = [:]
		Self.assertAttributesValidity(allAttributes)
		Self.assertRelationshipsValidity(allRelationships)
#warning("TODO: Filter attributes and relationships on requested fields instead of non-nil values.")
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
