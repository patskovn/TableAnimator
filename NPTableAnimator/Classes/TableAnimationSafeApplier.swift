//
// Created by Пацков Н.Д. on 18/12/2017.
//

import Foundation
import Dispatch



class SafeApplier {
	
	
	let applyQueue: OperationQueue
	private let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
	
	weak var associatedTable: AnyObject?
	
	
	convenience init(associatedTable: AnyObject) {
		let applyQueue = OperationQueue()
		
		self.init(associatedTable: associatedTable, operationQueue: applyQueue)
	}
	
	
	init(associatedTable: AnyObject, operationQueue: OperationQueue) {
		self.associatedTable = associatedTable
		self.applyQueue = operationQueue
		
		self.applyQueue.qualityOfService = .userInteractive
		self.applyQueue.maxConcurrentOperationCount = 1
	}
	
	
	func apply<T>(newList: [T], animator: TableAnimator<T>, getCurrentListBlock: @escaping () -> [T]?, mainPerform: @escaping (DispatchSemaphore, TableAnimations) -> Bool, deferredPerform: @escaping (DispatchSemaphore, [IndexPath]) -> Void, onAnimationsError: @escaping (Error) -> Void) {
		
		func silence(obj: AnyObject) {}
		
		let semaphore = self.semaphore
		
		let operation = BlockOperation()
		
		// Synchronize animations. We cant use semaphores on main thread, so we waiting for animations completion in specific serialized queue
		operation.addExecutionBlock { [weak self] in
			
			guard let strong = self, strong.associatedTable != nil else {
				return
			}
			
			guard let currentList = DispatchQueue.main.sync(execute: getCurrentListBlock) else { return }
			
			do {
				let animations = try animator.buildAnimations(from: currentList, to: newList)
				
				var didSetNewList = false
				
				var didStartAnimations = false
				DispatchQueue.main.sync {
					if let table = strong.associatedTable {
						silence(obj: table)
						didStartAnimations = true
						didSetNewList = mainPerform(semaphore, animations)
					}
				}
				
				if didStartAnimations {
					_ = semaphore.wait()
				}
				
				if !animations.cells.toDeferredUpdate.isEmpty && didSetNewList {
					didStartAnimations = false
					
					DispatchQueue.main.sync {
						if let table = strong.associatedTable {
							silence(obj: table)
							didStartAnimations = true
							deferredPerform(semaphore, animations.cells.toDeferredUpdate)
						}
					}
					
					if didStartAnimations {
						_ = semaphore.wait()
					}
				}
				
			} catch {
				DispatchQueue.main.sync {
					onAnimationsError(error)
				}
			}
		}
		
		self.applyQueue.addOperation(operation)
	}

	

}



