//
//  File.swift
//  NPTableViewAnimator
//
//  Created by Nikita Patskov on 14.03.17.
//  Copyright © 2017 Nikita Patskov. All rights reserved.
//

import Foundation


public struct SectionsAnimations {
	
	public let toInsert: IndexSet
	
	public let toDelete: IndexSet
	
	public let toMove : [(from: Int, to: Int)]
	
	public let toUpdate: IndexSet
	
	init(toInsert: IndexSet, toDelete: IndexSet, toMove : [(from: Int, to: Int)], toUpdate: IndexSet) {
		self.toInsert = toInsert
		self.toDelete = toDelete
		self.toMove = toMove
		self.toUpdate = toUpdate
	}
	
}



public struct CellsAnimations<InteractiveUpdate> {
	
	public let toInsert: [IndexPath]
	
	public let toDelete: [IndexPath]
	
	public let toMove: [(from: IndexPath, to: IndexPath)]
	
	public let toUpdate: [IndexPath]
	
	///Note: Interactive updates should used when you no need to change cell height. Possible usage: mark message as read, show checkmark image etc.
	public let toInteractiveUpdate: [(IndexPath, [InteractiveUpdate])]
	
	
	static func +(left: CellsAnimations<InteractiveUpdate>, right: CellsAnimations<InteractiveUpdate>) -> CellsAnimations<InteractiveUpdate> {
		
		return CellsAnimations<InteractiveUpdate>(toInsert: left.toInsert + right.toInsert
			, toDelete: left.toDelete + right.toDelete
			, toMove: left.toMove + right.toMove
			, toUpdate: left.toUpdate + right.toUpdate
			, toInteractiveUpdate: left.toInteractiveUpdate + right.toInteractiveUpdate)
	}
	
}










