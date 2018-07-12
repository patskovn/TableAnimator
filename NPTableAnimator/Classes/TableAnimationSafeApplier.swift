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
	
	
	func apply<T, O: AnyObject>(owner: O, newList: [T], options: ApplyAnimationOptions, animator: TableAnimator<T>, getCurrentListBlock: @escaping (O) -> [T], mainPerform: @escaping (O, DispatchSemaphore, TableAnimations) -> Void, deferredPerform: @escaping (O, DispatchSemaphore, [IndexPath]) -> Void, onAnimationsError: @escaping (O, Error) -> Void) {
		
		func silence(obj: AnyObject) {}
		
		let semaphore = self.semaphore
		
		let operation = BlockOperation()
		
		// Synchronize animations. We cant use semaphores on main thread, so we waiting for animations completion in specific serialized queue
		operation.addExecutionBlock { [weak self, weak owner] in
			
			guard let strong = self, owner != nil, strong.associatedTable != nil else {
				return
			}
			
			let privateGetCurrentListBlock: () -> [T]? = { [weak owner] in
				guard let strongO = owner else { return nil }
				return getCurrentListBlock(strongO)
			}
			
			guard let currentList = DispatchQueue.main.sync(execute: privateGetCurrentListBlock) else { return }
			
			do {
				let animations = try animator.buildAnimations(from: currentList, to: newList)
				
				var didStartAnimations = false
				DispatchQueue.main.sync { [weak owner] in
					if let table = strong.associatedTable, let strongO = owner {
						silence(obj: table)
						didStartAnimations = true
						mainPerform(strongO, semaphore, animations)
					}
				}
				
				if didStartAnimations {
					_ = semaphore.wait()
				}
				
				if !animations.cells.toDeferredUpdate.isEmpty && didStartAnimations {
					didStartAnimations = false
					
					DispatchQueue.main.sync { [weak owner] in
						if let table = strong.associatedTable, let strongO = owner {
							silence(obj: table)
							didStartAnimations = true
							deferredPerform(strongO, semaphore, animations.cells.toDeferredUpdate)
						}
					}
					
					if didStartAnimations {
						_ = semaphore.wait()
					}
				}
				
			} catch {
				DispatchQueue.main.sync { [weak owner] in
					guard let strongO = owner else { return }
					onAnimationsError(strongO, error)
				}
			}
		}
		
		self.applyQueue.addOperation(operation)
	}

	

}



