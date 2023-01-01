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



class GistViewController : UITableViewController, NSFetchedResultsControllerDelegate {
	
	var gist: Gist!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let t = gist.firstFileName ?? "<unnamed>"
		title = nil; title = t
		
		let fetchRequest: NSFetchRequest<Gist> = Gist.fetchRequest()
		fetchRequest.predicate = NSPredicate(format: "SELF == %@", gist)
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Gist.bmoID), ascending: true)]
		fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: gist.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
		
		self.fetchedResultsController?.delegate = self
		try! self.fetchedResultsController?.performFetch()
		
		RequestOperation(
			bridge: AppDelegate.shared.bridge,
			request: .init(localDb: AppDelegate.shared.localDb, localRequest: .fetch(fetchRequest as! NSFetchRequest<any NSFetchRequestResult>), remoteUserInfo: .init()),
			remoteOperationQueue: OperationQueue(), computeOperationQueue: OperationQueue()
		).start()
		
		tableView.reloadData()
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		switch segue.identifier {
			case "ShowFile"?:
				guard let senderIndexPath = (sender as? UITableViewCell).flatMap({ tableView.indexPath(for: $0) }) else {return}
				let fileViewController = segue.destination as! GistFileViewController
				fileViewController.file = (gist.files?.object(at: senderIndexPath.row) as! File)
				
			default: (/*nop*/)
		}
	}
	
	/* *****************************************
	   MARK: - Table View Data Source & Delegate
	   ***************************************** */
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 2
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch section {
			case 0: return 1
			case 1: return gist.files?.count ?? 0
			default: fatalError()
		}
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		switch indexPath.section {
			case 0:
				let cell = tableView.dequeueReusableCell(withIdentifier: "DescriptionCell", for: indexPath)
				cell.textLabel?.text = (gist.descr?.isEmpty ?? true ? "<No description>" : gist.descr)
				return cell
				
			case 1:
				let cell = tableView.dequeueReusableCell(withIdentifier: "FileCell", for: indexPath)
				cell.textLabel?.text = (gist.files!.object(at: indexPath.row) as! File).filename
				return cell
				
			default:
				fatalError()
		}
	}
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		switch section {
			case 0: return "Description"
			case 1: return "Files"
			default: fatalError()
		}
	}
	
	/* *******************************************
	   MARK: - Fetched Results Controller Delegate
	   ******************************************* */
	
	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		tableView.reloadData()
	}
	
	/* ***************
	   MARK: - Private
	   *************** */
	
	private var fetchedResultsController: NSFetchedResultsController<Gist>!
	
}
