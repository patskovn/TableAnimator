//
// Created by Пацков Н.Д. on 18/12/2017.
//

import Foundation
import Dispatch



class SafeApplier {
	
	private static var applierStorage: [ObjectIdentifier: SafeApplier] = [:]
	
	static func get(for associatedTable: AnyObject) -> SafeApplier {
		applierStorage = applierStorage.filter({$1.associatedTable != nil})
		
		let objectID = ObjectIdentifier(associatedTable)
		
		if let applier = applierStorage[objectID] {
			return applier
		} else {
			let applier = SafeApplier(associatedTable: associatedTable)
			applierStorage[objectID] = applier
			return applier
		}
	}
	
	
	static func prepare(for associatedTable: AnyObject, operationQueue: OperationQueue) -> Bool {
		
		let objectID = ObjectIdentifier(associatedTable)
		
		if applierStorage[objectID] == nil {
			let applier = SafeApplier(associatedTable: associatedTable, operationQueue: operationQueue)
			applierStorage[objectID] = applier
			return true
		} else {
			return false
		}
	}
	
	
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
	
	
	func apply<T>(newList: [T], getCurrentListBlock: @escaping () -> [T]?, calculateChanges: @escaping (_ from: [T], _ to: [T]) throws -> TableAnimations?, mainPerform: @escaping (DispatchSemaphore, TableAnimations) -> Bool, deferredPerform: @escaping (DispatchSemaphore, [IndexPath]) -> Void, onAnimationsError: @escaping (Error) -> Void) {
		
		let semaphore = self.semaphore
		
		let operation = BlockOperation()
		
		// Synchronize animations. We cant use semaphores on main thread, so we waiting for animations completion in specific serialized queue
		operation.addExecutionBlock {
			guard let table = self.associatedTable else {
				return
			}
			silence(obj: table)
			var possibleCurrentList: [T]?
			
			DispatchQueue.main.sync {
				if let table = self.associatedTable {
					silence(obj: table)
					possibleCurrentList = getCurrentListBlock()
				}
			}
			
			guard let currentList = possibleCurrentList else { return }
			
			do {
				guard let animations = try calculateChanges(currentList, newList) else {
					return
				}
				
				var didSetNewList = false
				
				var didStartAnimations = false
				DispatchQueue.main.sync {
					if let table = self.associatedTable {
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
						if let table = self.associatedTable {
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



