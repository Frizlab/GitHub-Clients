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

import KVObserver



extension NSManagedObject {
	
	/** Returns true if the observation setup has been done (was needed because not already done). */
	@discardableResult
	static func observeKeyPathsIfNeeded<Observed : NSManagedObject>(for subPropertyObservationInfo: SubPropertyObservingInfo<Observed>, on observed: Observed, with kvObserver: KVObserver, kvoOptions: NSKeyValueObservingOptions = [], observingIDs: inout Set<KVObserver.ObservingId>) -> Bool {
		guard observingIDs.isEmpty else {
			return false
		}
		
		/* No need for weak self here because the block is not kept (and also, we do not use self…). */
		let observeKeyPath = { (_ keyPath: String) -> KVObserver.ObservingId in
			kvObserver.observe(object: observed, keyPath: keyPath, kvoOptions: kvoOptions, dispatchType: .direct, handler: { [weak observed] (_ changes: [NSKeyValueChangeKey: Any]?) in
				guard let observed else {return}
				assert(observed.faultingState == 0)
				subPropertyObservationInfo.action(observed)
			})
		}
		
		observingIDs = Set(subPropertyObservationInfo.observedKeyPaths.map(observeKeyPath))
		return true
	}
	
	struct SubPropertyObservingInfo<Object : NSManagedObject> {
		var observedKeyPaths: [String]
		var action: (_ strongSelf: Object) -> Void
	}
	
}
