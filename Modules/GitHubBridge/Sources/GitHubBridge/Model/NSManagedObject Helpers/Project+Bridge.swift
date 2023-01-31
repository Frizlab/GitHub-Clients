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
import UnwrapOrThrow



extension Repository : GitHubBridgeObject {
	
	public static func onContext_operation(for fetchRequest: NSFetchRequest<NSFetchRequestResult>, userInfo: GitHubBridge.RequestUserInfo) throws -> (GitHubBMOOperation, GitHubBridgeObjects.UserInfo?)? {
		/* /repos/:owner/:repo    <-- Get one repository */
		/* /user/repos            <-- Lists all repositories on which the authenticated user has explicit permission to access */
		/* /users/:username/repos <-- Lists public repositories for the specified user */
		/* /orgs/:org/repos       <-- Lists repositories for the specified org */
		/* /repositories          <-- Lists all public repositories */
//		.restPath("/repos/|owner.username|/|name|"),
		let selfRepository = (fetchRequest.predicate?.firstLevelComparisonSubpredicates
			.filter{ $0.leftExpression.expressionType == .evaluatedObject || $0.rightExpression.expressionType == .evaluatedObject }
			.compactMap{ ($0.constantValueExpression?.constantValue as? Repository) })
			.flatMap{ $0.count == 1 ? $0.first : nil }
		let owners = fetchRequest.predicate?.firstLevelConstants(forKeyPath: "owner", withOrCompound: true, withAndCompound: true)
		if owners?.isEmpty ?? true && selfRepository == nil {
			/* ***********************************
			   Search For or List All Repositories
			   *********************************** */
			if let namePredicates = fetchRequest.predicate?.firstLevelComparisonSubpredicates
					.filter({ $0.keyPathExpression?.keyPath == "fullName" && $0.predicateOperatorType == .like && $0.comparisonPredicateModifier == .direct }),
				let namePredicate = namePredicates.first, namePredicates.count == 1,
				let searchedNameWithStars = namePredicate.constantValueExpression?.constantValue as? String,
				searchedNameWithStars.hasPrefix("*"), searchedNameWithStars.hasSuffix("*"), searchedNameWithStars != "**"
			{
				let searchedName = searchedNameWithStars.dropFirst().dropLast()
				let queryItems: [URLQueryItem] = [
					.init(name: "q",     value: searchedName + " in:name"),
//					.init(name: "sort",  value: "stars"),
//					.init(name: "order", value: "desc"),
				]
				return GitHubBMOOperation(pathComponents: ["search", "repositories"], queryItems: queryItems, pageInfo: userInfo.pageInfo).flatMap{ ($0, nil) }
			} else {
				return GitHubBMOOperation(pathComponents: ["repositories"], pageInfo: userInfo.pageInfo).flatMap{ ($0, nil) }
			}
			
		} else if let owners = owners as? [User], let ownerUsername = owners.first?.username, owners.count == 1 {
			/* **********************************
			   Get Repositories from a Given User
			   ********************************** */
			let queryItems: [URLQueryItem] = [
				.init(name: "sort",      value: "updated"),
				.init(name: "direction", value: "desc"),
			]
			return GitHubBMOOperation(pathComponents: ["users", ownerUsername, "repos"], queryItems: queryItems, pageInfo: userInfo.pageInfo).flatMap{ ($0, nil) }
			
		} else if let selfOwnerUsername = selfRepository?.owner?.username, let selfName = selfRepository?.name {
			/* ******************
			   Get One Repository
			   ****************** */
			return GitHubBMOOperation(pathComponents: ["repos", selfOwnerUsername, selfName], pageInfo: userInfo.pageInfo).flatMap{ ($0, nil) }
			
		} else {
			return nil
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
			#keyPath(Repository.bmoID):           bmoID,
			#keyPath(Repository.creationDate):    try remoteObject["created_at"]       .flatMap(Converters.convertJSONToDate),
			#keyPath(Repository.defaultBranch):   try remoteObject["default_branch"]   .flatMap(Converters.convertJSONToString),
			#keyPath(Repository.descr):           try remoteObject["description"]      .flatMap(Converters.convertJSONToOptionalString),
			#keyPath(Repository.forksCount):      try remoteObject["forks_count"]      .flatMap(Converters.convertJSONToInt),
			#keyPath(Repository.fullName):        try remoteObject["full_name"]        .flatMap(Converters.convertJSONToString),
			#keyPath(Repository.hasDownloads):    try remoteObject["has_downloads"]    .flatMap(Converters.convertJSONToBool),
			#keyPath(Repository.hasIssues):       try remoteObject["has_issues"]       .flatMap(Converters.convertJSONToBool),
			#keyPath(Repository.hasPages):        try remoteObject["has_pages"]        .flatMap(Converters.convertJSONToBool),
			#keyPath(Repository.hasWiki):         try remoteObject["has_wiki"]         .flatMap(Converters.convertJSONToBool),
			#keyPath(Repository.isArchived):      try remoteObject["archived"]         .flatMap(Converters.convertJSONToBool),
			#keyPath(Repository.isFork):          try remoteObject["fork"]             .flatMap(Converters.convertJSONToBool),
			#keyPath(Repository.isPrivate):       try remoteObject["private"]          .flatMap(Converters.convertJSONToBool),
			#keyPath(Repository.latestPushDate):  try remoteObject["pushed_at"]        .flatMap(Converters.convertJSONToOptionalDate),
			#keyPath(Repository.name):            try remoteObject["name"]             .flatMap(Converters.convertJSONToString),
			#keyPath(Repository.nodeID):          try remoteObject["node_id"]          .flatMap(Converters.convertJSONToString),
			#keyPath(Repository.openIssuesCount): try remoteObject["open_issues_count"].flatMap(Converters.convertJSONToInt),
			#keyPath(Repository.remoteID):        try remoteObject["id"]               .flatMap(Converters.convertJSONToInt),
			#keyPath(Repository.stargazersCount): try remoteObject["stargazers_count"] .flatMap(Converters.convertJSONToInt),
			#keyPath(Repository.updateDate):      try remoteObject["updated_at"]       .flatMap(Converters.convertJSONToDate),
			#keyPath(Repository.watchersCount):   try remoteObject["subscribers_count"].flatMap(Converters.convertJSONToInt),
			#keyPath(Repository.zDeletionDateInRepositoriesList): .some(nil),
			#keyPath(Repository.zEphemeralDeletionDate):          .some(nil),
		]
		let allRelationships: [String: (GitHubBridgeObjects, RelationshipMergeType<NSManagedObject, String>)?] = [
			#keyPath(Repository.license): GitHubBridgeObjects.forRelationshipsDictionary(remoteObjects: remoteObject["license"], localEntity: License.entity(), localMergeType: .replace),
			#keyPath(Repository.owner):   GitHubBridgeObjects.forRelationshipsDictionary(remoteObjects: remoteObject["owner"],   localEntity:    User.entity(), localMergeType: .replace),
			#keyPath(Repository.topics):  {
				let topicsAsObjectsArray = (remoteObject["topics"]?.arrayValue?.map{ JSON.object(["name": $0]) }).flatMap{ JSON.array($0) }
				return GitHubBridgeObjects.forRelationshipsDictionary(remoteObjects: topicsAsObjectsArray, localEntity: Topic.entity(), localMergeType: .replace)
			}()
		]
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
