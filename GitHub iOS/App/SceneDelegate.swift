/*
Copyright 2023 happn

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
import GitHubBridge



class SceneDelegate : UIResponder, UIWindowSceneDelegate {
	
	var window: UIWindow?
	
	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		/* Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
		 * If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
		 * This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead). */
		guard let _ = (scene as? UIWindowScene) else {return}
		
		let tabBarController = (window!.rootViewController! as! UITabBarController)
		
		/* Let's fetch the connected username (if any) and add the “you” tab if we get a result. */
		GitHubBMOOperation.retrieveUsernameFromToken{ username in
			AppDelegate.shared.myUsername = username
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
					
					tabBarController.viewControllers?.append(youNavigationController)
					hasAddedController = true
				}
				let fRequest = User.fetchRequest()
				fRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(User.username), username)
				AppDelegate.shared.gitHubAPI.remoteFetch(fRequest as! NSFetchRequest<NSFetchRequestResult>, fetchType: .onlyIfNoLocalResults, handler: { _ in
					/* We’re on the main thread, our context is a view context, it’s ok to launch the fetch request like this. */
					let u = try? AppDelegate.shared.context.fetch(fRequest).first
					addUserController(u)
				})
				let u = try? AppDelegate.shared.context.fetch(fRequest).first
				addUserController(u)
			}
			
		}
	}
	
}
