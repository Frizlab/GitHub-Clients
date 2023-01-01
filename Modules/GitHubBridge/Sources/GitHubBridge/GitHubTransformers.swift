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



class IntToStringTransformer : ValueTransformer {
	
	override public class func allowsReverseTransformation() -> Bool {
		return false
	}
	
	override public class func transformedValueClass() -> AnyClass {
		return NSString.self
	}
	
	override func transformedValue(_ value: Any?) -> Any? {
		return (value as? Int).flatMap{ String($0) }
	}
	
}


class FilesTransformer : ValueTransformer {
	
	override public class func allowsReverseTransformation() -> Bool {
		return false
	}
	
	override public class func transformedValueClass() -> AnyClass {
		return NSArray.self
	}
	
	override func transformedValue(_ value: Any?) -> Any? {
		guard let value  = value          as? [String: Any?]           else {return nil}
		guard let gistID = value["id"]    as? String                   else {return nil}
		guard let files  = value["files"] as? [String: [String: Any?]] else {return nil}
		
		var ret = [[String: Any?]]()
		for (filename, var fileinfo) in files {
			fileinfo["id"] = gistID + " - " + filename
			fileinfo["filename"] = filename
			ret.append(fileinfo)
		}
		return ret
	}
	
}


class TopicsTransformer : ValueTransformer {
	
	override public class func allowsReverseTransformation() -> Bool {
		return false
	}
	
	override public class func transformedValueClass() -> AnyClass {
		return NSArray.self
	}
	
	override func transformedValue(_ value: Any?) -> Any? {
		return (value as? [String])?.map{ ["name": $0] }
	}
	
}
