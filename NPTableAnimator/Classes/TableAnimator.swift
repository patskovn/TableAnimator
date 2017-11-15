//
//  NPTableViewAnimator.swift
//  NPTableViewAnimator
//
//  Created by Nikita Patskov on 14.03.17.
//  Copyright © 2017 Nikita Patskov. All rights reserved.
//

import Foundation



/// Possible TableAnmator errors.
///
/// - inconsistencyError: This error happens, when u have two equals entityes etc.
public enum TableAnimatorError: Error {
	
	/// This error happens, when u have two equals entityes etc.
	case inconsistencyError
}


/// Configuration, that TableAnimator will use for calculations.
public struct TableAnimatorConfiguration<Section: TableAnimatorSection, InteractiveUpdate> {
	
	/// You may provide algorhytm for calculating cells move here. Details are described in **MoveCalculatingStrategy** description.
	public let cellMoveCalculatingStrategy: MoveCalculatingStrategy<Section.Cell>
	
	/// You may provide algorhytm for calculating sections move here. Details are described in **MoveCalculatingStrategy** description.
	public let sectionMoveCalculatingStrategy: MoveCalculatingStrategy<Section>
	
	
	/// You may provide algorhytm for calculating cells move here. Details are described in **UpdateCalculatingStrategy** description.
	public let updateCalculatingStrategy: UpdateCalculatingStrategy<Section.Cell, InteractiveUpdate>
	
	
	
	/** Flag for configuring feed consistency checking. Adds additional check to cells uniqueness.
	Section like
	
		[0, 1, 2, 3]
	will pass validation cause all elements in section are unique, but
	
		[0, 0, 1, 2]
	will throw **TableAnimatorError.inconsistencyError**.
	By setting this property to *false*, you guarantee that all cells are unique.
	If you set this flag to *false* and pass not unique items, animator may return wrong calculations.
	*/
	public let isConsistencyValidationEnabled = true
}


private struct DefaultSection<Cell: TableAnimatorCell>: TableAnimatorSection {
	
	let updateField = 0
	
	var cells: [Cell]
	
	static func == (lhs: DefaultSection, rhs: DefaultSection) -> Bool {
		return true
	}
	
}



/// Class, that should be used for calculate one section changes only.
/// Details are described in **TableAnimator** description.
open class SingleSectionTableAnimator<Cell: TableAnimatorCell, InteractiveUpdate>: TableAnimator<DefaultSection<Cell>, InteractiveUpdate> {
	
	
	/// Function calculates animations between two lists.
	///	- Note: This funcion only calculates animations, not applying them.
	///
	/// - Parameters:
	///   - fromCells: initial cells.
	///   - toCells: result cells.
	/// - Returns: Calculated changes.
	/// - Throws: *TableAnimatorError*
	open func buildAnimations(fromCells: [Cell], toCells: [Cell]) throws -> CellsAnimations<InteractiveUpdate> {
		let fromSection = DefaultSection(cells: fromCells)
		let toSection = DefaultSection(cells: toCells)
		
		return try buildAnimations(from: [fromSection], to: [toSection]).cells
	}
	
}



/** **TableAnimator** takes to sequences and calcuate difference between them.

- Note: Animator cant calculate difference, if you do not guarantee elements uniqueness inside sequence.
	 	Details are described in **TableAnimatorConfiguration.isConsistencyValidationEnabled** description.
- Note: If you do not want to use interactive updates in your calculations, you may mark InteractiveUpdate type as Void.
*/
open class TableAnimator<Section: TableAnimatorSection, InteractiveUpdate> {
	
