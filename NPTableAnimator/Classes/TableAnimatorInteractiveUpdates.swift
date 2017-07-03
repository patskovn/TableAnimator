//
//  NPTableViewAnimator.swift
//  NPTableViewAnimator
//
//  Created by Nikita Patskov on 14.03.17.
//  Copyright © 2017 Nikita Patskov. All rights reserved.
//

import Foundation



open class TableAnimatorInteractiveUpdates<InteractiveUpdate, Section: TableAnimatorSection>: TableAnimator<Section> {
	
	private let updatesRecognitionClosure: (_ from: Section.Cell, _ to: Section.Cell) -> [InteractiveUpdate]
	
	public init(preferredMoveDirection: PreferredMoveDirection = .top, interactiveUpdatesRecognition: @escaping (_ from: Section.Cell, _ to: Section.Cell) -> [InteractiveUpdate]) {
		self.updatesRecognitionClosure = interactiveUpdatesRecognition
		super.init(preferredMoveDirection: preferredMoveDirection)
	}
	
	
	open override func buildAnimations(from fromList: [Section], to toList: [Section]) -> (sections: SectionsAnimations, cells: CellsAnimationsInteractived<InteractiveUpdate>) {
		
		let sectionTransformResult = makeSectionTransformations(from: fromList, to: toList)
		
		let sectionAnimations = SectionsAnimations(toInsert: sectionTransformResult.toAdd
			, toDelete: sectionTransformResult.toRemove
			, toMove: sectionTransformResult.toMove
			, toUpdate: sectionTransformResult.toUpdate)
		
		let cellsAnimations = CellsAnimationsInteractived<InteractiveUpdate>(toInsert: [], toDelete: [], toMove: [], toUpdate: [], toInteractiveUpdate: [])
		
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
	
	
	
	
	override func makeSingleSectionTransformation(from fromSection: Section, fromSectionIndex: Int, to toSection: Section, toSectionIndex: Int) -> CellsAnimationsInteractived<InteractiveUpdate> {
		
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
		
		let cellsTransformations = CellsAnimationsInteractived<InteractiveUpdate>(toInsert: toAdd
			, toDelete: toRemove
			, toMove: toMove
			, toUpdate: toUpdate
			, toInteractiveUpdate: toInteractiveUpdate)
		
		return cellsTransformations
		
	}
	
	
}

























