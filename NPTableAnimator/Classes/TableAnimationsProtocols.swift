//
//  NPTableViewAnimationsProtocols.swift
//  NPTableViewAnimator
//
//  Created by Nikita Patskov on 14.03.17.
//  Copyright © 2017 Nikita Patskov. All rights reserved.
//


public protocol TableAnimatorUpdatable {
	
	associatedtype UpdateCellType: Equatable
	
	var updateField: UpdateCellType { get }
}



public protocol TableAnimatorCell: Hashable, TableAnimatorUpdatable {}



public protocol TableAnimatorSection: Equatable, TableAnimatorUpdatable {
	
	associatedtype Cell: TableAnimatorCell
	
	var cells: [Cell] { get }
	
}



public protocol TableAnimationSequence {
	
	associatedtype Section: TableAnimatorSection
	
	var sections: [Section] { get }
}



