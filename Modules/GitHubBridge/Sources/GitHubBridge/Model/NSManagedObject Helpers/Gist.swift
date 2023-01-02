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



@objc(Gist)
public class Gist : NSManagedObject {
	
	private static let subPropertyObservationInfos: [SubPropertyObservingInfo<Gist>] = [
		SubPropertyObservingInfo(
			observedKeyPaths: [
				#keyPath(Gist.files)
			],
			action: { strongSelf in
				/* The list of files changed. Let’s observe the first one to have an up-to-date firstFileName. */
				let firstFile = strongSelf.files?.firstObject as! File?
				guard firstFile != strongSelf.observedFile else {return}
				
				strongSelf.observingIDForFirstFile.map{ strongSelf.kvObserver.stopObserving(id: $0) }
				
				strongSelf.observedFile = firstFile
				strongSelf.observingIDForFirstFile = firstFile.flatMap{
					strongSelf.kvObserver.observe(object: $0, keyPath: #keyPath(File.filename), kvoOptions: [.initial, .new], dispatchType: .direct, handler: { [weak self = strongSelf] change in
						self?.firstFileName = change?[.newKey] as? String
					})
				}
			}
		)
	]
	
	/* ***************************
	   MARK: - Core Data Overrides
	   *************************** */
	
	public override func awakeFromFetch() {
		/* This is also called when a fault is fulfilled (fulfilling a fault is a fetch).
		 * Always DO call super's implementation *first*.
		 *
		 * Context's changes processing is disabled in this method.
		 * This also means inverse relationship are not set automatically when relationships are modified in this method. */
		super.awakeFromFetch()
		
		for (idx, observationInfo) in Self.subPropertyObservationInfos.enumerated() {
			Self.observeKeyPathsIfNeeded(for: observationInfo, on: self, with: kvObserver, kvoOptions: [.initial], observingIDs: &automaticObservingIDs[idx])
		}
	}
	
	public override func awakeFromInsert() {
		/* Use primitive accessors to change properties values in this method.
		 * Always DO call super's implementation first. */
		super.awakeFromInsert()
		
		for (idx, observationInfo) in Self.subPropertyObservationInfos.enumerated() {
			Self.observeKeyPathsIfNeeded(for: observationInfo, on: self, with: kvObserver, kvoOptions: [], observingIDs: &automaticObservingIDs[idx])
		}
	}
	
	public override func willTurnIntoFault() {
		for idx in 0..<automaticObservingIDs.count {
			kvObserver.stopObserving(ids: automaticObservingIDs[idx])
			automaticObservingIDs[idx].removeAll(keepingCapacity: true)
		}
		
		observingIDForFirstFile.map{ kvObserver.stopObserving(id: $0) }
		observingIDForFirstFile = nil
		
		super.willTurnIntoFault()
	}
	
	/* ***************
	   MARK: - Private
	   *************** */
	
	let kvObserver = KVObserver()
	private var automaticObservingIDs = Array(
		repeating: Set<KVObserver.ObservingId>(),
		count: Gist.subPropertyObservationInfos.count
	)
	
	private var observedFile: File?
	private var observingIDForFirstFile: KVObserver.ObservingId?
	
}
