//
//  File.swift
//  NPTableViewAnimator
//
//  Created by Nikita Patskov on 14.03.17.
//  Copyright © 2017 Nikita Patskov. All rights reserved.
//

import Foundation

public struct TableAnimations {
	
	public struct Sections {
		
		public let toInsert: IndexSet
		
		public let toDelete: IndexSet
		
		public let toMove : [(from: Int, to: Int)]
		
		public let toUpdate: IndexSet
	}
	
	
	public struct Cells {
		
		public var toInsert: [IndexPath]
		
		public var toDelete: [IndexPath]
		
		public var toMove: [(from: IndexPath, to: IndexPath)]
		
		public var toUpdate: [IndexPath]
		
		mutating func add(another cells: Cells) {
			
			toInsert += cells.toInsert
			
			toDelete += cells.toDelete
			
			toMove += cells.toMove
			
			toUpdate += cells.toUpdate
			
		}
		
	}
	
	
	
	public let sections: Sections
	
	
	public let cells: Cells
	
	
}
