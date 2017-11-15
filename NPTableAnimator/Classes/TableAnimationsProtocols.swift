//
//  NPTableViewAnimationsProtocols.swift
//  NPTableViewAnimator
//
//  Created by Nikita Patskov on 14.03.17.
//  Copyright © 2017 Nikita Patskov. All rights reserved.
//


/// Protocol for updatable itemrepresentation.
public protocol TableAnimatorUpdatable {
	
	/// Timestamp or another revision mark, which can indicate that same entity have new data and should be updated.
	/// Use any Equatable type and same *updateField* value if you no need to calculate updates.
	associatedtype UpdateCellType: Equatable
	
	/// Field for comparing entity revision mark.
	var updateField: UpdateCellType { get }
}




/// Protocol for section element representation.
public protocol TableAnimatorCell: Hashable, TableAnimatorUpdatable {}



/// Protocol for section representation.
/// - Note: To have just single section is fine.
public protocol TableAnimatorSection: Equatable, TableAnimatorUpdatable {
	
	/// Section element representation.
	associatedtype Cell: TableAnimatorCell
	
	/// Sequence of elements in section.
	var cells: [Cell] { get }
	
}


