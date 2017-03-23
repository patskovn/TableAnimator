//
//  NPTableViewAnimator.swift
//  NPTableViewAnimator
//
//  Created by Nikita Patskov on 14.03.17.
//  Copyright © 2017 Nikita Patskov. All rights reserved.
//

import Foundation



open class TableAnimator<Section: TableAnimatorSection> {
	
	
	open func buildAnimations(from fromList: [Section], to toList: [Section]) -> TableAnimations {
		
		let sectionTransformResult = makeSectionTransformations(from: fromList, to: toList)
		
		let sectionAnimations = TableAnimations.Sections(toInsert: sectionTransformResult.toAdd
			, toDelete: sectionTransformResult.toRemove
			, toMove: sectionTransformResult.toMove
			, toUpdate: sectionTransformResult.toUpdate)
		
		var cellsAnimations = TableAnimations.Cells(toInsert: [], toDelete: [], toMove: [], toUpdate: [])
		
		for index in 0 ..< sectionTransformResult.existedSectionFromList.count {
			
			let fromIndex = sectionTransformResult.existedSectionFromList[index]
			let toIndex = sectionTransformResult.existedSectionToList[index]
			
			let fromSection = fromList[fromIndex]
			let toSection = toList[toIndex]
			
			let cellTransforms = makeSingleSectionTransformation(from: fromSection, fromSectionIndex: fromIndex, to: toSection, toSectionIndex: toIndex)
			
			cellsAnimations.add(another: cellTransforms)
			
		}
		
		
		return TableAnimations(sections: sectionAnimations, cells: cellsAnimations)
	}
	
	
	
	private func makeSectionTransformations(from fromList: [Section], to toList: [Section]) -> SectionsTransformationResult {
		
		var toAdd = IndexSet()
		var toRemove = IndexSet()
		var toMove = [(from: Int, to: Int)]()
		var toUpdate = IndexSet()
		
		var existedSectionInFromList: [Int] = []
		var existedSectionInToList: [Int] = []
		
		
		for (index, section) in fromList.enumerated() {
			
			if let indexInNewSection = toList.index(of: section) {
				
				let newSection = toList[indexInNewSection]
				
				if section.updateField != newSection.updateField {
					toUpdate.insert(index)
					
				} else {
					existedSectionInFromList.append(index)
				}
				
				
				if index != indexInNewSection {
					toMove.append((from: index, to: indexInNewSection))
				}
				
			} else {
				toRemove.insert(index)
			}
			
		}
		
		
		for (index, section) in toList.enumerated() {
			if !fromList.contains(section) {
				toAdd.insert(index)
			} else if section.updateField == section.updateField {
				existedSectionInToList.append(index)
			}
		}
		
		
		let result = SectionsTransformationResult(toAdd: toAdd
			, toRemove: toRemove
			, toMove: toMove
			, toUpdate: toUpdate
			, existedSectionFromList: existedSectionInFromList
			, existedSectionToList: existedSectionInToList)
		
		return result
		
	}
	
	
	
	private func makeSingleSectionTransformation(from fromSection: Section, fromSectionIndex: Int, to toSection: Section, toSectionIndex: Int) -> TableAnimations.Cells {
		
		var toAdd = [IndexPath]()
		var toRemove = [IndexPath]()
		var toUpdate = [IndexPath]()
		var toMove = [(from: IndexPath, to: IndexPath)]()
		
		
		
		for (index, cell) in fromSection.cells.enumerated() {
			if !toSection.cells.contains(cell) {
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
				
				
				if indexInOldList != index {
					let fromPath = IndexPath(row: indexInOldList, section: toSectionIndex)
					toMove.append((from: fromPath, to: path))
				}
				
				
			} else {
				toAdd.append(path)
				
			}
			
		}
		
		let cellsTransformations = TableAnimations.Cells(toInsert: toAdd
			, toDelete: toRemove
			, toMove: toMove
			, toUpdate: toUpdate)
		
		return cellsTransformations
		
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


























