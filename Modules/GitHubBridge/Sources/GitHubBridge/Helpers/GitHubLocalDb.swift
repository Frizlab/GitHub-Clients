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

import BMO
import BMOCoreData



public struct GitHubLocalDb : LocalDbProtocol {
	
	public typealias UniquingID = String
	public typealias SaveWorkflow = BMOCoreDataSaveRequestHelper<GitHubBridge.Metadata>.SaveWorkflow
	
	public typealias DbObject = NSManagedObject
	public enum DbRequest {
		
		case fetch(NSFetchRequest<NSFetchRequestResult>)
		case create(NSManagedObject, SaveWorkflow)
		case update(NSManagedObject, SaveWorkflow)
		case delete(NSManagedObject, SaveWorkflow)
		
	}
	
	public var context: NSManagedObjectContext
	
	public init(context: NSManagedObjectContext) {
		self.context = context
	}
	
}
