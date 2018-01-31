//
//  TableAnimationApplier.swift
//  NPTableAnimator
//
//  Created by Nikita Patskov on 14.11.17.
//


import Foundation


#if os(iOS)
	
	
	/// TableView rows animation style set.
	public struct UITableViewRowAnimationSet {
		let insert: UIKit.UITableViewRowAnimation
		let delete: UIKit.UITableViewRowAnimation
		let reload: UIKit.UITableViewRowAnimation
		public init(insert anInsert: UIKit.UITableViewRowAnimation, delete aDelete: UIKit.UITableViewRowAnimation, reload aReload: UIKit.UITableViewRowAnimation) {
			self.insert = anInsert
			self.delete = aDelete
			self.reload = aReload
		}
	}
	
	extension UIKit.UITableView {
		
		
		
		/// Use this for applying changes for UITableView.
		///
		/// - Parameters:
		///   - newList: New list that should be presented in collection view.
		///   - getCurrentListBlock: Block for getting current screen list. Called from main thread.
		///   - calculateChanges: Block for getting changes. Called from **background** serialized queue. You can get that queue by call *tableView.getApplyQueue()*.
		///   - from: Initial list, which we got from *getCurrentListBlock()*.
		///   - to: New list to set, which you pass in *newList*.
		///   - setNewListBlock: Block for changing current screen list to passed *newList*. Called from main thread.
		///   - rowAnimations: Specific UITableViewRowAnimations that will be passed in all animation type during applying.
		///   - completion: Block for capturing animation completion. Called from main thread.
		///   - error: Block for capturing error during changes calculation. When we got error in changes, we call *setNewListBlock* and *tableView.reloadData()*, then error block called
		///   - tableError: TableAnimatorError
		public func apply<T>(newList: [T], getCurrentListBlock: @escaping () -> [T]?, calculateChanges: @escaping (_ from: [T], _ to: [T]) throws -> TableAnimations?, setNewListBlock: @escaping (_ newList: [T]) -> Bool, rowAnimations: UITableViewRowAnimationSet, completion: (() -> Void)?, error: @escaping (_ tableError: Error) -> Void) {
			
			let setAnimationsClosure: (UITableView, TableAnimations) -> Void = { table, animations in
				table.insertSections(animations.sections.toInsert, with: rowAnimations.insert)
				table.deleteSections(animations.sections.toDelete, with: rowAnimations.delete)
				table.reloadSections(animations.sections.toUpdate, with: rowAnimations.reload)
				
				for (from, to) in animations.sections.toMove {
					table.moveSection(from, toSection: to)
				}
				
				table.insertRows(at: animations.cells.toInsert, with: rowAnimations.insert)
				table.deleteRows(at: animations.cells.toDelete, with: rowAnimations.delete)
				table.reloadRows(at: animations.cells.toUpdate, with: rowAnimations.reload)
				
				for (from, to) in animations.cells.toMove {
					table.moveRow(at: from, to: to)
				}
			}
			
			let safeApplyClosure: (DispatchSemaphore, TableAnimations) -> Bool = { [weak self] semaphore, animations in
				// If dataSource died, tableView.endUpdates() will throw fatal error.
				guard let strong = self, let dataSource = strong.dataSource else {
					return false
				}
				silence(obj: dataSource)
				
				var didSetNewList = false
				
				if #available(iOS 11, *) {
					
					strong.performBatchUpdates({
						didSetNewList = setNewListBlock(newList)
						
						if didSetNewList {
							setAnimationsClosure(strong, animations)
						}
						
					}, completion: { _ in
						
						if animations.cells.toDeferredUpdate.isEmpty || !didSetNewList {
							completion?()
						}
						
						semaphore.signal()
					})
					
				} else {
					CATransaction.begin()
					strong.beginUpdates()
					
					didSetNewList = setNewListBlock(newList)
					
					CATransaction.setCompletionBlock {
						if animations.cells.toDeferredUpdate.isEmpty || !didSetNewList {
							completion?()
						}
						
						semaphore.signal()
					}
					
					setAnimationsClosure(strong, animations)
					
					strong.endUpdates()
					CATransaction.commit()
				}
				
				return didSetNewList
			}
			
			
			let safeDeferredApplyClosure: (DispatchSemaphore, [IndexPath]) -> Void = { [weak self] semaphore, toDeferredUpdate in
				// If dataSource died, tableView.endUpdates() will throw fatal error.
				guard let strong = self, let dataSource = strong.dataSource else {
					return
				}
				silence(obj: dataSource)
				
				if #available(iOS 11, *) {
					strong.performBatchUpdates({
						strong.reloadRows(at: toDeferredUpdate, with: rowAnimations.reload)
					}, completion: { _ in
						completion?()
						semaphore.signal()
					})
					
				} else {
					CATransaction.begin()
					CATransaction.setCompletionBlock {
						completion?()
						semaphore.signal()
					}
					
					strong.beginUpdates()
					strong.reloadRows(at: toDeferredUpdate, with: rowAnimations.reload)
					strong.endUpdates()
					
					CATransaction.commit()
				}
				
			}
			
			
			let onAnimationsError: (Error) -> Void = { [weak self] anError in
				_ = setNewListBlock(newList)
				self?.reloadData()
				
				error(anError)
			}
			
			
			SafeApplier.get(for: self).apply(newList: newList,
								   getCurrentListBlock: getCurrentListBlock,
								   calculateChanges: calculateChanges,
								   mainPerform: safeApplyClosure,
								   deferredPerform: safeDeferredApplyClosure,
								   onAnimationsError: onAnimationsError)
			
		}
		
		
		/// Use this for applying changes for UITableView.
		///
		/// - Parameters:
		///   - newList: New list that should be presented in collection view.
		///   - getCurrentListBlock: Block for getting current screen list. Called from main thread.
		///   - calculateChanges: Block for getting changes. Called from **background** serialized queue. You can get that queue by call *tableView.getApplyQueue()*.
		///   - from: Initial list, which we got from *getCurrentListBlock()*.
		///   - to: New list to set, which you pass in *newList*.
		///   - setNewListBlock: Block for changing current screen list to passed *newList*. Called from main thread.
		///   - rowAnimation: UITableViewRowAnimation that will be passed in all animation type during applying.
		///   - completion: Block for capturing animation completion. Called from main thread.
		///   - error: Block for capturing error during changes calculation. When we got error in changes, we call *setNewListBlock* and *tableView.reloadData()*, then error block called
		///   - tableError: TableAnimatorError
		public func apply<T>(newList: [T], getCurrentListBlock: @escaping () -> [T]?, calculateChanges: @escaping (_ from: [T], _ to: [T]) throws -> TableAnimations?, setNewListBlock: @escaping (_ newList: [T]) -> Bool, rowAnimation: UIKit.UITableViewRowAnimation, completion: (() -> Void)?, error: @escaping (_ tableError: Error) -> Void) {
			
			let animationSet = UITableViewRowAnimationSet(insert: rowAnimation, delete: rowAnimation, reload: rowAnimation)
			self.apply(newList: newList, getCurrentListBlock: getCurrentListBlock, calculateChanges: calculateChanges, setNewListBlock: setNewListBlock, rowAnimations: animationSet, completion: completion, error: error)
		}
		
		
		/// Use this function when you need synchronize something with serialized animation queue.
		///
		/// - Returns: Queue that used for animations synchronizing.
		public func getApplyQueue() -> OperationQueue {
			return SafeApplier.get(for: self).applyQueue
		}
		
		
		/// User this when you want to provide your own operation queue for animations serializing.
		/// - Note: You **had to** use serialized queue!
		///
		/// - Parameter operationQueue: Operation queue that will be used for animatino synchronizing.
		/// - Returns: *true* if queue was successfully set, *false* if table already have queue for animations.
		public func provideApplyQueue(_ operationQueue: OperationQueue) -> Bool {
			return SafeApplier.prepare(for: self, operationQueue: operationQueue)
		}
		
		
		
		
		/// Use this for applying changes for UITableView.
		///
		/// - Note: If you have no interactive updates, you may mark InteractiveUpdate type as Void and pass nil to applyAnimationsToCell closure.
		/// - Note: Owner of screen list in *setNewListBlock* should be weakly referenced!
		/// - Parameters:
		///   - animations: Changes, calculated by **TableAnimator**
		///   - setNewListBlock: You should provide block, where you doing something like 'myItems = newItems'
		///   - applyAnimationsToCell: If you have interactive updates, pass this closure for apply interactive animations for cells.
		///   - completion: Completion block, that will be called when animation end.
		///   - cancelBlock: Called if list change was cancelled (You ask next apply before previous apply ended)
		///   - rowAnimations: UITableView animations style for insert, delete and reload
		public func apply(animations: TableAnimations, setNewListBlock: @escaping () -> Bool, completion: (() -> Void)?, cancelBlock: (() -> Void)?, rowAnimations: UITableViewRowAnimationSet) {
			
			guard !animations.cells.isEmpty || !animations.sections.isEmpty else {
				cancelBlock?()
				return
			}
			
			let setAnimationsClosure: (UITableView) -> Void = { table in
				table.insertSections(animations.sections.toInsert, with: rowAnimations.insert)
				table.deleteSections(animations.sections.toDelete, with: rowAnimations.delete)
				table.reloadSections(animations.sections.toUpdate, with: rowAnimations.reload)
				
				for (from, to) in animations.sections.toMove {
					table.moveSection(from, toSection: to)
				}
				
				table.insertRows(at: animations.cells.toInsert, with: rowAnimations.insert)
				table.deleteRows(at: animations.cells.toDelete, with: rowAnimations.delete)
				table.reloadRows(at: animations.cells.toUpdate, with: rowAnimations.reload)
				
				for (from, to) in animations.cells.toMove {
					table.moveRow(at: from, to: to)
				}
			}
			
			if self.dataSource == nil {
				fatalError("UITableView is alive, but its data source are dead! That should never happen! Look closer at your memory management.")
			}
			
			var didSetNewList = false
			
			if #available(iOS 11, *) {
				self.performBatchUpdates({
					didSetNewList = setNewListBlock()
					
					if didSetNewList {
						setAnimationsClosure(self)
					}
					
				}, completion: { _ in
					
					if animations.cells.toDeferredUpdate.isEmpty || !didSetNewList {
						completion?()
					}
				})
				
			} else {
				CATransaction.begin()
				self.beginUpdates()
				
				didSetNewList = setNewListBlock()
				
				CATransaction.setCompletionBlock {
					if animations.cells.toDeferredUpdate.isEmpty || !didSetNewList {
						completion?()
					}
				}
				
				setAnimationsClosure(self)
				
				self.endUpdates()
				CATransaction.commit()
			}
			
			if #available(iOS 11, *) {
				self.performBatchUpdates({
					self.reloadRows(at: animations.cells.toDeferredUpdate, with: rowAnimations.reload)
				}, completion: { _ in
					completion?()
				})
				
			} else {
				CATransaction.begin()
				CATransaction.setCompletionBlock {
					completion?()
				}
				
				self.beginUpdates()
				self.reloadRows(at: animations.cells.toDeferredUpdate, with: rowAnimations.reload)
				self.endUpdates()
				
				CATransaction.commit()
			}
		}
		
		
		/// Use this for applying changes for UITableView.
		///
		/// - Note: If you have no interactive updates, you may mark InteractiveUpdate type as Void and pass nil to applyAnimationsToCell closure.
		/// - Note: Owner of screen list in *setNewListBlock* should be weakly referenced!
		/// - Parameters:
		///   - animations: Changes, calculated by **TableAnimator**
		///   - setNewListBlock: You should provide block, where you doing something like 'myItems = newItems'
		///   - applyAnimationsToCell: If you have interactive updates, pass this closure for apply interactive animations for cells.
		///   - completion: Completion block, that will be called when animation end
		///   - cancelBlock: Called if list change was cancelled (You ask next apply before previous apply ended)
		///   - rowAnimation: UITableView animations style for all animations like insert, delete and reload
		public func apply(animations: TableAnimations, setNewListBlock: @escaping () -> Bool, completion: (() -> Void)?, cancelBlock: (() -> Void)?, rowAnimation: UITableViewRowAnimation) {
			self.apply(animations: animations, setNewListBlock: setNewListBlock, completion: completion, cancelBlock: cancelBlock, rowAnimations: UITableViewRowAnimationSet(insert: rowAnimation, delete: rowAnimation, reload: rowAnimation))
		}
		
	}
	
	
	
	extension UIKit.UICollectionView {
		
		
		
		/// Use this for applying changes for UICollectionView.
		///
		/// - Parameters:
		///   - newList: New list that should be presented in collection view.
		///   - getCurrentListBlock: Block for getting current screen list. Called from main thread.
		///   - calculateChanges: Block for getting changes. Called from **background** serialized queue. You can get that queue by call *collectionView.getApplyQueue()*.
		///   - from: Initial list, which we got from *getCurrentListBlock()*.
		///   - to: New list to set, which you pass in *newList*.
		///   - setNewListBlock: Block for changing current screen list to passed *newList*. Called from main thread.
		///   - completion: Block for capturing animation completion. Called from main thread.
		///   - error: Block for capturing error during changes calculation. When we got error in changes, we call *setNewListBlock* and *collectionView.reloadData()*, then error block called
		///   - tableError: TableAnimatorError
		public func apply<T>(newList: [T], getCurrentListBlock: @escaping () -> [T]?, calculateChanges: @escaping (_ from: [T], _ to: [T]) throws -> TableAnimations?, setNewListBlock: @escaping (_ newList: [T]) -> Bool, completion: (() -> Void)?, error: @escaping (_ tableError: Error) -> Void) {
			
			
			let safeApplyClosure: (DispatchSemaphore, TableAnimations) -> Bool = { [weak self] semaphore, animations in
				// If dataSource died, tableView.endUpdates() will throw fatal error.
				guard let strong = self, let dataSource = strong.dataSource else {
					return false
				}
				silence(obj: dataSource)
				
				var didSetNewList = false
				
				strong.performBatchUpdates({
					didSetNewList = setNewListBlock(newList)
					
					if didSetNewList {
						strong.insertSections(animations.sections.toInsert)
						strong.deleteSections(animations.sections.toDelete)
						strong.reloadSections(animations.sections.toUpdate)
						
						for (from, to) in animations.sections.toMove {
							strong.moveSection(from, toSection: to)
						}
						
						strong.insertItems(at: animations.cells.toInsert)
						strong.deleteItems(at: animations.cells.toDelete)
						strong.reloadItems(at: animations.cells.toUpdate)
						
						for (from, to) in animations.cells.toMove {
							strong.moveItem(at: from, to: to)
						}
					}
					
				}, completion: { _ in
					if animations.cells.toDeferredUpdate.isEmpty || !didSetNewList {
						completion?()
					}
					
					semaphore.signal()
				})
				
				return didSetNewList
			}
			
			
			let safeDeferredApplyClosure: (DispatchSemaphore, [IndexPath]) -> Void = { [weak self] semaphore, toDeferredUpdate in
				// If dataSource died, tableView.endUpdates() will throw fatal error.
				guard let strong = self, let dataSource = strong.dataSource else {
					return
				}
				silence(obj: dataSource)
				
				strong.performBatchUpdates({
					strong.reloadItems(at: toDeferredUpdate)
				}, completion: { _ in
					completion?()
					semaphore.signal()
				})
				
			}
			
			
			let onAnimationsError: (Error) -> Void = { [weak self] anError in
				_ = setNewListBlock(newList)
				self?.reloadData()
				
				if let strong = self, strong.dataSource == nil {
					fatalError("UITableView is alive, but its data source are dead! That should never happen! Look closer at your memory management.")
				}
				
				error(anError)
			}
			
			
			SafeApplier.get(for: self).apply(newList: newList,
								   getCurrentListBlock: getCurrentListBlock,
								   calculateChanges: calculateChanges,
								   mainPerform: safeApplyClosure,
								   deferredPerform: safeDeferredApplyClosure,
								   onAnimationsError: onAnimationsError)
			
		}
		
		
		/// Use this when you need synchronize something with serialized animation queue.
		///
		/// - Returns: Queue that used for animations synchronizing.
		public func getApplyQueue() -> OperationQueue {
			return SafeApplier.get(for: self).applyQueue
		}
		
		
		/// User this when you want to provide your own operation queue for animations serializing.
		/// - Note: You **had to** use serialized queue!
		///
		/// - Parameter operationQueue: Operation queue that will be used for animatino synchronizing.
		/// - Returns: *true* if queue was successfully set, *false* if table already have queue for animations.
		public func provideApplyQueue(_ operationQueue: OperationQueue) -> Bool {
			return SafeApplier.prepare(for: self, operationQueue: operationQueue)
		}
		
		
		
		/// Use this for applying changes for UICollectionView.
		///
		/// - Note: If you have no interactive updates, you may mark InteractiveUpdate type as Void and pass nil to applyAnimationsToCell closure.
		/// - Note: Owner of screen list in *setNewListBlock* should be weakly referenced!
		/// - Parameters:
		///   - animations: Changes, calculated by **TableAnimator**
		///   - setNewListBlock: You should provide block, where you doing something like 'myItems = newItems'
		///   - applyAnimationsToCell: If you have interactive updates, pass this closure for apply interactive animations for cells.
		///   - completion: Completion block, that will be called when animation end.
		///   - cancelBlock: Called if list change was cancelled (You ask next apply before previous apply ended)
		public func apply(animations: TableAnimations, setNewListBlock: @escaping () -> Bool, completion: (() -> Void)?, cancelBlock: (() -> Void)?) {
			
			guard (!animations.cells.isEmpty || !animations.sections.isEmpty) && dataSource != nil else {
				cancelBlock?()
				return
			}
			
			var didSetNewList = false
			
			self.performBatchUpdates({
				didSetNewList = setNewListBlock()
				
				if didSetNewList {
					self.insertSections(animations.sections.toInsert)
					self.deleteSections(animations.sections.toDelete)
					self.reloadSections(animations.sections.toUpdate)
					
					for (from, to) in animations.sections.toMove {
						self.moveSection(from, toSection: to)
					}
					
					self.insertItems(at: animations.cells.toInsert)
					self.deleteItems(at: animations.cells.toDelete)
					self.reloadItems(at: animations.cells.toUpdate)
					
					for (from, to) in animations.cells.toMove {
						self.moveItem(at: from, to: to)
					}
				}
				
			}, completion: { _ in
				if animations.cells.toDeferredUpdate.isEmpty || !didSetNewList {
					completion?()
				}
			})
			
			self.performBatchUpdates({
				self.reloadItems(at: animations.cells.toDeferredUpdate)
			}, completion: { _ in
				completion?()
			})
		}
		
	}
	
	// For warnings disable
	func silence(obj: AnyObject) {}
	
	
#endif



