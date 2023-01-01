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

import BMO
import BMOCoreData

import GitHubBridge



class UserViewController : UIViewController, NSFetchedResultsControllerDelegate {
	
	var user: User!
	var shouldRefreshUserOnLoad = true
	
	@IBOutlet var labelUsername: UILabel!
	
	@IBOutlet var buttonPublicRepos: UIButton!
	@IBOutlet var buttonPublicGists: UIButton!
	@IBOutlet var buttonAssignedIssues: UIButton!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let t = title
		title = nil; title = t
		
		let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
		fetchRequest.predicate = NSPredicate(format: "SELF == %@", user)
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(User.username), ascending: true)]
		fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: user.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
		
		fetchedResultsController?.delegate = self
		try! fetchedResultsController?.performFetch()
		
		if shouldRefreshUserOnLoad {
			RequestOperation(
				bridge: AppDelegate.shared.bridge,
				request: .init(localDb: AppDelegate.shared.localDb, localRequest: .fetch(fetchRequest as! NSFetchRequest<any NSFetchRequestResult>), remoteUserInfo: .init()),
				remoteOperationQueue: OperationQueue(), computeOperationQueue: OperationQueue()
			).start()
		}
		
		updateUI()
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		switch segue.identifier {
			case "ShowGists"?:
				let gistsListViewController = segue.destination as! GistsListViewController
				gistsListViewController.gistsSource = .gists(of: user)
				
			case "ShowRepositories"?:
				let repositoriesListViewController = segue.destination as! ProjectsListViewController
				repositoriesListViewController.projectsSource = .projects(of: user)
				
			case "ShowIssues"?:
				let issuesListViewController = segue.destination as! IssuesListViewController
				issuesListViewController.issuesSource = .assigned(to: user)
				
			default: (/*nop*/)
		}
	}
	
	/* *******************************************
	   MARK: - Fetched Results Controller Delegate
	   ******************************************* */
	
	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		updateUI()
	}
	
	/* ***************
	   MARK: - Private
	   *************** */
	
	private var fetchedResultsController: NSFetchedResultsController<User>!
	
	private func updateUI() {
		guard let user = fetchedResultsController?.fetchedObjects?.first else {
			buttonAssignedIssues.isHidden = true
			labelUsername.text = "Error"
			return
		}
		
		labelUsername.text = user.username
		buttonAssignedIssues.isHidden = (user.username != AppDelegate.shared.myUsername)
		
		/* Both performWithoutAnimation and layoutIfNeeded are needed to avoid the animations on the buttons when changing the title… */
		UIView.performWithoutAnimation{
			buttonPublicRepos.setTitle("See Public Repositories (\(user.publicReposCount))", for: .normal)
			buttonPublicGists.setTitle("See Public Gists (\(user.publicGistsCount))", for: .normal)
			buttonPublicRepos.layoutIfNeeded()
			buttonPublicGists.layoutIfNeeded()
		}
	}
	
}
