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

import Foundation
import UIKit

import Alamofire
import GitHubBridge



class GistFileViewController : UIViewController {
	
	var file: File!
	
	@IBOutlet var textView: UITextView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let t = file.filename ?? "<unnamed>"
		title = nil; title = t
		
		guard let url = file.rawURL else {
			textView.text = "Loading Error…"
			return
		}
		
		AF.request(url).responseString{ response in
			self.textView.text = (try? response.result.get()) ?? "Loading Error…"
		}
	}
	
}
