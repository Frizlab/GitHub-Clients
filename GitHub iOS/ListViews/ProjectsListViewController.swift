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



class ProjectsListViewController : GitHubListViewController<Repository> {
	
	enum ProjectsSource {
		
		case searchAll
		case projects(of: User)
		
	}
	
	var projectsSource = ProjectsSource.searchAll
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		cellIdentifier = "ProjectCell"
		
		let t = title
		title = nil; title = t
	}
	
	override func configureCell(_ cell: UITableViewCell, element: Repository) {
		cell.textLabel?.text = element.fullName
	}
	
	override func collectionLoaderHelper(for searchText: String?, context: NSManagedObjectContext) -> BMOCoreDataSearchLoader<GitHubBridge, Repository, GitHubPageInfoRetriever> {
		let fetchRequest: NSFetchRequest<Repository> = Repository.fetchRequest()
		
		let repositoryEntity = Repository.entity()
		let ephemeralDeletionDateProperty = repositoryEntity.attributesByName[#keyPath(Repository.zEphemeralDeletionDate)]!
		
		let apiOrderProperty: NSAttributeDescription?
		let deletionDateProperty: NSAttributeDescription
		switch projectsSource {
			case .searchAll:
				if let t = searchText?.trimmingCharacters(in: .whitespaces), !t.isEmpty {
					nullify(property: ephemeralDeletionDateProperty, inInstancesOf: repositoryEntity, context: AppDelegate.shared.context)
					
					deletionDateProperty = ephemeralDeletionDateProperty
					apiOrderProperty = repositoryEntity.attributesByName[#keyPath(Repository.zPosInSearchResults)]!
					fetchRequest.predicate = NSPredicate(format: "%K LIKE[cd] %@", #keyPath(Repository.fullName), "*" + t + "*")
					fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Repository.zPosInSearchResults), ascending: false)]
				} else {
					apiOrderProperty = nil
					deletionDateProperty = repositoryEntity.attributesByName[#keyPath(Repository.zDeletionDateInRepositoriesList)]!
					fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Repository.remoteID), ascending: true)]
				}
				
			case .projects(of: let user):
				nullify(property: ephemeralDeletionDateProperty, inInstancesOf: repositoryEntity, context: AppDelegate.shared.context)
				apiOrderProperty = nil
				deletionDateProperty = ephemeralDeletionDateProperty
				fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(Repository.owner), user)
				if let t = searchText?.trimmingCharacters(in: .whitespaces), !t.isEmpty {
					fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
						fetchRequest.predicate!,
						NSPredicate(format: "%K LIKE[cd] %@", #keyPath(Repository.fullName), "*" + t + "*")
					])
				}
				fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Repository.updateDate), ascending: false)]
		}
		
		return try! BMOCoreDataSearchLoader(
			bridge: AppDelegate.shared.bridge,
			localDb: AppDelegate.shared.localDb,
			pageInfoRetriever: AppDelegate.shared.pageInfoRetriever,
			fetchRequest: fetchRequest,
			deletionDateProperty: deletionDateProperty,
			fetchRequestToBridgeRequest: { .fetch($0 as! NSFetchRequest<NSFetchRequestResult>) },
			pageInfoToRequestUserInfo: { _ in GitHubBridge.RequestUserInfo() }
		)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard segue.identifier == "ShowProject" else {return}
		guard let selectedRow = (sender as? UITableViewCell).flatMap({ tableView.indexPath(for: $0) }) else {return}
		
		let destinationVC = segue.destination as! ProjectViewController
		destinationVC.repository = resultsController.object(at: selectedRow)
	}
	
}
