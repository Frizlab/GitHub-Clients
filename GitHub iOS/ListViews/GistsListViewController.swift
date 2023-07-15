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



class GistsListViewController: GitHubListViewController<Gist> {
	
	enum GistsSource {
		
		case all
		case gists(of: User)
		
	}
	
	var gistsSource = GistsSource.all
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		cellIdentifier = "GistCell"
		
		let t = title
		title = nil; title = t
	}
	
	override var shouldShowSearchBar: Bool {
		return false /* Gists searching is apparently not supported by the GitHub API. */
	}
	
	override var numberOfElementsPerPage: Int {
		return 75
	}
	
	override func configureCell(_ cell: UITableViewCell, element: Gist) {
		cell.textLabel?.text = element.firstFileName
	}
	
	override func collectionLoaderHelper(for searchText: String?, context: NSManagedObjectContext) -> BMOCoreDataSearchLoader<GitHubBridge, Gist, GitHubPageInfoRetriever> {
		assert(searchText == nil)
		let fetchRequest: NSFetchRequest<Gist> = Gist.fetchRequest()
		
		let gistEntity = Gist.entity()
		let ephemeralDeletionDateProperty = gistEntity.attributesByName[#keyPath(Gist.zEphemeralDeletionDate)]!
		
		let deletionDateProperty: NSAttributeDescription
		switch gistsSource {
			case .all:
				deletionDateProperty = gistEntity.attributesByName[#keyPath(Gist.zDeletionDateInGistList)]!
				fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Gist.creationDate), ascending: false)]
				
			case .gists(of: let user):
				nullify(property: ephemeralDeletionDateProperty, inInstancesOf: gistEntity, context: AppDelegate.shared.context)
				deletionDateProperty = ephemeralDeletionDateProperty
				fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(Gist.owner), user)
				fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Gist.creationDate), ascending: false)]
		}
		return BMOCoreDataSearchLoader(
			api: AppDelegate.shared.gitHubAPI, pageInfoRetriever: AppDelegate.shared.pageInfoRetriever,
			fetchRequest: fetchRequest, deletionDateProperty: deletionDateProperty,
			pageInfoToRequestUserInfo: { GitHubBridge.RequestUserInfo(pageInfo: $0) }
		)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard segue.identifier == "ShowGist" else {return}
		guard let selectedRow = (sender as? UITableViewCell).flatMap({ tableView.indexPath(for: $0) }) else {return}
		
		let destinationVC = segue.destination as! GistViewController
		destinationVC.gist = resultsController.object(at: selectedRow)
	}
	
}
