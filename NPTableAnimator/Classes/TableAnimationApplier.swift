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

			guard !animations.cells.isEmpty && !animations.sections.isEmpty else {
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

			let safeApplyClosure: (DispatchSemaphore) -> Bool = { [weak self] semaphore in
				guard let strong = self else {
					semaphore.signal()
					return false
				}

				var didSetNewList = false
				
				if #available(iOS 11, *) {

					strong.performBatchUpdates({
						 didSetNewList = setNewListBlock()
						
						if didSetNewList {
							setAnimationsClosure(strong)
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

					didSetNewList = setNewListBlock()
					
					if animations.cells.toDeferredUpdate.isEmpty || !didSetNewList {
						CATransaction.setCompletionBlock(completion)
					}

					setAnimationsClosure(strong)

					strong.endUpdates()
				}
				
				return didSetNewList
			}


			let safeDeferredApplyClosure: (DispatchSemaphore) -> Void = { [weak self] semaphore in
				guard let strong = self else {
					semaphore.signal()
					return
				}

				if #available(iOS 11, *) {
					strong.performBatchUpdates({
					   strong.reloadRows(at: animations.cells.toDeferredUpdate, with: rowAnimations.reload)
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
					strong.reloadRows(at: animations.cells.toDeferredUpdate, with: rowAnimations.reload)
					strong.endUpdates()

					CATransaction.commit()
				}

			}

			SafeApplier.get(for: self).apply(hasDeferredAnimations: !animations.cells.toDeferredUpdate.isEmpty,
								   mainPerform: safeApplyClosure,
								   deferredPerform: safeDeferredApplyClosure,
								   cancelBlock: cancelBlock)

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
		/// - Note: If you have no interactive updates, you may mark InteractiveUpdate type as Void and pass nil to applyAnimationsToCell closure.
		/// - Note: Owner of screen list in *setNewListBlock* should be weakly referenced!
		/// - Parameters:
		///   - animations: Changes, calculated by **TableAnimator**
		///   - setNewListBlock: You should provide block, where you doing something like 'myItems = newItems'
		///   - applyAnimationsToCell: If you have interactive updates, pass this closure for apply interactive animations for cells.
		///   - completion: Completion block, that will be called when animation end.
		///   - cancelBlock: Called if list change was cancelled (You ask next apply before previous apply ended)
		public func apply(animations: TableAnimations, setNewListBlock: @escaping () -> Bool, completion: (() -> Void)?, cancelBlock: (() -> Void)?) {

			guard !animations.cells.isEmpty && !animations.sections.isEmpty else {
				cancelBlock?()
				return
			}

			let safeApplyClosure: (DispatchSemaphore) -> Bool = { [weak self] semaphore in
				guard let strong = self else {
					semaphore.signal()
					return false
				}

				var didSetNewList = false
				
				strong.performBatchUpdates({
					didSetNewList = setNewListBlock()
					
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


			let safeDeferredApplyClosure: (DispatchSemaphore) -> Void = { [weak self] semaphore in
				guard let strong = self else {
					semaphore.signal()
					return
				}

				strong.performBatchUpdates({
					strong.reloadItems(at: animations.cells.toDeferredUpdate)
								   }, completion: { _ in
					completion?()
					semaphore.signal()
				})

			}

			SafeApplier.get(for: self).apply(hasDeferredAnimations: !animations.cells.toDeferredUpdate.isEmpty,
								   mainPerform: safeApplyClosure,
								   deferredPerform: safeDeferredApplyClosure,
								   cancelBlock: cancelBlock)

		}
		
	}
	
#endif



