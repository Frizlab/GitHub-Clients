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
import CollectionAndTableViewUpdateConveniences
import CollectionLoader

import GitHubBridge



class GitHubListViewController<ListElement : NSManagedObject> : UITableViewController, NSFetchedResultsControllerDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
	
	var cellIdentifier: String!
	
	private(set) var collectionLoader: CollectionLoader<BMOCoreDataSearchLoader<GitHubBridge, ListElement, GitHubPageInfoRetriever>>!
	private(set) var searchController: UISearchController!
	
	var resultsController: NSFetchedResultsController<ListElement> {
		return collectionLoader.helper.resultsController
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		/* ***** Configuring the Table View ***** */
		tableView.fetchedResultsControllerMoveMode = .move(reloadMode: .standard)
		tableView.fetchedResultsControllerReloadMode = .handler{ [weak self] cell, object, _, _ in self?.configureCell(cell, element: object as! ListElement) }
		
		/* ***** Add refresh control to the table view ***** */
		let rc = UIRefreshControl()
		rc.addTarget(self, action: #selector(refreshTableView(_:)), for: .valueChanged)
		tableView.refreshControl = rc
		
		/* ***** Configuring the Search Controller ***** */
		if shouldShowSearchBar {
			searchController = UISearchController(searchResultsController: nil)
			searchController.delegate = self
			searchController.searchResultsUpdater = self
			searchController.hidesNavigationBarDuringPresentation = true
			searchController.obscuresBackgroundDuringPresentation = false
			
			navigationItem.searchController = searchController
			definesPresentationContext = true /* Needed so that navigation works when searching */
		}
		
		/* ***** Setup the Collection Loader ***** */
		setupCollectionLoader(searchText: nil)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		/* If the refresh control is updated too soon, the collection view inset
		 * will not be updated and we won't be able to show the refresh control.
		 * So we have to block the update until the view _did_ appear. */
		blockSetRefreshControlIsRefreshing = false
#warning("TODO: Add current loading state in CollectionLoader")
//		updateRefreshControl(loading: collectionLoader.)
	}
	
	/* ***********************
	   MARK: - Override Points
	   *********************** */
	
	var shouldShowSearchBar: Bool {
		return true
	}
	
	var numberOfElementsPerPage: Int {
		return 21
	}
	
	func configureCell(_ cell: UITableViewCell, element: ListElement) {
		fatalError("Abstract method called.")
	}
	
	func collectionLoaderHelper(for searchText: String?, context: NSManagedObjectContext) -> BMOCoreDataSearchLoader<GitHubBridge, ListElement, GitHubPageInfoRetriever> {
		fatalError("Abstract method called.")
	}
	
	/* ******************************************
	   MARK: - Table View DataSource and Delegate
	   ****************************************** */
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return resultsController.sections!.count
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return resultsController.sections![section].numberOfObjects
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
		configureCell(cell, element: resultsController.object(at: indexPath))
		return cell
	}
	
	override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		if indexPath.section == tableView.numberOfSections-1 && indexPath.row >= tableView.numberOfRows(inSection: indexPath.section)-5 {
			collectionLoader.loadNextPage()
		}
	}
	
	/* *******************************
	   MARK: - Search Results Updating
	   ******************************* */
	
	func updateSearchResults(for searchController: UISearchController) {
		timerRefreshCollectionLoader?.invalidate()
		timerRefreshCollectionLoader = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { _ in
			self.timerRefreshCollectionLoader = nil
			self.setupCollectionLoader(searchText: searchController.searchBar.text)
		})
	}
	
	/* ******************************************
	   MARK: - NSFetchedResultsControllerDelegate
	   ****************************************** */
	
	func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		tableView.fetchedResultsControllerWillChangeContent()
	}
	
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
		tableView.fetchedResultsControllerDidChange(section: sectionInfo, atIndex: sectionIndex, forChangeType: type)
	}
	
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
		tableView.fetchedResultsControllerDidChange(object: anObject, atIndexPath: indexPath, forChangeType: type, newIndexPath: newIndexPath)
	}
	
	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		tableView.fetchedResultsControllerDidChangeContent()
	}
	
	/* ***************
	   MARK: - Private
	   *************** */
	
	private var blockSetRefreshControlIsRefreshing = true
	
	private var currentSearch: String?
	private var timerRefreshCollectionLoader: Timer?
	
	private func setupCollectionLoader(searchText: String?) {
		guard searchText != currentSearch || collectionLoader == nil else {return}
		currentSearch = searchText
		
//		collectionLoader?.cancelAllLoadings()
		collectionLoader?.helper.resultsController.delegate = nil
		
		let clh = collectionLoaderHelper(for: searchText, context: AppDelegate.shared.context)
		collectionLoader = CollectionLoader(helper: clh)
		collectionLoader.delegate = self
		collectionLoader.helper.resultsController.delegate = self
		collectionLoader.loadInitialPage()
		
		tableView.reloadData()
	}
	
	@objc
	@IBAction func refreshTableView(_ sender: AnyObject) {
		collectionLoader.loadInitialPage()
	}
	
}


extension GitHubListViewController : CollectionLoaderDelegate {
	
	typealias CollectionLoaderHelper = BMOCoreDataSearchLoader<GitHubBridge, ListElement, GitHubPageInfoRetriever>
	
	func willStartLoading(pageLoadDescription: CLDPageLoadDescription) {
		updateRefreshControl(loading: pageLoadDescription.loadingReason == .initialPage)
	}
	
	func didFinishLoading(pageLoadDescription: CLDPageLoadDescription, results: Result<CompletionResults, Error>) {
		updateRefreshControl(loading: false)
	}
	
	private func updateRefreshControl(loading: Bool) {
		guard !blockSetRefreshControlIsRefreshing,
				let refreshControl = refreshControl,
				loading != refreshControl.isRefreshing
		else {
			return
		}
		
		if !loading {refreshControl.endRefreshing()}
		else        {refreshControl.beginRefreshing()}
	}
	
}
