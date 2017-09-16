//
//  NPTableViewAnimator.swift
//  NPTableViewAnimator
//
//  Created by Nikita Patskov on 14.03.17.
//  Copyright © 2017 Nikita Patskov. All rights reserved.
//

import Foundation


public enum PreferredMoveDirection {
	
	case top
	
	case bottom
	
}


public enum TableAnimatorError: Error {
	
	
	/// This error happenes, when u have two equals entityes etc.
	case incosistencyError
	
}


open class TableAnimator<Section: TableAnimatorSection, InteractiveUpdate> {
	
	private let updatesRecognitionClosure: (_ from: Section.Cell, _ to: Section.Cell) -> [InteractiveUpdate]
	
	private let preferredMoveDirection: PreferredMoveDirection
	
	public init(preferredMoveDirection: PreferredMoveDirection = .top, interactiveUpdatesRecognition: @escaping (_ from: Section.Cell, _ to: Section.Cell) -> [InteractiveUpdate]) {
		self.updatesRecognitionClosure = interactiveUpdatesRecognition
		self.preferredMoveDirection = preferredMoveDirection
	}
	
	open func buildAnimations(from fromList: [Section], to toList: [Section]) throws -> (sections: SectionsAnimations, cells: CellsAnimations<InteractiveUpdate>) {
		
		let sectionTransformResult = try makeSectionTransformations(from: fromList, to: toList)
		
		let sectionAnimations = SectionsAnimations(toInsert: sectionTransformResult.toAdd
			, toDelete: sectionTransformResult.toRemove
			, toMove: sectionTransformResult.toMove
			, toUpdate: sectionTransformResult.toUpdate)
		
		var cellsAnimations = CellsAnimations<InteractiveUpdate>(toInsert: [], toDelete: [], toMove: [], toUpdate: [], toInteractiveUpdate: [])
		
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
	
	
	
	private func makeSectionTransformations(from fromList: [Section], to toList: [Section]) throws -> SectionsTransformationResult {
		
		var toAdd = IndexSet()
		var toRemove = IndexSet()
		var toUpdate = IndexSet()
		
		var existedSectionIndecies: [(Section, (from: Int, to: Int))] = []
		var orderedExistedSectionsFrom: [(index: Int, section: Section)] = []
		var orderedExistedSectionsTo: [(index: Int, section: Section)] = []
		
		
		for (index, section) in fromList.enumerated() {
			
			if let indexInNewSection = toList.index(of: section) {
				
				let newSection = toList[indexInNewSection]
				
				if section.updateField != newSection.updateField {
					toUpdate.insert(index)
					
				} else {
					orderedExistedSectionsFrom.append((index, section))
					existedSectionIndecies.append((section, (index, 0)))
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
				
				guard let existedIndex = existedSectionIndecies.index(where: { $0.0 == section })
					else { throw TableAnimatorError.incosistencyError }
				
				existedSectionIndecies[existedIndex].1.to = index
			}
		}
		
		
		let toMove = try recognizeSectionsMove(existedSectionIndecies: existedSectionIndecies, existedSectionsFrom: orderedExistedSectionsFrom, existedSectionsTo: orderedExistedSectionsTo)
		
		let result = SectionsTransformationResult(toAdd: toAdd
			, toRemove: toRemove
			, toMove: toMove
			, toUpdate: toUpdate
			, existedSectionFromList: orderedExistedSectionsFrom.map{ $0.index }
			, existedSectionToList: orderedExistedSectionsTo.map{ $0.index })
		
		return result
		
	}
	
	
	
	
	private func recognizeSectionsMove(existedSectionIndecies: [(Section, (from: Int, to: Int))], existedSectionsFrom: [(index: Int, section: Section)], existedSectionsTo: [(index: Int, section: Section)]) throws -> [(from: Int, to: Int)] {
		
		var toMove = [(from: Int, to: Int)]()
		
		var toMoveSections = [Section]()
		
		let toIndexCalculatingClosure: (Int) -> Int
		let toEnumerateList: [(index: Int, section: Section)]
		
		
		switch preferredMoveDirection {
		case .top:
			toEnumerateList = existedSectionsTo.reversed()
			
			toIndexCalculatingClosure = { existedSectionsTo.count - $0 - 1 }
			
		case .bottom:
			toEnumerateList = existedSectionsTo
			
			toIndexCalculatingClosure = { $0 }
			
		}
		
		
		for (anIndex, value) in toEnumerateList.enumerated() {
			
			let toSection = value.section
			
			let indexTo = toIndexCalculatingClosure(anIndex)
			
			guard let indexFrom = existedSectionsFrom.index(where: { $0.section == toSection })
				, let existedSectionIndex = existedSectionIndecies.index(where: { $0.0 == toSection })
				else { throw TableAnimatorError.incosistencyError }
			
			
			
			let (fromIndex, toIndex) = existedSectionIndecies[existedSectionIndex].1
			
			
			guard fromIndex != toIndex else { continue }
			guard !toMoveSections.contains(toSection) else { continue }
			
			
			let sectionsBeforeFrom = existedSectionsFrom[0 ..< indexFrom].map{ $0.section }
			let sectionsAfterFrom = existedSectionsFrom[indexFrom + 1 ..< existedSectionsFrom.count].map{ $0.section }
			
			let sectionsBeforeTo = existedSectionsTo[0 ..< indexTo].map{ $0.section }
			let sectionsAfterTo = existedSectionsTo[indexTo + 1 ..< existedSectionsTo.count].map{ $0.section }
			
			let moveFromTopToBottom = sectionsBeforeTo.filter{ !sectionsBeforeFrom.contains($0) }
			let moveFromBottomToTop = sectionsAfterTo.filter{ !sectionsAfterFrom.contains($0) }
			
			for section in moveFromTopToBottom where !toMoveSections.contains(section) {
				toMoveSections.append(section)
			}
			
			for section in moveFromBottomToTop where !toMoveSections.contains(section) {
				toMoveSections.append(section)
			}
		}
		
		
		for section in toMoveSections {
			let existedSectionIndex = existedSectionIndecies.index{ $0.0 == section }!
			let indexes = existedSectionIndecies[existedSectionIndex].1
			
			toMove.append(indexes)
		}
		
		return toMove
	}
	
	
	
	
	private func makeSingleSectionTransformation(from fromSection: Section, fromSectionIndex: Int, to toSection: Section, toSectionIndex: Int) -> CellsAnimations<InteractiveUpdate> {
		
		var toAdd = [IndexPath]()
		var toRemove = [IndexPath]()
		var toUpdate = [IndexPath]()
		var toInteractiveUpdate = [(IndexPath, [InteractiveUpdate])]()
		
		var existedCellIndecies: [Section.Cell : (from: Int, to: Int)] = [:]
		var orderedExistedCellsFrom: [(index: Int, element: Section.Cell)] = []
		var orderedExistedCellsTo: [(index: Int, element: Section.Cell)] = []
		
		
		for (index, cell) in fromSection.cells.enumerated() {
			
			if toSection.cells.index(of: cell) != nil {
				orderedExistedCellsFrom.append((index, cell))
				existedCellIndecies[cell] = (index, 0)
				
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
					
					let updates = updatesRecognitionClosure(oldCell, cell)
					
					if updates.isEmpty {
						toUpdate.append(path)
					} else {
						toInteractiveUpdate.append((path, updates))
					}
					
				}
				
				orderedExistedCellsTo.append((index, cell))
				existedCellIndecies[cell]!.to = index
				
			} else {
				toAdd.append(path)
			}
			
		}
		
		let toMove = recognizeCellsMove(existedElementsIndecies: existedCellIndecies
			, existedElementsFrom: orderedExistedCellsFrom
			, existedElementsTo: orderedExistedCellsTo)
			.map {
				(from: IndexPath(row: $0.from, section: toSectionIndex)
					, to: IndexPath(row: $0.to, section: toSectionIndex))
		}
		
		let cellsTransformations = CellsAnimations<InteractiveUpdate>(toInsert: toAdd
			, toDelete: toRemove
			, toMove: toMove
			, toUpdate: toUpdate
			, toInteractiveUpdate: toInteractiveUpdate)
		
		return cellsTransformations
		
	}
	

	
	
	
	
	
	
	private func recognizeCellsMove(existedElementsIndecies: [Section.Cell : (from: Int, to: Int)], existedElementsFrom: [(index: Int, element: Section.Cell)], existedElementsTo: [(index: Int, element: Section.Cell)]) -> [(from: Int, to: Int)] {
		
		var toMove = [(from: Int, to: Int)]()
		
		var toMoveElements = Set<Section.Cell>()
		
		let toIndexCalculatingClosure: (Int) -> Int
		let toEnumerateList: [(index: Int, element: Section.Cell)]
		
		
		switch preferredMoveDirection {
		case .top:
			toEnumerateList = existedElementsTo.reversed()
			
			toIndexCalculatingClosure = { existedElementsTo.count - $0 - 1 }
			
		case .bottom:
			toEnumerateList = existedElementsTo
			
			toIndexCalculatingClosure = { $0 }
			
		}
		
		
		for (anIndex, value) in toEnumerateList.enumerated() {
			
			let toSection = value.element
			
			let indexTo = toIndexCalculatingClosure(anIndex)
			let indexFrom = existedElementsFrom.index{ $0.element == toSection }!
			
			let (fromIndex, toIndex) = existedElementsIndecies[toSection]!
			
			
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
		
		
		for element in toMoveElements {
			let indexes = existedElementsIndecies[element]!
			
			toMove.append(indexes)
		}
		
		return toMove
	}
	
	
}




struct SectionsTransformationResult {
	
	let toAdd: IndexSet
	let toRemove: IndexSet
	let toMove: [(from: Int, to: Int)]
	let toUpdate: IndexSet
	
	//Количество элементов в массивах должно совпадать
	let existedSectionFromList: [Int]
	let existedSectionToList: [Int]
	
}

























