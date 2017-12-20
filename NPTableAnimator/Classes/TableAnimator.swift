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
	
	/// This error happens, when u have two equals sections in list.
	case sectionInconsistencyError
	
	/// This error happens, when u have two equals cells in one section. Pass the section in which elements doubles and doubled element.
	/// If inconsistency found in "fromList", section and element picked from "fromList", picked from "toList" otherwise.
	case cellInconsistencyError(Int, Any)
}




/** **TableAnimator** takes to sequences and calcuate difference between them.

- Note: Animator cant calculate difference, if you do not guarantee elements uniqueness inside sequence.
	 	Details are described in **TableAnimatorConfiguration.isConsistencyValidationEnabled** description.
- Note: If you do not want to use interactive updates in your calculations, you may mark InteractiveUpdate type as Void.
*/
open class TableAnimator<Section: TableAnimatorSection> {
	
	private typealias List = [(section: Section, cells: [Section.Cell : IndexedCell<Section.Cell>])]
	
	private let cellMoveCalculatingStrategy: MoveCalculatingStrategy<Section.Cell>
	private let sectionMoveCalculatingStrategy: MoveCalculatingStrategy<Section>
	private let isConsistencyValidationEnabled: Bool
	
	
	/// Use this init for perfect configuring animator behavior.
	///
	/// - Parameter configuration: Configuration, that TableAnimator will use for calculations.
	public init(configuration: TableAnimatorConfiguration<Section>) {
		self.cellMoveCalculatingStrategy = configuration.cellMoveCalculatingStrategy
		self.sectionMoveCalculatingStrategy = configuration.sectionMoveCalculatingStrategy
		self.isConsistencyValidationEnabled = configuration.isConsistencyValidationEnabled
	}
	
	
	/// Use this *init* for default and simpliest (not fastest) behavior.
	public convenience init() {
		self.init(configuration: .init())
	}
	
	
	/// Function calculates animations between two lists.
	///	- Note: This funcion only calculates animations, not applying them.
	///
	/// - Parameters:
	///   - fromList: initial list.
	///   - toList: result list.
	/// - Returns: Calculated changes.
	/// - Throws: *TableAnimatorError*
	open func buildAnimations(from fromList: [Section], to toList: [Section]) throws -> TableAnimations {
		
		let indexedFromList = indexedListBuilder(list: fromList)
		let indexedToList = indexedListBuilder(list: toList)
		
		if isConsistencyValidationEnabled {
			try validateSectionsConsistency(fromList: indexedFromList, fromSections: fromList, toList: indexedToList, toSections: toList)
		}
		
		let sectionTransformResult = try makeSectionTransformations(from: fromList, to: toList)
		
		let sectionAnimations = SectionsAnimations(toInsert: sectionTransformResult.toAdd
			, toDelete: sectionTransformResult.toRemove
			, toMove: sectionTransformResult.toMove
			, toUpdate: sectionTransformResult.toUpdate)
		
		var cellsAnimations = CellsAnimations(toInsert: [], toDelete: [], toMove: [], toUpdate: [], toDeferredUpdate: [])
		
		for index in 0 ..< sectionTransformResult.existedSectionFromList.count {
			
			let fromIndex = sectionTransformResult.existedSectionFromList[index]
			let toIndex = sectionTransformResult.existedSectionToList[index]
			
			let fromSection = indexedFromList[fromIndex].cells
			let toSection = indexedToList[toIndex].cells
			
			let cellTransforms = makeSingleSectionTransformation(from: fromSection, to: toSection)
			
			cellsAnimations = cellsAnimations + cellTransforms
			
		}
		
		return (sections: sectionAnimations, cells: cellsAnimations)
	}
	
	
	
