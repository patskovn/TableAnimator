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

#if swift(>=4.2)
	public typealias UITableViewRowAnimation = UITableView.RowAnimation
#endif
	
	/// TableView rows animation style set.
	public struct UITableViewRowAnimationSet {
		let insert: UITableViewRowAnimation
		let delete: UITableViewRowAnimation
		let reload: UITableViewRowAnimation
		
		public init(insert: UITableViewRowAnimation, delete: UITableViewRowAnimation, reload: UITableViewRowAnimation) {
			self.insert = insert
			self.delete = delete
			self.reload = reload
		}
	}
	
    extension UITableView: EmptyCheckableSequence {
		
        var isEmpty: Bool {
            let block: () -> Bool = {
                let numberOfSections = (self.dataSource?.numberOfSections?(in: self)) ?? 0
                let rowsCount: Int = (0 ..< numberOfSections)
                    .reduce(0) { $0 + (self.dataSource?.tableView(self, numberOfRowsInSection: $1) ?? 0) }
                return rowsCount == 0
            }
            
            if Thread.isMainThread {
                return block()
            } else {
                return DispatchQueue.main.sync(execute: block)
            }
        }
		
		/// Use this for applying changes for UITableView.
		///
		/// - Parameters:
		///   - owner: Apply moves to Operation queue, so you need to pass owner for capturing.
		///   - newList: New list that should be presented in collection view.
		///   - getCurrentListBlock: Block for getting current screen list. Called from main thread.
		///   - animator: Instance of TableAnimator for calculating changes.
		///   - animated: If you dont want to animate changes, just pass *false*, otherwise, pass *true*.
        ///   - options: Additional options for animations applying.
		///   - from: Initial list, which we got from *getCurrentListBlock()*.
		///   - to: New list to set, which you pass in *newList*.
		///   - setNewListBlock: Block for changing current screen list to passed *newList*. Called from main thread.
		///   - rowAnimations: Specific UITableViewRowAnimations that will be passed in all animation type during applying.
		///   - completion: Block for capturing animation completion. Called from main thread.
		///   - error: Block for capturing error during changes calculation. When we got error in changes, we call *setNewListBlock* and *tableView.reloadData()*, then error block called
		///   - tableError: TableAnimatorError
        public func apply<T, O: AnyObject>(owner: O, newList: [T], animator: TableAnimator<T>, animated: Bool, options: ApplyAnimationOptions = [], getCurrentListBlock: @escaping (_ owner: O) -> [T], setNewListBlock: @escaping ((owner: O, newList: [T])) -> Void, rowAnimations: UITableViewRowAnimationSet, completion: (() -> Void)?, error: ((_ tableError: Error) -> Void)?) {
			
            if options.contains(.cancelPreviousAddedOperations) {
                self.getApplyQueue().cancelAllOperations()
            }
            
            if options.contains(.withoutActuallyRefreshTable) {
                self.getApplyQueue().addOperation {
                    DispatchQueue.main.sync { [weak owner] in
                        guard let strongO = owner else { return }
                        setNewListBlock((strongO, newList))
                    }
                }
                return
                
            } else if !animated || (self.isEmpty && options.contains(.withoutAnimationForEmptyTable)) {
                self.getApplyQueue().addOperation {
                    DispatchQueue.main.sync { [weak owner, weak self] in
                        guard let strongO = owner, let strong = self else { return }
                        setNewListBlock((strongO, newList))
                        strong.reloadData()
						completion?()
                    }
                }
                return
            }
			
			let setAnimationsClosure: (UITableView, TableAnimations) -> Void = { table, animations in
                let animations = table.applyOptions(options: options, to: animations)
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
			
			let safeApplyClosure: (O, DispatchSemaphore, TableAnimations) -> Void = { [weak self] anOwner, semaphore, animations in
				guard let strong = self, strong.dataSource != nil else {
					return
				}
				
				if #available(iOS 11, *) {
					
					strong.performBatchUpdates({
						setNewListBlock((anOwner, newList))
						setAnimationsClosure(strong, animations)
						
					}, completion: { _ in
						if animations.cells.toDeferredUpdate.isEmpty {
							completion?()
						}
						
						semaphore.signal()
					})
					
				} else {
					strong.beginUpdates()
					
					setNewListBlock((anOwner, newList))
					setAnimationsClosure(strong, animations)
					
					strong.endUpdates()
                    if animations.cells.toDeferredUpdate.isEmpty {
                        completion?()
                    }
                    
                    semaphore.signal()
				}
			}
			
			
			let safeDeferredApplyClosure: (O, DispatchSemaphore, [IndexPath]) -> Void = { [weak self] _, semaphore, toDeferredUpdate in
				guard let strong = self, strong.dataSource != nil else {
					return
				}
                let toDeferredUpdate = strong.applyOptions(options: options, toDeferredUpdatePaths: toDeferredUpdate)
				
				if #available(iOS 11, *) {
					strong.performBatchUpdates({
						strong.reloadRows(at: toDeferredUpdate, with: rowAnimations.reload)
					}, completion: { _ in
						completion?()
						semaphore.signal()
					})
					
				} else {
					strong.beginUpdates()
					strong.reloadRows(at: toDeferredUpdate, with: rowAnimations.reload)
					strong.endUpdates()
                    completion?()
                    semaphore.signal()
				}
				
			}
			
			
			let onAnimationsError: (O, Error) -> Void = { [weak self] owner, anError in
				setNewListBlock((owner, newList))
				self?.reloadData()
				
				error?(anError)
			}
			
			safeApplier.apply(owner: owner,
							  newList: newList,
                              options: options,
							  animator: animator,
							  getCurrentListBlock: getCurrentListBlock,
							  mainPerform: safeApplyClosure,
							  deferredPerform: safeDeferredApplyClosure,
							  onAnimationsError: onAnimationsError)
		}
		
		
		/// Use this for applying changes for UITableView.
		///
		/// - Parameters:
		///   - owner: Apply moves to Operation queue, so you need to pass owner for capturing.
		///   - newList: New list that should be presented in collection view.
		///   - getCurrentListBlock: Block for getting current screen list. Called from main thread.
		///   - animator: Instance of TableAnimator for calculating changes.
		///   - animated: If you dont want to animate changes, just pass *false*, otherwise, pass *true*.
        ///   - options: Additional options for animations applying.
		///   - from: Initial list, which we got from *getCurrentListBlock()*.
		///   - to: New list to set, which you pass in *newList*.
		///   - setNewListBlock: Block for changing current screen list to passed *newList*. Called from main thread.
		///   - rowAnimation: UITableViewRowAnimation that will be passed in all animation type during applying.
		///   - completion: Block for capturing animation completion. Called from main thread.
		///   - error: Block for capturing error during changes calculation. When we got error in changes, we call *setNewListBlock* and *tableView.reloadData()*, then error block called
		///   - tableError: TableAnimatorError
		public func apply<T, O: AnyObject>(owner: O, newList: [T], animator: TableAnimator<T>, animated: Bool, options: ApplyAnimationOptions = [], getCurrentListBlock: @escaping (_ owner: O) -> [T], setNewListBlock: @escaping ((owner: O, newList: [T])) -> Void, rowAnimation: UITableViewRowAnimation, completion: (() -> Void)? = nil, error: ((_ tableError: Error) -> Void)? = nil) {
			
			let animationSet = UITableViewRowAnimationSet(insert: rowAnimation, delete: rowAnimation, reload: rowAnimation)
            self.apply(owner: owner, newList: newList, animator: animator, animated: animated, options: options, getCurrentListBlock: getCurrentListBlock, setNewListBlock: setNewListBlock, rowAnimations: animationSet, completion: completion, error: error)
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
		
		
        
        private var safeApplier: SafeApplier {
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
        
        
        private func applyOptions(options: ApplyAnimationOptions, to animations: (cells: CellsAnimations, sections: SectionsAnimations)) -> (cells: CellsAnimations, sections: SectionsAnimations) {
            var animations = animations
            
            if let visibleRows = self.indexPathsForVisibleRows,
                let firstResponderIndex = visibleRows.first(where: { self.cellForRow(at: $0)?.isActuallyResponder == true }) {
                
                
                if options.contains(.excludeFirstResponderCellFromReload) {
                    animations.cells.toUpdate = animations.cells.toUpdate.filter({ $0 != firstResponderIndex })
                }
                
                if options.contains(.excludeFirstResponderSectionFromReload) {
                    animations.sections.toUpdate.remove(firstResponderIndex.section)
                }
            }
            
            return animations
        }
        
        private func applyOptions(options: ApplyAnimationOptions, toDeferredUpdatePaths: [IndexPath]) -> [IndexPath] {
            
            if let visibleRows = self.indexPathsForVisibleRows,
                let firstResponderIndex = visibleRows.first(where: { self.cellForRow(at: $0)?.isActuallyResponder == true }),
                options.contains(.excludeFirstResponderCellFromReload) {
                return toDeferredUpdatePaths.filter({ $0 != firstResponderIndex })
            }
            
            return toDeferredUpdatePaths
        }
		
		
	}
	
	
	
    extension UIKit.UICollectionView: EmptyCheckableSequence {
		
        var isEmpty: Bool {
            let block: () -> Bool = {
                let numberOfSections = (self.dataSource?.numberOfSections?(in: self)) ?? 0
                let rowsCount = (0 ..< numberOfSections)
                    .reduce(0) { $0 + (self.dataSource?.collectionView(self, numberOfItemsInSection: $1) ?? 0) }
                return rowsCount == 0
            }
            
            if Thread.isMainThread {
                return block()
            } else {
                return DispatchQueue.main.sync(execute: block)
            }
        }
        
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
		
        func applyOptions(options: ApplyAnimationOptions, to animations: (cells: CellsAnimations, sections: SectionsAnimations)) -> (cells: CellsAnimations, sections: SectionsAnimations) {
            var animations = animations
            
            if let firstResponderIndex = indexPathsForVisibleItems.first(where: { self.cellForItem(at: $0)?.isActuallyResponder == true }) {
                if options.contains(.excludeFirstResponderCellFromReload) {
                    animations.cells.toUpdate = animations.cells.toUpdate.filter({ $0 != firstResponderIndex })
                }
                
                if options.contains(.excludeFirstResponderSectionFromReload) {
                    animations.sections.toUpdate.remove(firstResponderIndex.section)
                }
            }
            
            return animations
        }
        
        func applyOptions(options: ApplyAnimationOptions, toDeferredUpdatePaths: [IndexPath]) -> [IndexPath] {
            
            if let firstResponderIndex = indexPathsForVisibleItems.first(where: { self.cellForItem(at: $0)?.isActuallyResponder == true }),
                options.contains(.excludeFirstResponderCellFromReload) {
                return toDeferredUpdatePaths.filter({ $0 != firstResponderIndex })
            }
            
            return toDeferredUpdatePaths
        }
		
		/// Use this for applying changes for UICollectionView.
		///
		/// - Parameters:
		///   - owner: Apply moves to Operation queue, so you need to pass owner for capturing.
		///   - newList: New list that should be presented in collection view.
		///   - getCurrentListBlock: Block for getting current screen list. Called from main thread.
		///   - animator: Instance of TableAnimator for calculating changes.
		///   - animated: If you dont want to animate changes, just pass *false*, otherwise, pass *true*.
        ///   - options: Additional options for animations applying.
		///   - from: Initial list, which we got from *getCurrentListBlock()*.
		///   - to: New list to set, which you pass in *newList*.
		///   - setNewListBlock: Block for changing current screen list to passed *newList*. Called from main thread.
		///   - completion: Block for capturing animation completion. Called from main thread.
		///   - error: Block for capturing error during changes calculation. When we got error in changes, we call *setNewListBlock* and *collectionView.reloadData()*, then error block called
		///   - tableError: TableAnimatorError
		public func apply<T, O: AnyObject>(owner: O, newList: [T], animator: TableAnimator<T>, animated: Bool, options: ApplyAnimationOptions = [], getCurrentListBlock: @escaping (_ owner: O) -> [T], setNewListBlock: @escaping ((owner: O, newList: [T])) -> Void, completion: (() -> Void)? = nil, error: ((_ tableError: Error) -> Void)? = nil) {
			
            if options.contains(.cancelPreviousAddedOperations) {
                self.getApplyQueue().cancelAllOperations()
            }
            
            if options.contains(.withoutActuallyRefreshTable) {
                self.getApplyQueue().addOperation {
                    DispatchQueue.main.sync { [weak owner] in
                        guard let strongO = owner else { return }
                        setNewListBlock((strongO, newList))
                    }
                }
                return
                
            } else if !animated || (self.isEmpty && options.contains(.withoutAnimationForEmptyTable)) {
                self.getApplyQueue().addOperation {
                    DispatchQueue.main.sync { [weak owner, weak self] in
                        guard let strongO = owner, let strong = self else { return }
                        setNewListBlock((strongO, newList))
                        strong.reloadData()
						completion?()
                    }
                }
                return
            }
			
			let safeApplyClosure: (O, DispatchSemaphore, TableAnimations) -> Void = { [weak self] anOwner, semaphore, animations in
				guard let strong = self, strong.dataSource != nil else {
					return
				}
                let animations = strong.applyOptions(options: options, to: animations)
				
				strong.performBatchUpdates({
					setNewListBlock((anOwner, newList))
					
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
					
				}, completion: { _ in
					if animations.cells.toDeferredUpdate.isEmpty {
						completion?()
					}
					
					semaphore.signal()
				})
			}
			
			
			let safeDeferredApplyClosure: (O, DispatchSemaphore, [IndexPath]) -> Void = { [weak self] _, semaphore, toDeferredUpdate in
				guard let strong = self, strong.dataSource != nil else {
					return
				}
                let toDeferredUpdate = strong.applyOptions(options: options, toDeferredUpdatePaths: toDeferredUpdate)
				
				strong.performBatchUpdates({
					strong.reloadItems(at: toDeferredUpdate)
				}, completion: { _ in
					completion?()
					semaphore.signal()
				})
			}
			
			
			let onAnimationsError: (O, Error) -> Void = { [weak self] anOwner, anError in
				setNewListBlock((anOwner, newList))
				self?.reloadData()
				
				if let strong = self, strong.dataSource == nil {
					return
				}
				
				error?(anError)
			}
			
			
			safeApplier.apply(owner: owner,
							  newList: newList,
                              options: options,
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



