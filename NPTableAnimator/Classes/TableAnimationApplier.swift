//
//  TableAnimationApplier.swift
//  NPTableAnimator
//
//  Created by Nikita Patskov on 14.11.17.
//


import Foundation


#if os(iOS)
	
	
	extension UIKit.UITableView {
		
		public func apply<InteractiveUpdates>(animations: (cells: CellsAnimations<InteractiveUpdates>, sections: SectionsAnimations), setNewListBlock: () -> Void, applyAnimationsToCell: @escaping (UITableViewCell, [InteractiveUpdates]) -> Void, completion: (() -> Void)?, rowAnimation: UITableViewRowAnimation) {
			
			let setAnimationsClosure = {
				self.insertSections(animations.sections.toInsert, with: rowAnimation)
				self.deleteSections(animations.sections.toDelete, with: rowAnimation)
				self.reloadSections(animations.sections.toUpdate, with: rowAnimation)
				
				for (from, to) in animations.sections.toMove {
					self.moveSection(from, toSection: to)
				}
				
				self.insertRows(at: animations.cells.toInsert, with: rowAnimation)
				self.deleteRows(at: animations.cells.toDelete, with: rowAnimation)
				self.reloadRows(at: animations.cells.toUpdate, with: rowAnimation)
				
				for (from, to) in animations.cells.toMove {
					self.moveRow(at: from, to: to)
				}
				
				for (path, updates) in animations.cells.toInteractiveUpdate {
					guard let cell = self.cellForRow(at: path) else { continue }
					applyAnimationsToCell(cell, updates)
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
						self.reloadRows(at: animations.cells.toDeferredUpdate, with: rowAnimation)
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
					self.beginUpdates()
					self.reloadRows(at: animations.cells.toDeferredUpdate, with: rowAnimation)
					self.endUpdates()
				}
				
				CATransaction.commit()
			}
			
		}
	}
	
	
	
	extension UIKit.UICollectionView {
		
		public func apply<InteractiveUpdates>(animations: (cells: CellsAnimations<InteractiveUpdates>, sections: SectionsAnimations), setNewListBlock: () -> Void, applyAnimationsToCell: @escaping (UICollectionViewCell, [InteractiveUpdates]) -> Void, completion: (() -> Void)?) {
			
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
				
				for (path, updates) in animations.cells.toInteractiveUpdate {
					guard let cell = self.cellForItem(at: path) else { continue }
					applyAnimationsToCell(cell, updates)
				}
			}, completion: { _ in
				if animations.cells.toDeferredUpdate.isEmpty {
					completion?()
				} else {
					self.performBatchUpdates({
						self.reloadItems(at: animations.cells.toDeferredUpdate)
					}, completion: { _ in
						completion?()
					})
					
				}
			})
		}
		
	}
	
#endif



