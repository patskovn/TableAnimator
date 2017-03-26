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


open class TableAnimator<Section: TableAnimatorSection> {
	
	private let preferredMoveDirection: PreferredMoveDirection
	
	public init(preferredMoveDirection: PreferredMoveDirection = .top) {
		self.preferredMoveDirection = preferredMoveDirection
	}
	
	open func buildAnimations(from fromList: [Section], to toList: [Section]) -> (sections: SectionsAnimations, cells: CellsAnimations) {
		
		let sectionTransformResult = makeSectionTransformations(from: fromList, to: toList)
		
		let sectionAnimations = SectionsAnimations(toInsert: sectionTransformResult.toAdd
			, toDelete: sectionTransformResult.toRemove
			, toMove: sectionTransformResult.toMove
			, toUpdate: sectionTransformResult.toUpdate)
		
		var cellsAnimations = CellsAnimations(toInsert: [], toDelete: [], toMove: [], toUpdate: [])
		
		for index in 0 ..< sectionTransformResult.existedSectionFromList.count {
			
			let fromIndex = sectionTransformResult.existedSectionFromList[index]
			let toIndex = sectionTransformResult.existedSectionToList[index]
			
			let fromSection = fromList[fromIndex]
			let toSection = toList[toIndex]
			
			let cellTransforms = makeSingleSectionTransformation(from: fromSection, fromSectionIndex: fromIndex, to: toSection, toSectionIndex: toIndex)
			
			cellsAnimations.add(another: cellTransforms)
			
		}
		
		
		return (sections: sectionAnimations, cells: cellsAnimations)
	}
	
	
	
	func makeSectionTransformations(from fromList: [Section], to toList: [Section]) -> SectionsTransformationResult {
		
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
				
				let existedIndex = existedSectionIndecies.index{ $0.0 == section }!
				
				existedSectionIndecies[existedIndex].1.to = index
			}
		}
		
		
		let toMove = recognizeSectionsMove(existedSectionIndecies: existedSectionIndecies, existedSectionsFrom: orderedExistedSectionsFrom, existedSectionsTo: orderedExistedSectionsTo)
		
		let result = SectionsTransformationResult(toAdd: toAdd
			, toRemove: toRemove
			, toMove: toMove
			, toUpdate: toUpdate
			, existedSectionFromList: orderedExistedSectionsFrom.map{ $0.index }
			, existedSectionToList: orderedExistedSectionsTo.map{ $0.index })
		
		return result
		
	}
	
	
	
	
	func recognizeSectionsMove(existedSectionIndecies: [(Section, (from: Int, to: Int))], existedSectionsFrom: [(index: Int, section: Section)], existedSectionsTo: [(index: Int, section: Section)]) -> [(from: Int, to: Int)] {
		
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
			let indexFrom = existedSectionsFrom.index{ $0.section == toSection }!
			
			let existedSectionIndex = existedSectionIndecies.index{ $0.0 == toSection }!
			
			
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
	
	
	
	
	func makeSingleSectionTransformation(from fromSection: Section, fromSectionIndex: Int, to toSection: Section, toSectionIndex: Int) -> CellsAnimations {
		
		var toAdd = [IndexPath]()
		var toRemove = [IndexPath]()
		var toUpdate = [IndexPath]()
		
		var toUpdateCells = Set<Section.Cell>()
		
		var existedCellIndecies: [Section.Cell : (from: Int, to: Int)] = [:]
		var orderedExistedCellsFrom: [(index: Int, element: Section.Cell)] = []
		var orderedExistedCellsTo: [(index: Int, element: Section.Cell)] = []
		
		
		for (index, cell) in fromSection.cells.enumerated() {
			
			if let indexInToList = toSection.cells.index(of: cell) {
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
					toUpdate.append(path)
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
		
		let cellsTransformations = CellsAnimations(toInsert: toAdd
			, toDelete: toRemove
			, toMove: toMove
			, toUpdate: toUpdate)
		
		return cellsTransformations
		
	}
	
	
	
	
	
	
	func recognizeCellsMove(existedElementsIndecies: [Section.Cell : (from: Int, to: Int)], existedElementsFrom: [(index: Int, element: Section.Cell)], existedElementsTo: [(index: Int, element: Section.Cell)]) -> [(from: Int, to: Int)] {
		
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


struct SingleSectionTransformationResult {
	
	let toAdd: [IndexPath]
	let toRemove: [IndexPath]
	let toUpdate: [IndexPath]
	let toMove: [(from: IndexPath, to: IndexPath)]
	
}


























