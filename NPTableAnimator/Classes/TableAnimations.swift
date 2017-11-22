//
//  File.swift
//  NPTableViewAnimator
//
//  Created by Nikita Patskov on 14.03.17.
//  Copyright © 2017 Nikita Patskov. All rights reserved.
//

import Foundation


/// Structure contains information about sections change.
public struct SectionsAnimations {
	
	/// New sections indexes.
	public let toInsert: IndexSet
	
	/// Deleted sections indexes.
	public let toDelete: IndexSet
	
	/// Moved sections indexes.
	public let toMove : [(from: Int, to: Int)]
	
	/// Updated sections indexes.
	public let toUpdate: IndexSet
}


/// Cells animations without interactive updates
public typealias DefaultCellsAnimations = CellsAnimations<Void>


/// Structure contains information about cells change.
public struct CellsAnimations<InteractiveUpdate> {
	
	/// New cells indexes.
	public let toInsert: [IndexPath]
	
	/// Deleted cells indexes.
	public let toDelete: [IndexPath]
	
	/// Moved cells indexes.
	public let toMove: [(from: IndexPath, to: IndexPath)]
	
	/// Updated cells indexes.
	public let toUpdate: [IndexPath]

	/// Updated cells indexes, which intersects with move indexes. UITableView can't perform *move* and *update*
	/// at the same time, so we need to apply this updates during second update request.
	public let toDeferredUpdate: [IndexPath]

	/** Cells to interactive updates.
	
	- Note: Interactive updates should be used when you no need to change cell height. Possible usage: mark message as read, show checkmark image etc.
	- Note: Interactive updates will never intersects with *toUpdate* or *toDeferredUpdate*, because *toUpdate* and *toDeferredUpdate* have higher priority in calculations.
	*/
	public let toInteractiveUpdate: [(IndexPath, [InteractiveUpdate])]
	
	
	static func +(left: CellsAnimations<InteractiveUpdate>, right: CellsAnimations<InteractiveUpdate>) -> CellsAnimations<InteractiveUpdate> {
		
		return CellsAnimations<InteractiveUpdate>(toInsert: left.toInsert + right.toInsert
			, toDelete: left.toDelete + right.toDelete
			, toMove: left.toMove + right.toMove
			, toUpdate: left.toUpdate + right.toUpdate
			, toDeferredUpdate: left.toDeferredUpdate + right.toDeferredUpdate
			, toInteractiveUpdate: left.toInteractiveUpdate + right.toInteractiveUpdate)
	}
	
}










