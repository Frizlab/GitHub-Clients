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
//	private(set) var requestManager: RequestManager!
	private(set) var bridge: GitHubBridge!
	private(set) var localDb: GitHubLocalDb!
	private(set) var pageInfoRetriever: GitHubPageInfoRetriever!
	
	private(set) var myUsername: String?
	
	private(set) var tabBarController: UITabBarController!
	
	var window: UIWindow?
	
	override init() {
		super.init()
		
		assert(AppDelegate.shared == nil)
		AppDelegate.shared = self
	}
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		let container = NSPersistentContainer(name: "GitHub", managedObjectModel: GitHubBridge.coreDataModel)
		container.loadPersistentStores(completionHandler: { _, _ in })
		context = container.viewContext
		
//		requestManager = RequestManager(bridges: [GitHubBridge()], resultsImporterFactory: BMOBackResultsImporterForCoreDataWithFastImportRepresentationFactory())
		bridge = GitHubBridge()
		localDb = GitHubLocalDb(context: context)
		pageInfoRetriever = GitHubPageInfoRetriever()
		
		tabBarController = (window!.rootViewController! as! UITabBarController)
		
		/* Let's fetch the connected username (if any) and add the “you” tab if we get a result. */
		GitHubBMOOperation.retrieveUsernameFromToken{ username in
			self.myUsername = username
			guard let username = username else {return}
			
			DispatchQueue.main.async{
				var hasAddedController = false
				let addUserController = { (user: User?) -> Void in
					guard !hasAddedController, let user = user else {return}
					
					let youNavigationController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "YouNavigationViewController") as! UINavigationController
					let userViewController = youNavigationController.viewControllers.first! as! UserViewController
					userViewController.shouldRefreshUserOnLoad = false
					userViewController.title = "You"
					userViewController.user = user
					
					self.tabBarController.viewControllers?.append(youNavigationController)
					hasAddedController = true
				}
//				let (u, _) = self.requestManager.unsafeFetchObject(withRemoteId: username, remoteIdAttributeName: "username", onContext: self.context, handler: { (u: User?, _: Result<BridgeBackRequestResult<GitHubBridge>, Error>) in
//					addUserController(u)
//				})
//				addUserController(u)
			}
		}
		
		return true
	}
	
	func applicationWillResignActive(_ application: UIApplication) {
	}
	
	func applicationDidEnterBackground(_ application: UIApplication) {
	}
	
	func applicationWillEnterForeground(_ application: UIApplication) {
	}
	
	func applicationDidBecomeActive(_ application: UIApplication) {
	}
	
	func applicationWillTerminate(_ application: UIApplication) {
	}
	
}
