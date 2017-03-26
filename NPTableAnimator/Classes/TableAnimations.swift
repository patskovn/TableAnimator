//
//  File.swift
//  NPTableViewAnimator
//
//  Created by Nikita Patskov on 14.03.17.
//  Copyright © 2017 Nikita Patskov. All rights reserved.
//

import Foundation


public class SectionsAnimations {
	
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



public class CellsAnimations {
	
	public var toInsert: [IndexPath]
	
	public var toDelete: [IndexPath]
	
	public var toMove: [(from: IndexPath, to: IndexPath)]
	
	public var toUpdate: [IndexPath]
	
	
	func add(another cells: CellsAnimations) {
		
		toInsert += cells.toInsert
		
		toDelete += cells.toDelete
		
		toMove += cells.toMove
		
		toUpdate += cells.toUpdate
		
		
	}
	
	
	init(toInsert: [IndexPath], toDelete: [IndexPath], toMove: [(from: IndexPath, to: IndexPath)], toUpdate: [IndexPath]) {
		self.toInsert = toInsert
		self.toDelete = toDelete
		self.toMove = toMove
		self.toUpdate = toUpdate
	}
	
}


public class CellsAnimationsInteractived<InteractiveUpdate>: CellsAnimations {
	
	public var toInteractiveUpdate: [(IndexPath, [InteractiveUpdate])]
	
	init(toInsert: [IndexPath], toDelete: [IndexPath], toMove: [(from: IndexPath, to: IndexPath)], toUpdate: [IndexPath], toInteractiveUpdate: [(IndexPath, [InteractiveUpdate])]) {
		self.toInteractiveUpdate = toInteractiveUpdate
		super.init(toInsert: toInsert, toDelete: toDelete, toMove: toMove, toUpdate: toUpdate)
	}
	
	func add(another cells: CellsAnimationsInteractived) {
		
		toInsert += cells.toInsert
		
		toDelete += cells.toDelete
		
		toMove += cells.toMove
		
		toUpdate += cells.toUpdate
		
		toInteractiveUpdate += toInteractiveUpdate
	}
	
}









