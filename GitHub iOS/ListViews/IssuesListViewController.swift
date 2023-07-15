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



class IssuesListViewController : GitHubListViewController<Issue> {
	
	enum IssuesSource {
		
		case from(project: Repository)
		case assigned(to: User)
		
	}
	
	var issuesSource: IssuesSource!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		cellIdentifier = "IssueCell"
		
		let t = title
		title = nil; title = t
	}
	
	override var shouldShowSearchBar: Bool {
		return false
	}
	
	override var numberOfElementsPerPage: Int {
		return 75
	}
	
	override func configureCell(_ cell: UITableViewCell, element: Issue) {
		cell.textLabel?.text = element.title
	}
	
	override func collectionLoaderHelper(for searchText: String?, context: NSManagedObjectContext) -> BMOCoreDataSearchLoader<GitHubBridge, Issue, GitHubPageInfoRetriever> {
		assert(searchText == nil)
		let fetchRequest: NSFetchRequest<Issue> = Issue.fetchRequest()
		
		let issueEntity = Issue.entity()
		let ephemeralDeletionDateProperty = issueEntity.attributesByName[#keyPath(Gist.zEphemeralDeletionDate)]!
		
		let deletionDateProperty: NSAttributeDescription
		switch issuesSource! {
			case .from(project: let repository):
				nullify(property: ephemeralDeletionDateProperty, inInstancesOf: issueEntity, context: AppDelegate.shared.context)
				deletionDateProperty = ephemeralDeletionDateProperty
				fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(Issue.repository), repository)
				fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Gist.creationDate), ascending: false)]
				
			case .assigned(to: let user):
				nullify(property: ephemeralDeletionDateProperty, inInstancesOf: issueEntity, context: AppDelegate.shared.context)
				deletionDateProperty = ephemeralDeletionDateProperty
				fetchRequest.predicate = NSPredicate(format: "%K CONTAINS %@", #keyPath(Issue.assignees), user)
				fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Gist.creationDate), ascending: false)]
		}
		return BMOCoreDataSearchLoader(
			api: AppDelegate.shared.gitHubAPI, pageInfoRetriever: AppDelegate.shared.pageInfoRetriever,
			fetchRequest: fetchRequest, deletionDateProperty: deletionDateProperty,
			pageInfoToRequestUserInfo: { GitHubBridge.RequestUserInfo(pageInfo: $0) }
		)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard segue.identifier == "ShowIssue" else {return}
		guard let selectedRow = (sender as? UITableViewCell).flatMap({ tableView.indexPath(for: $0) }) else {return}
		
		let destinationVC = segue.destination as! IssueViewController
		destinationVC.issue = resultsController.object(at: selectedRow)
	}
	
}
