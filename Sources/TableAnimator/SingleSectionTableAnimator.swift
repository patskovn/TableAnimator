//
//  SingleSectionTableAnimator.swift
//  NPTableAnimator
//
//  Created by Nikita Patskov on 19.11.17.
//

import Foundation


public struct DefaultSection<Cell: TableAnimatorCell>: TableAnimatorSection {
	
	public let updateField = 0
	
	public var cells: [Cell]
	
	public static func == (lhs: DefaultSection, rhs: DefaultSection) -> Bool {
		return true
	}
	
}



/// Class, that should be used for calculate one section changes only.
/// Details are described in **TableAnimator** description.
open class SingleSectionTableAnimator<Cell: TableAnimatorCell>: TableAnimator<DefaultSection<Cell>> {
	
	
	/// Function calculates animations between two lists.
	///	- Note: This funcion only calculates animations, not applying them.
	///
	/// - Parameters:
	///   - fromCells: initial cells.
	///   - toCells: result cells.
	/// - Returns: Calculated changes.
	/// - Throws: *TableAnimatorError*
	open func buildAnimations(fromCells: [Cell], toCells: [Cell]) throws -> CellsAnimations {
		let fromSection = DefaultSection(cells: fromCells)
		let toSection = DefaultSection(cells: toCells)
		
		return try buildAnimations(from: [fromSection], to: [toSection]).cells
	}
	
}
