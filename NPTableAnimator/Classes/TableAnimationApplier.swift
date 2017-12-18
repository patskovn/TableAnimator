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
		let insert: UITableViewRowAnimation
		let delete: UITableViewRowAnimation
		let reload: UITableViewRowAnimation
		public init(insert anInsert: UITableViewRowAnimation, delete aDelete: UITableViewRowAnimation, reload aReload: UITableViewRowAnimation) {
			self.insert = anInsert
			self.delete = aDelete
			self.reload = aReload
		}
	}
	
	extension UIKit.UITableView {
		/// Use this for applying changes for UITableView.
		///
		/// - Note: If you have no interactive updates, you may mark InteractiveUpdate type as Void and pass nil to applyAnimationsToCell closure.
		/// - Parameters:
		///   - animations: Changes, calculated by **TableAnimator**
		///   - setNewListBlock: You should provide block, where you doing something like 'myItems = newItems'
		///   - applyAnimationsToCell: If you have interactive updates, pass this closure for apply interactive animations for cells.
		///   - completion: Completion block, that will be called when animation end.
		///   - rowAnimations: UITableView animations style for insert, delete and reload
		public func apply(animations: (cells: CellsAnimations, sections: SectionsAnimations), setNewListBlock: () -> Void, completion: (() -> Void)?, rowAnimations: UITableViewRowAnimationSet) {
			
			let setAnimationsClosure = {
				self.insertSections(animations.sections.toInsert, with: rowAnimations.insert)
				self.deleteSections(animations.sections.toDelete, with: rowAnimations.delete)
				self.reloadSections(animations.sections.toUpdate, with: rowAnimations.reload)
				
				for (from, to) in animations.sections.toMove {
					self.moveSection(from, toSection: to)
				}
				
				self.insertRows(at: animations.cells.toInsert, with: rowAnimations.insert)
				self.deleteRows(at: animations.cells.toDelete, with: rowAnimations.delete)
				self.reloadRows(at: animations.cells.toUpdate, with: rowAnimations.reload)
				
				for (from, to) in animations.cells.toMove {
					self.moveRow(at: from, to: to)
				}
			}
			
			if #available(iOS 11, *) {

				self.performBatchUpdates({
					setNewListBlock()
					setAnimationsClosure()
				}, completion: { _ in
					if animations.cells.toDeferredUpdate.isEmpty {
						completion?()
					}
				})

				if !animations.cells.toDeferredUpdate.isEmpty {
					self.performBatchUpdates({
						self.reloadRows(at: animations.cells.toDeferredUpdate, with: rowAnimations.reload)
					}, completion: { _ in completion?() })
				}
				
			} else {
				CATransaction.begin()
				self.beginUpdates()
				
				if animations.cells.toDeferredUpdate.isEmpty {
					CATransaction.setCompletionBlock(completion)
				}
				
				setNewListBlock()
				setAnimationsClosure()
				
				self.endUpdates()
				
				if !animations.cells.toDeferredUpdate.isEmpty {
					// Visual bug while doing deferred updated without async on main queue.
					DispatchQueue.main.async {
						
						CATransaction.begin()
						CATransaction.setCompletionBlock(completion)
						
						self.beginUpdates()
						self.reloadRows(at: animations.cells.toDeferredUpdate, with: rowAnimations.reload)
						self.endUpdates()
						
						CATransaction.commit()
					}
				}
				
				CATransaction.commit()
			}
		}
		
		
		/// Use this for applying changes for UITableView.
		///
		/// - Note: If you have no interactive updates, you may mark InteractiveUpdate type as Void and pass nil to applyAnimationsToCell closure.
		/// - Parameters:
		///   - animations: Changes, calculated by **TableAnimator**
		///   - setNewListBlock: You should provide block, where you doing something like 'myItems = newItems'
		///   - applyAnimationsToCell: If you have interactive updates, pass this closure for apply interactive animations for cells.
		///   - completion: Completion block, that will be called when animation end
		///   - rowAnimation: UITableView animations style for all animations like insert, delete and reload
		public func apply(animations: (cells: CellsAnimations, sections: SectionsAnimations), setNewListBlock: () -> Void, completion: (() -> Void)?, rowAnimation: UITableViewRowAnimation) {
			self.apply(animations: animations, setNewListBlock: setNewListBlock, completion: completion, rowAnimations: UITableViewRowAnimationSet(insert: rowAnimation, delete: rowAnimation, reload: rowAnimation))
		}

	}
	
	
	
	extension UIKit.UICollectionView {
		
		/// Use this for applying changes for UICollectionView.
		///
		/// - Note: If you have no interactive updates, you may mark InteractiveUpdate type as Void and pass nil to applyAnimationsToCell closure.
		/// - Parameters:
		///   - animations: Changes, calculated by **TableAnimator**
		///   - setNewListBlock: You should provide block, where you doing something like 'myItems = newItems'
		///   - applyAnimationsToCell: If you have interactive updates, pass this closure for apply interactive animations for cells.
		///   - completion: Completion block, that will be called when animation end.
		public func apply(animations: (cells: CellsAnimations, sections: SectionsAnimations), setNewListBlock: () -> Void, completion: (() -> Void)?) {
			
			self.performBatchUpdates({
				setNewListBlock()
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
				
			}, completion: { _ in
				if animations.cells.toDeferredUpdate.isEmpty {
					completion?()
				}
			})
			
			if !animations.cells.toDeferredUpdate.isEmpty {
				self.performBatchUpdates({
					self.reloadItems(at: animations.cells.toDeferredUpdate)
				}, completion: { _ in
					completion?()
				})
			}
		}
		
	}
	
#endif



