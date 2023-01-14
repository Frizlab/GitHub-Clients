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
import os.log
import UIKit

import BMO
import BMOCoreData

import GitHubBridge



@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	
	static private(set) var shared: AppDelegate!
	
	private(set) var context: NSManagedObjectContext!
	private(set) var gitHubAPI: CoreDataAPI<GitHubBridge>!
	private(set) var pageInfoRetriever: GitHubPageInfoRetriever!
	
	var myUsername: String?
	
	override init() {
		super.init()
		
		assert(AppDelegate.shared == nil)
		AppDelegate.shared = self
	}
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		let container = NSPersistentContainer(name: "GitHub", managedObjectModel: GitHubBridge.coreDataModel)
		container.loadPersistentStores(completionHandler: { _, _ in })
		context = container.viewContext
		
		gitHubAPI = CoreDataAPI(
			bridge: GitHubBridge(), localDb: GitHubLocalDb(context: context),
			defaultSettings: .init(
				remoteOperationQueue: OperationQueue(), computeOperationQueue: OperationQueue(),
				remoteIDPropertyName: "bmoID", fetchRequestToBridgeRequest: { r, _ in .fetch(r) }
			),
			defaultRequestUserInfo: .init()
		)
		pageInfoRetriever = GitHubPageInfoRetriever()
		
		return true
	}
	
}
