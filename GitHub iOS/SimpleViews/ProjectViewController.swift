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



class ProjectViewController : UIViewController, NSFetchedResultsControllerDelegate {
	
	var repository: Repository!
	
	@IBOutlet var labelProjectName: UILabel!
	@IBOutlet var labelProjectDescription: UILabel!
	
	@IBOutlet var buttonSeeIssues: UIButton!
	@IBOutlet var buttonSeeStargazers: UIButton!
	@IBOutlet var buttonSeeWatchers: UIButton!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let t = repository.name
		title = nil; title = t
		
		let fetchRequest: NSFetchRequest<Repository> = Repository.fetchRequest()
		fetchRequest.predicate = NSPredicate(format: "SELF == %@", repository)
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Repository.name), ascending: true)]
		fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: repository.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
		
		self.fetchedResultsController?.delegate = self
		try! self.fetchedResultsController?.performFetch()
		
		AppDelegate.shared.gitHubAPI.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>)
		
		updateUI()
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		switch segue.identifier {
			case "ShowStargazers"?:
				let usersListViewController = segue.destination as! UsersListViewController
				usersListViewController.usersSource = .stargazers(of: repository)
				
			case "ShowWatchers"?:
				let usersListViewController = segue.destination as! UsersListViewController
				usersListViewController.usersSource = .watchers(of: repository)
				
			case "ShowOpenIssues"?:
				let issuesListViewController = segue.destination as! IssuesListViewController
				issuesListViewController.issuesSource = .from(project: repository)
				
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
	
	private var fetchedResultsController: NSFetchedResultsController<Repository>!
	
	private func updateUI() {
		guard let repository = fetchedResultsController?.fetchedObjects?.first else {
			labelProjectDescription.isHidden = true
			labelProjectName.text = "Error"
			return
		}
		
		labelProjectName.text = repository.fullName
		labelProjectDescription.isHidden = false
		labelProjectDescription.text = (repository.descr?.isEmpty ?? true ? "<No Description>" : repository.descr)
		
		/* Both performWithoutAnimation and layoutIfNeeded are needed to avoid the animations on the buttons when changing the title… */
		UIView.performWithoutAnimation{
			buttonSeeIssues.setTitle("See Open Issues (\(repository.openIssuesCount))", for: .normal)
			buttonSeeWatchers.setTitle("See Watchers (\(repository.watchersCount))", for: .normal)
			buttonSeeStargazers.setTitle("See Stargazers (\(repository.stargazersCount))", for: .normal)
			buttonSeeIssues.layoutIfNeeded()
			buttonSeeWatchers.layoutIfNeeded()
			buttonSeeStargazers.layoutIfNeeded()
		}
	}
	
}
