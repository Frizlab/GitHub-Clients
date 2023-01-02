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
import UIKit

import BMOCoreDataCollectionLoaders

import GitHubBridge



class UsersListViewController : GitHubListViewController<User> {
	
	enum UsersSource {
		
		case searchAll
		case stargazers(of: Repository)
		case watchers(of: Repository)
		
	}
	
	var usersSource = UsersSource.searchAll
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		cellIdentifier = "UserCell"
		
		let t = title
		title = nil; title = t
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		switch segue.identifier {
			case "ShowUser"?:
				guard let selectedRow = (sender as? UITableViewCell).flatMap({ tableView.indexPath(for: $0) }) else {return}
				
				let userViewController = segue.destination as! UserViewController
				userViewController.user = resultsController.object(at: selectedRow)
				
			default: (/*nop*/)
		}
	}
	
	override func configureCell(_ cell: UITableViewCell, element: User) {
		cell.textLabel?.text = element.username
	}
	
	override func collectionLoaderHelper(for searchText: String?, context: NSManagedObjectContext) -> BMOCoreDataSearchLoader<GitHubBridge, User, GitHubPageInfoRetriever> {
		let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
		
		let userEntity = User.entity()
		let ephemeralDeletionDateProperty = userEntity.attributesByName[#keyPath(User.zEphemeralDeletionDate)]!
		
		let deletionDateProperty: NSAttributeDescription
		switch usersSource {
			case .searchAll:
				if let t = searchText?.trimmingCharacters(in: .whitespaces), !t.isEmpty {
					nullify(property: ephemeralDeletionDateProperty, inInstancesOf: userEntity, context: AppDelegate.shared.context)
					
					deletionDateProperty = ephemeralDeletionDateProperty
					fetchRequest.predicate = NSPredicate(format: "%K LIKE[cd] %@", #keyPath(User.username), t + "*")
					fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(User.username), ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
				} else {
					deletionDateProperty = userEntity.attributesByName[#keyPath(User.zDeletionDateInUsersList)]!
					fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(User.remoteID), ascending: true)]
				}
				
			case .stargazers(of: let repo):
				nullify(property: ephemeralDeletionDateProperty, inInstancesOf: userEntity, context: AppDelegate.shared.context)
				deletionDateProperty = ephemeralDeletionDateProperty
				
				fetchRequest.predicate = NSPredicate(format: "%K CONTAINS %@", #keyPath(User.starredRepositories), repo)
				fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(User.remoteID), ascending: true)]
				
			case .watchers(of: let repo):
				nullify(property: ephemeralDeletionDateProperty, inInstancesOf: userEntity, context: AppDelegate.shared.context)
				deletionDateProperty = ephemeralDeletionDateProperty
				
				fetchRequest.predicate = NSPredicate(format: "%K CONTAINS %@", #keyPath(User.watchedRepositories), repo)
				fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(User.remoteID), ascending: true)]
		}
		
		return try! BMOCoreDataSearchLoader(
			bridge: AppDelegate.shared.bridge,
			localDb: AppDelegate.shared.localDb,
			pageInfoRetriever: AppDelegate.shared.pageInfoRetriever,
			fetchRequest: fetchRequest,
			deletionDateProperty: deletionDateProperty,
			fetchRequestToBridgeRequest: { .fetch($0 as! NSFetchRequest<NSFetchRequestResult>) },
			pageInfoToRequestUserInfo: { pageInfo in GitHubBridge.RequestUserInfo(pageInfo: pageInfo) }
		)
	}
	
}