	private let cellMoveCalculatingStrategy: MoveCalculatingStrategy<Section.Cell>
	private let sectionMoveCalculatingStrategy: MoveCalculatingStrategy<Section>
	private let updateCalculatingStrategy: UpdateCalculatingStrategy<Section.Cell, InteractiveUpdate>
	private let isConsistencyValidationEnabled: Bool
	
	
	/// Use this init for perfect configuring animator behavior.
	///
	/// - Parameter configuration: Configuration, that TableAnimator will use for calculations.
	public init(configuration: TableAnimatorConfiguration<Section, InteractiveUpdate>) {
		self.cellMoveCalculatingStrategy = configuration.cellMoveCalculatingStrategy
		self.sectionMoveCalculatingStrategy = configuration.sectionMoveCalculatingStrategy
		self.updateCalculatingStrategy = configuration.updateCalculatingStrategy
		self.isConsistencyValidationEnabled = configuration.isConsistencyValidationEnabled
	}
	
	
	/// Use this *init* for default and simpliest (not fastest) behavior.
	public init() {
		self.cellMoveCalculatingStrategy = .top
		self.sectionMoveCalculatingStrategy = .top
		self.updateCalculatingStrategy = .default
		self.isConsistencyValidationEnabled = true
	}
	
	
	/// Function calculates animations between two lists.
	///	- Note: This funcion only calculates animations, not applying them.
	///
	/// - Parameters:
	///   - fromList: initial list.
	///   - toList: result list.
	/// - Returns: Calculated changes.
	/// - Throws: *TableAnimatorError*
	open func buildAnimations(from fromList: [Section], to toList: [Section]) throws -> (sections: SectionsAnimations, cells: CellsAnimations<InteractiveUpdate>) {
		
		if isConsistencyValidationEnabled {
			try validateSectionsConsistency(fromList: fromList, toList: toList)
		}
		
		let sectionTransformResult = try makeSectionTransformations(from: fromList, to: toList)
		
		let sectionAnimations = SectionsAnimations(toInsert: sectionTransformResult.toAdd
			, toDelete: sectionTransformResult.toRemove
			, toMove: sectionTransformResult.toMove
			, toUpdate: sectionTransformResult.toUpdate)
		
		var cellsAnimations = CellsAnimations<InteractiveUpdate>(toInsert: [], toDelete: [], toMove: [], toUpdate: [], toDeferredUpdate: [], toInteractiveUpdate: [])
		
		for index in 0 ..< sectionTransformResult.existedSectionFromList.count {
			
			let fromIndex = sectionTransformResult.existedSectionFromList[index]
			let toIndex = sectionTransformResult.existedSectionToList[index]
			
			let fromSection = fromList[fromIndex]
			let toSection = toList[toIndex]
			
			let cellTransforms = makeSingleSectionTransformation(from: fromSection, fromSectionIndex: fromIndex, to: toSection, toSectionIndex: toIndex)
			
			cellsAnimations = cellsAnimations + cellTransforms
			
		}
		
		return (sections: sectionAnimations, cells: cellsAnimations)
	}

	
	private func validateSectionsConsistency(fromList: [Section], toList: [Section]) throws {
		
		func validateSections(list: [Section]) throws {
			let arrayElements = list.flatMap({ $0.cells })
			
			guard arrayElements.count == Set(arrayElements).count else {
				throw TableAnimatorError.inconsistencyError
			}
		}
		
		try validateSections(list: fromList)
		try validateSections(list: toList)
	}
	
	
	private func makeSectionTransformations(from fromList: [Section], to toList: [Section]) throws -> SectionsTransformationResult {
		
		var toAdd = IndexSet()
		var toRemove = IndexSet()
		var toUpdate = IndexSet()
		
		var existedSectionIndexes: [(Section, (from: Int, to: Int))] = []
		var orderedExistedSectionsFrom: [(index: Int, section: Section)] = []
		var orderedExistedSectionsTo: [(index: Int, section: Section)] = []
		
		
		for (index, section) in fromList.enumerated() {
			
			if let indexInNewSection = toList.index(of: section) {
				
				let newSection = toList[indexInNewSection]
				
				if section.updateField != newSection.updateField {
					toUpdate.insert(index)
					
				} else {
					orderedExistedSectionsFrom.append((index, section))
					existedSectionIndexes.append((section, (index, 0)))
				}
				
			} else {
				toRemove.insert(index)
			}
			
		}
		
		
		for (index, section) in toList.enumerated() {
			if !fromList.contains(section) {
				toAdd.insert(index)
			} else if section.updateField == section.updateField {
				orderedExistedSectionsTo.append((index, section))
				
				guard let existedIndex = existedSectionIndexes.index(where: { $0.0 == section })
					else { throw TableAnimatorError.inconsistencyError
				}
				
				existedSectionIndexes[existedIndex].1.to = index
			}
		}
		
		
		let toMove = try recognizeSectionsMove(existedSectionIndexes: existedSectionIndexes, existedSectionsFrom: orderedExistedSectionsFrom, existedSectionsTo: orderedExistedSectionsTo)
		
		let result = SectionsTransformationResult(toAdd: toAdd
			, toRemove: toRemove
			, toMove: toMove
			, toUpdate: toUpdate
			, existedSectionFromList: orderedExistedSectionsFrom.map{ $0.index }
			, existedSectionToList: orderedExistedSectionsTo.map{ $0.index })
		
		return result
	}
	
	
	
	
	private func recognizeSectionsMove(existedSectionIndexes: [(Section, (from: Int, to: Int))], existedSectionsFrom: [(index: Int, section: Section)], existedSectionsTo: [(index: Int, section: Section)]) throws -> [(from: Int, to: Int)] {
		
		var toMove = [(from: Int, to: Int)]()
		let toMoveSequence: [Section]
		let toIndexCalculatingClosure: (Int) -> Int
		let toEnumerateList: [(index: Int, section: Section)]
		
		func calculateToMoveElementsWithPreferredDirection() throws -> [Section] {
			
			var toMoveElements = [Section]()
			
			for (anIndex, value) in toEnumerateList.enumerated() {
				
				let toSection = value.section
				
				let indexTo = toIndexCalculatingClosure(anIndex)
				
				guard let indexFrom = existedSectionsFrom.index(where: { $0.section == toSection })
					, let existedSectionIndex = existedSectionIndexes.index(where: { $0.0 == toSection })
					else { throw TableAnimatorError.inconsistencyError }
				
				let (fromIndex, toIndex) = existedSectionIndexes[existedSectionIndex].1
				
				guard fromIndex != toIndex else { continue }
				guard !toMoveElements.contains(toSection) else { continue }
				
				
				let sectionsBeforeFrom = existedSectionsFrom[0 ..< indexFrom].map{ $0.section }
				let sectionsAfterFrom = existedSectionsFrom[indexFrom + 1 ..< existedSectionsFrom.count].map{ $0.section }
				
				let sectionsBeforeTo = existedSectionsTo[0 ..< indexTo].map{ $0.section }
				let sectionsAfterTo = existedSectionsTo[indexTo + 1 ..< existedSectionsTo.count].map{ $0.section }
				
				let moveFromTopToBottom = sectionsBeforeTo.filter{ !sectionsBeforeFrom.contains($0) }
				let moveFromBottomToTop = sectionsAfterTo.filter{ !sectionsAfterFrom.contains($0) }
				
				for section in moveFromTopToBottom where !toMoveElements.contains(section) {
					toMoveElements.append(section)
				}
				
				for section in moveFromBottomToTop where !toMoveElements.contains(section) {
					toMoveElements.append(section)
				}
			}
			
			return toMoveElements
		}
		
		
		switch sectionMoveCalculatingStrategy {
		case .top:
			toEnumerateList = existedSectionsTo.reversed()
			toIndexCalculatingClosure = { existedSectionsTo.count - $0 - 1 }
			toMoveSequence = try calculateToMoveElementsWithPreferredDirection()
			
		case .bottom:
			toEnumerateList = existedSectionsTo
			toIndexCalculatingClosure = { $0 }
			toMoveSequence = try calculateToMoveElementsWithPreferredDirection()
			
		case .directRecognition(let recognizer):
			toMoveSequence = zip(existedSectionsFrom, existedSectionsTo)
				.filter { recognizer.recognizeMove(from: $0.1, to: $1.1) }
				.reduce(into: []) { if !$0.contains($1.1.section) { $0.append($1.1.section) } }
		}
		
		
		for section in toMoveSequence {
			let existedSectionIndex = existedSectionIndexes.index{ $0.0 == section }!
			let indexes = existedSectionIndexes[existedSectionIndex].1
			
			toMove.append(indexes)
		}
		
		return toMove
	}
	
	
	
	
	private func makeSingleSectionTransformation(from fromSection: Section, fromSectionIndex: Int, to toSection: Section, toSectionIndex: Int) -> CellsAnimations<InteractiveUpdate> {
		
		var toAdd = [IndexPath]()
		var toRemove = [IndexPath]()
		var toDeferredUpdate = [IndexPath]()
		var toInteractiveUpdate = [(IndexPath, [InteractiveUpdate])]()
		var toUpdate = [IndexPath]()

		var existedCellIndexes: [Section.Cell : (from: Int, to: Int)] = [:]
		var orderedExistedCellsFrom: [(index: Int, element: Section.Cell)] = []
		var orderedExistedCellsTo: [(index: Int, element: Section.Cell)] = []
		
		
		for (index, cell) in fromSection.cells.enumerated() {

			let path = IndexPath(row: index, section: fromSectionIndex)

			if let indexInNewList = toSection.cells.index(of: cell) {
				orderedExistedCellsFrom.append((index, cell))
				existedCellIndexes[cell] = (index, 0)

				let newCell = toSection.cells[indexInNewList]

				let interactiveUpdates: [InteractiveUpdate]
				
				switch updateCalculatingStrategy {
				case .default:
					interactiveUpdates = []
					
				case .withInteractiveUpdateRecognition(let recognizer):
					interactiveUpdates = recognizer.recognizeInteractiveUpdate(from: cell, to: newCell)
				}

				if !interactiveUpdates.isEmpty {
					toInteractiveUpdate.append((path, interactiveUpdates))

				} else if cell.updateField != newCell.updateField {
					toUpdate.append(path)
				}

			} else {
				let path = IndexPath(row: index, section: fromSectionIndex)
				toRemove.append(path)
			}

		}
		
		
		for (index, cell) in toSection.cells.enumerated() {
			
			let path = IndexPath(row: index, section: toSectionIndex)
			
			if let indexInOldList = fromSection.cells.index(of: cell) {
				
				let oldCell = fromSection.cells[indexInOldList]
				
				if oldCell.updateField != cell.updateField {
					toDeferredUpdate.append(path)
				}
				
				orderedExistedCellsTo.append((index, cell))
				existedCellIndexes[cell]!.to = index
				
			} else {
				toAdd.append(path)
			}
			
		}
		
		let toMove = recognizeCellsMove(existedElementsIndexes: existedCellIndexes
			, existedElementsFrom: orderedExistedCellsFrom
			, existedElementsTo: orderedExistedCellsTo)
			.map { (from: IndexPath(row: $0.from, section: toSectionIndex) , to: IndexPath(row: $0.to, section: toSectionIndex)) }

		toUpdate = toUpdate.filter{ toUpdateIndex in toMove.contains(where: { $0.from == toUpdateIndex }) }
		toDeferredUpdate = toDeferredUpdate.filter { !toUpdate.contains($0) }

		let cellsTransformations = CellsAnimations(toInsert: toAdd
			, toDelete: toRemove
			, toMove: toMove
			, toUpdate: toUpdate
			, toDeferredUpdate: toDeferredUpdate
			, toInteractiveUpdate: toInteractiveUpdate)
		
		return cellsTransformations
		
	}
	
	
	
	
	private func recognizeCellsMove(existedElementsIndexes: [Section.Cell : (from: Int, to: Int)], existedElementsFrom: [(index: Int, element: Section.Cell)], existedElementsTo: [(index: Int, element: Section.Cell)]) -> [(from: Int, to: Int)] {
		
		var toMove = [(from: Int, to: Int)]()
		
		let toMoveSequence: Set<Section.Cell>
		let toIndexCalculatingClosure: (Int) -> Int
		let toEnumerateList: [(index: Int, element: Section.Cell)]
		
		
		func calculateToMoveElementsWithPreferredDirection() -> Set<Section.Cell> {
			
			var toMoveElements = Set<Section.Cell>()
			
			for (anIndex, value) in toEnumerateList.enumerated() {
				
				let toSection = value.element
				
				let indexTo = toIndexCalculatingClosure(anIndex)
				let indexFrom = existedElementsFrom.index{ $0.element == toSection }!
				
				let (fromIndex, toIndex) = existedElementsIndexes[toSection]!
				
				
				guard fromIndex != toIndex else { continue }
				guard !toMoveElements.contains(toSection) else { continue }
				
				
				let elementsBeforeFrom = Set<Section.Cell>(existedElementsFrom[0 ..< indexFrom].map{ $0.element })
				let elementsAfterFrom = Set<Section.Cell>(existedElementsFrom[indexFrom + 1 ..< existedElementsFrom.count].map{ $0.element })
				
				let elementsBeforeTo = Set<Section.Cell>(existedElementsTo[0 ..< indexTo].map{ $0.element })
				let elementsAfterTo = Set<Section.Cell>(existedElementsTo[indexTo + 1 ..< existedElementsTo.count].map{ $0.element })
				
				let moveFromTopToBottom = elementsBeforeTo.subtracting(elementsBeforeFrom)
				let moveFromBottomToTop = elementsAfterTo.subtracting(elementsAfterFrom)
				
				
				toMoveElements.formUnion(moveFromTopToBottom)
				toMoveElements.formUnion(moveFromBottomToTop)
			}
			
			return toMoveElements
		}
		
		
		switch cellMoveCalculatingStrategy {
		case .top:
			toEnumerateList = existedElementsTo.reversed()
			toIndexCalculatingClosure = { existedElementsTo.count - $0 - 1 }
			toMoveSequence = calculateToMoveElementsWithPreferredDirection()
			
		case .bottom:
			toEnumerateList = existedElementsTo
			toIndexCalculatingClosure = { $0 }
			toMoveSequence = calculateToMoveElementsWithPreferredDirection()
			
		case .directRecognition(let recognizer):
			toMoveSequence = zip(existedElementsFrom, existedElementsTo)
				.filter { recognizer.recognizeMove(from: $0.1, to: $1.1) }
				.reduce([]) { return $0.union([$1.1.element]) }
		}
		
		
		
		for element in toMoveSequence {
			let indexes = existedElementsIndexes[element]!
			
			toMove.append(indexes)
		}
		
		return toMove
	}
	
	
}




private struct SectionsTransformationResult {
	
	let toAdd: IndexSet
	let toRemove: IndexSet
	let toMove: [(from: Int, to: Int)]
	let toUpdate: IndexSet
	
	//Количество элементов в массивах должно совпадать
	let existedSectionFromList: [Int]
	let existedSectionToList: [Int]
}

























