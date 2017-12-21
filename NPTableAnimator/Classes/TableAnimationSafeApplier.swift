//
// Created by Пацков Н.Д. on 18/12/2017.
//

import Foundation
import Dispatch
import UIKit





class SafeApplier {

	private static var applierStorage: [ObjectIdentifier: SafeApplier] = [:]

	static func get(for associatedTable: AnyObject) -> SafeApplier {
		let objectID = ObjectIdentifier(associatedTable)

		if let applier = applierStorage[objectID] {
			return applier
		} else {
			let applier = SafeApplier(associatedTable: associatedTable)
			applierStorage[objectID] = applier
			return applier
		}
	}


	let applyQueue: OperationQueue
	let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
	let objectID: ObjectIdentifier

	weak var associatedTable: AnyObject? {
		didSet {
			if associatedTable == nil {
				let objectID = self.objectID
				DispatchQueue.main.async {
					SafeApplier.applierStorage.removeValue(forKey: objectID)
				}
			}
		}
	}

	init(associatedTable: AnyObject) {
		self.objectID = ObjectIdentifier(associatedTable)
		self.associatedTable = associatedTable
		self.applyQueue = OperationQueue()
		self.applyQueue.qualityOfService = .userInteractive
		applyQueue.maxConcurrentOperationCount = 1
	}


	func apply(hasDeferredAnimations: Bool, mainPerform: @escaping (DispatchSemaphore) -> Bool, deferredPerform: @escaping (DispatchSemaphore) -> Void, cancelBlock: (() -> Void)?) {

		let semaphore = self.semaphore

		func silence(_ obj: AnyObject) {}
		
//		applyQueue.cancelAllOperations()
		
		let operation = UpdateTableOperation(cancelBlock: cancelBlock)
		operation.addExecutionBlock {
			guard let table = self.associatedTable else { return }
			silence(table)
			
			var didSetNewList = false
			
			var didStartAnimations = false
			
			DispatchQueue.main.sync {
				if let table = self.associatedTable {
					silence(table)
					didStartAnimations = true
					didSetNewList = mainPerform(semaphore)
				}
			}
			
			if didStartAnimations {
				_ = semaphore.wait(timeout: .now() + .seconds(1))
			}
			
			if hasDeferredAnimations && didSetNewList {
				didStartAnimations = false
				
				DispatchQueue.main.sync {
					if let table = self.associatedTable {
						silence(table)
						didStartAnimations = true
						deferredPerform(semaphore)
					}
				}
				
				if didStartAnimations {
					_ = semaphore.wait(timeout: .now() + .seconds(1))
				}
			}

		}
		
		self.applyQueue.addOperation(operation)
	}


}



private class UpdateTableOperation: BlockOperation {
	
	private let cancelBlock: (() -> Void)?
	
	init(cancelBlock: (() -> Void)?) {
		self.cancelBlock = cancelBlock
	}
	
	override func cancel() {
		super.cancel()
		cancelBlock?()
	}
	
}
