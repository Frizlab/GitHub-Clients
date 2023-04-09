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



class IssueViewController : UIViewController, NSFetchedResultsControllerDelegate {
	
	var issue: Issue!
	
	@IBOutlet var labelIssueName: UILabel!
	@IBOutlet var labelIssueDescription: UILabel!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let t = (issue.repository?.name.flatMap{ $0 + " — " } ?? "") + "#" + String(issue.issueNumber)
		title = nil; title = t
		
		let fetchRequest: NSFetchRequest<Issue> = Issue.fetchRequest()
		fetchRequest.predicate = NSPredicate(format: "SELF == %@", issue)
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Issue.issueNumber), ascending: true)]
		fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: issue.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
		
		self.fetchedResultsController?.delegate = self
		try! self.fetchedResultsController?.performFetch()
		
		AppDelegate.shared.gitHubAPI.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>)
		
		updateUI()
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		let w = view.bounds.width - view.layoutMargins.left - view.layoutMargins.right
		
		labelIssueName.preferredMaxLayoutWidth = w
		labelIssueDescription.preferredMaxLayoutWidth = w
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		switch segue.identifier {
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
	
	private var fetchedResultsController: NSFetchedResultsController<Issue>!
	
	private func updateUI() {
		guard let issue = fetchedResultsController?.fetchedObjects?.first else {
			labelIssueDescription.text = ""
			labelIssueName.text = "Error"
			return
		}
		
		labelIssueName.text = issue.title
		labelIssueDescription.text = issue.descr
	}
	
}
