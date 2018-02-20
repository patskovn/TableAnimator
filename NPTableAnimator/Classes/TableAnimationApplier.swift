//
//  TableAnimationApplier.swift
//  NPTableAnimator
//
//  Created by Nikita Patskov on 14.11.17.
//


import Foundation


#if os(iOS)
	
	
	private var tableAssociatedObjectHandle: UInt8 = 0
	private var collectionAssociatedObjectHandle: UInt8 = 0
	private let monitor = NSObject()
	
	
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
		
		
		var safeApplier: SafeApplier {
			get {
				objc_sync_enter(monitor)
				defer { objc_sync_exit(monitor) }
				
				if let applier = objc_getAssociatedObject(self, &tableAssociatedObjectHandle) as? SafeApplier {
					return applier
				} else {
					let applier = SafeApplier(associatedTable: self)
					objc_setAssociatedObject(self, &tableAssociatedObjectHandle, applier, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
					return applier
				}
			}
			
			set {
				objc_sync_enter(monitor)
				defer { objc_sync_exit(monitor) }
				objc_setAssociatedObject(self, &tableAssociatedObjectHandle, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
			}
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
		///   - rowAnimations: Specific UITableViewRowAnimations that will be passed in all animation type during applying.
		///   - completion: Block for capturing animation completion. Called from main thread.
		///   - error: Block for capturing error during changes calculation. When we got error in changes, we call *setNewListBlock* and *tableView.reloadData()*, then error block called
		///   - tableError: TableAnimatorError
		public func apply<T>(newList: [T], animator: TableAnimator<T>, getCurrentListBlock: @escaping () -> [T]?, setNewListBlock: @escaping (_ newList: [T]) -> Bool, rowAnimations: UITableViewRowAnimationSet, completion: (() -> Void)?, error: @escaping (_ tableError: Error) -> Void) {
			
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
				guard let strong = self, strong.dataSource != nil else {
					return false
				}
				
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
				guard let strong = self, strong.dataSource != nil else {
					return
				}
				
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
			
			
			safeApplier.apply(newList: newList,
						animator: animator,
						getCurrentListBlock: getCurrentListBlock,
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
		public func apply<T>(newList: [T], animator: TableAnimator<T>, getCurrentListBlock: @escaping () -> [T]?, setNewListBlock: @escaping (_ newList: [T]) -> Bool, rowAnimation: UIKit.UITableViewRowAnimation, completion: (() -> Void)?, error: @escaping (_ tableError: Error) -> Void) {
			
			let animationSet = UITableViewRowAnimationSet(insert: rowAnimation, delete: rowAnimation, reload: rowAnimation)
			self.apply(newList: newList, animator: animator, getCurrentListBlock: getCurrentListBlock, setNewListBlock: setNewListBlock, rowAnimations: animationSet, completion: completion, error: error)
		}
		
		
		/// Use this function when you need synchronize something with serialized animation queue.
		///
		/// - Returns: Queue that used for animations synchronizing.
		public func getApplyQueue() -> OperationQueue {
			return safeApplier.applyQueue
		}
		
		
		/// User this when you want to provide your own operation queue for animations serializing.
		/// - Note: You **had to** use serialized queue!
		///
		/// - Parameter operationQueue: Operation queue that will be used for animatino synchronizing.
		/// - Returns: *true* if queue was successfully set, *false* if table already have queue for animations.
		public func provideApplyQueue(_ operationQueue: OperationQueue) -> Bool {
			objc_sync_enter(monitor)
			defer { objc_sync_exit(monitor) }
			
			if (objc_getAssociatedObject(self, &tableAssociatedObjectHandle) as? SafeApplier) != nil {
				return false
			} else {
				let applier = SafeApplier(associatedTable: self, operationQueue: operationQueue)
				objc_setAssociatedObject(self, &tableAssociatedObjectHandle, applier, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
				return true
			}
		}
		
		
		
		
	}
	
	
	
	extension UIKit.UICollectionView {
		
		var safeApplier: SafeApplier {
			get {
				objc_sync_enter(monitor)
				defer { objc_sync_exit(monitor) }
				
				if let applier = objc_getAssociatedObject(self, &collectionAssociatedObjectHandle) as? SafeApplier {
					return applier
				} else {
					let applier = SafeApplier(associatedTable: self)
					objc_setAssociatedObject(self, &collectionAssociatedObjectHandle, applier, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
					return applier
				}
			}
			
			set {
				objc_sync_enter(monitor)
				defer { objc_sync_exit(monitor) }
				objc_setAssociatedObject(self, &collectionAssociatedObjectHandle, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
			}
		}
		
		
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
		public func apply<T>(newList: [T], animator: TableAnimator<T>, getCurrentListBlock: @escaping () -> [T]?, setNewListBlock: @escaping (_ newList: [T]) -> Bool, completion: (() -> Void)?, error: @escaping (_ tableError: Error) -> Void) {
			
			
			let safeApplyClosure: (DispatchSemaphore, TableAnimations) -> Bool = { [weak self] semaphore, animations in
				guard let strong = self, strong.dataSource != nil else {
					return false
				}
				
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
				guard let strong = self, strong.dataSource != nil else {
					return
				}
				
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
					return
				}
				
				error(anError)
			}
			
			
			safeApplier.apply(newList: newList,
						animator: animator,
						getCurrentListBlock: getCurrentListBlock,
						mainPerform: safeApplyClosure,
						deferredPerform: safeDeferredApplyClosure,
						onAnimationsError: onAnimationsError)
		}
		
		
		/// Use this when you need synchronize something with serialized animation queue.
		///
		/// - Returns: Queue that used for animations synchronizing.
		public func getApplyQueue() -> OperationQueue {
			return safeApplier.applyQueue
		}
		
		
		/// User this when you want to provide your own operation queue for animations serializing.
		/// - Note: You **had to** use serialized queue!
		///
		/// - Parameter operationQueue: Operation queue that will be used for animatino synchronizing.
		/// - Returns: *true* if queue was successfully set, *false* if table already have queue for animations.
		public func provideApplyQueue(_ operationQueue: OperationQueue) -> Bool {
			objc_sync_enter(monitor)
			defer { objc_sync_exit(monitor) }
			
			if (objc_getAssociatedObject(self, &tableAssociatedObjectHandle) as? SafeApplier) != nil {
				return false
			} else {
				let applier = SafeApplier(associatedTable: self, operationQueue: operationQueue)
				objc_setAssociatedObject(self, &tableAssociatedObjectHandle, applier, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
				return true
			}
		}
	}
		
		
#endif