	private func indexedListBuilder(list: [Section]) -> List {
		
		var result = List()
		
		for (sectionIndex, section) in list.enumerated() {
			var dict = [Section.Cell : IndexedCell<Section.Cell>]()
			
			for (cellIndex, cell) in section.cells.enumerated() {
				let index = IndexPath(row: cellIndex, section: sectionIndex)
				dict[cell] = IndexedCell(cell: cell, index: index)
			}
			
			result.append((section, dict))
		}
		
		return result
	}

	
	private func validateSectionsConsistency(fromList: List, fromSections: [Section], toList: List, toSections: [Section]) throws {
		
		func validateSections(list: List, sections: [Section]) throws {
			
			var uniqueSections: [Section] = []
			
			for (index, listElement) in list.enumerated() {
				
				if !uniqueSections.contains(listElement.section) {
					uniqueSections.append(listElement.section)
				}
				
				if sections[index].cells.count != listElement.cells.count {
					let listElementCells = listElement.cells.map({ $0.key })
					
					if let firstNotExistedElement = Set(sections[index].cells).subtracting(listElementCells).first {
						throw TableAnimatorError.cellInconsistencyError(index, firstNotExistedElement)
					} else {
						throw TableAnimatorError.sectionInconsistencyError
					}
				}
			}
			
			if uniqueSections.count != list.count {
				throw TableAnimatorError.sectionInconsistencyError
			}
		}
		
		try validateSections(list: fromList, sections: fromSections)
		try validateSections(list: toList, sections: toSections)
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
					else { throw TableAnimatorError.sectionInconsistencyError
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
					else { throw TableAnimatorError.sectionInconsistencyError }
				
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
	
	
	
	
	private func makeSingleSectionTransformation(from fromSection: [Section.Cell : IndexedCell<Section.Cell>], to toSection: [Section.Cell : IndexedCell<Section.Cell>]) -> CellsAnimations {
		
		var toAdd = [IndexPath]()
		var toRemove = [IndexPath]()
		var toDeferredUpdate = [IndexPath]()
		var toMove: [(from: IndexPath, to: IndexPath)] = []

		var existedCellIndexes: [Section.Cell : (from: IndexPath, to: IndexPath)] = [:]
		var orderedExistedCellsFrom: [IndexedCell<Section.Cell>] = []
		var orderedExistedCellsTo: [IndexedCell<Section.Cell>] = []
		
		for (_, fromCell) in fromSection {
			if let toCell = toSection[fromCell.cell] {
				orderedExistedCellsFrom.append(fromCell)
				existedCellIndexes[fromCell.cell] = (fromCell.index, toCell.index)
				
				if fromCell.cell.updateField != toCell.cell.updateField {
					toDeferredUpdate.append(toCell.index)
				}
				
				if case .directRecognition(let moveRecognizer) = self.cellMoveCalculatingStrategy,
					moveRecognizer.recognizeMove(from: fromCell.cell, to: toCell.cell) {
					toMove.append((fromCell.index, toCell.index))
				}
				
			} else {
				toRemove.append(fromCell.index)
			}
		}
		
		for (_, toCell) in toSection {
			if fromSection[toCell.cell] != nil {
				orderedExistedCellsTo.append(toCell)
			} else {
				toAdd.append(toCell.index)
			}
		}
		
		if toMove.isEmpty {
			toMove = recognizeCellsMove(existedElementsIndexes: existedCellIndexes
				, existedElementsFrom: orderedExistedCellsFrom
				, existedElementsTo: orderedExistedCellsTo)
		}

		let cellsTransformations = CellsAnimations(toInsert: toAdd
			, toDelete: toRemove
			, toMove: toMove
			, toUpdate: []
			, toDeferredUpdate: toDeferredUpdate)
		
		return cellsTransformations
		
	}
	
	
	
	
	private func recognizeCellsMove(existedElementsIndexes: [Section.Cell : (from: IndexPath, to: IndexPath)], existedElementsFrom: [IndexedCell<Section.Cell>], existedElementsTo: [IndexedCell<Section.Cell>]) -> [(from: IndexPath, to: IndexPath)] {
		
		
		func calculateCellMove(orderedToSequence: [IndexedCell<Section.Cell>]) -> Set<Section.Cell> {
			
			var toMoveElements = Set<Section.Cell>()
			
			for value in orderedToSequence {
				
				let toCell = value.cell
				let (fromIndex, toIndex) = existedElementsIndexes[toCell]!
				
				guard fromIndex != toIndex else { continue }
				guard !toMoveElements.contains(toCell) else { continue }
				
				var elementsBeforeFrom: Set<Section.Cell> = []
				var elementsAfterFrom: Set<Section.Cell> = []
				var elementsBeforeTo: Set<Section.Cell> = []
				var elementsAfterTo: Set<Section.Cell> = []
				
				for cell in existedElementsFrom where cell.cell != value.cell {
					
					if cell.index.row < fromIndex.row {
						elementsBeforeFrom.insert(cell.cell)
					} else if cell.index.row > fromIndex.row {
						elementsAfterFrom.insert(cell.cell)
					}
				}
				
				for cell in existedElementsTo where cell.cell != value.cell {
					if cell.index.row < toIndex.row {
						elementsBeforeTo.insert(cell.cell)
					} else if cell.index.row > toIndex.row {
						elementsAfterTo.insert(cell.cell)
					}
				}
				
				let moveFromTopToBottom = elementsBeforeTo.subtracting(elementsBeforeFrom)
				let moveFromBottomToTop = elementsAfterTo.subtracting(elementsAfterFrom)
				
				toMoveElements.formUnion(moveFromTopToBottom)
				toMoveElements.formUnion(moveFromBottomToTop)
			}
			
			return toMoveElements
		}
		
		
		let toMoveSequence: Set<Section.Cell>
		switch cellMoveCalculatingStrategy {
		case .top:
			toMoveSequence = calculateCellMove(orderedToSequence: existedElementsTo.sorted(by: { $0.index.row > $1.index.row }))
			
		case .bottom:
			toMoveSequence = calculateCellMove(orderedToSequence: existedElementsTo.sorted(by: { $0.index.row < $1.index.row }))
			
		case .directRecognition:
			// With direct recognition move recognizes with insertions and deletions
			return []
		}
		
		return toMoveSequence.reduce(into: []) {
			let move = existedElementsIndexes[$1]!
			if move.from != move.to {
				$0.append(existedElementsIndexes[$1]!)
			}
		}
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




private struct IndexedCell<Element> {
	
	let cell: Element
	
	let index: IndexPath
	
}




















