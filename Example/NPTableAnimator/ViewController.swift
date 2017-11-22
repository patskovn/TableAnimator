//
//  ViewController.swift
//  NPTableAnimator
//
//  Created by Nikita Patskov on 03/23/2017.
//  Copyright (c) 2017 Nikita Patskov. All rights reserved.
//

import UIKit
import NPTableAnimator


public func == (lhs: MySection, rhs: MySection) -> Bool {
	return lhs.id == rhs.id
}


public func == (lhs: MyCell, rhs: MyCell) -> Bool {
	return lhs.id == rhs.id
}


public struct MySection: TableAnimatorSection {
	
	public typealias Cell = MyCell
	
	public typealias UpdateCellType = Int
	
	
	public var hashValue: Int {
		return id.hashValue
	}
	
	let id: Int
	
	public var cells: [MyCell]
	
	public var updateField: Int {
		return 0
	}
	
	
	subscript(value: Int) -> MyCell {
		return cells[value]
	}
	
}


public struct MyCell: TableAnimatorCell {
	
	public typealias UpdateCellType = Int
	
	let id: Int
	
	public var hashValue: Int {
		return id.hashValue
	}
	
	public var updateField: Int {
		return 0
	}
	
}


public struct MySequenceIterator: IteratorProtocol {
	
	public typealias Element = MySection
	
	let sequence: MySequence
	
	init(sequence: MySequence) {
		self.sequence = sequence
	}
	
	mutating public func next() -> MySection? {
		
		let lastIndex = sequence.sections.count - 1
		var nextIndex = 0
		if (nextIndex > lastIndex) {
			return nil
		}
		let section = sequence.sections[nextIndex]
		nextIndex += 1
		return section
	}
	
}


public struct MySequence {
	
	typealias Iterator = MySequenceIterator
	
	/// Returns an iterator over the elements of this sequence.
	public func makeIterator() -> MySequenceIterator {
		return MySequenceIterator(sequence: self)
	}
	
	
	public typealias Section = MySection
	
	public var sections: [MySection]
	
	subscript(value: Int) -> MySection {
		return sections[value]
	}
}



class ViewController: UITableViewController {

	var currentList: MySequence! = nil
	
	private class UpdateRecognizer: TableAnimatorUpdateRecognizer<MySection.Cell, Void> {}
	
	let animator = TableAnimator<MySection, Void>()
	
	var animationCount = 0
	
	@IBAction func animate(_ sender: UIBarButtonItem) {
		
		let toList: MySequence
		
		if animationCount % 2 == 0 {
			toList = generateToList()
			
		} else {
			toList = generateFromList()
		}
		
		animationCount += 1
		
		let animations = try! animator.buildAnimations(from: currentList.sections, to: toList.sections)
		var conf = TableAnimatorConfiguration<MySection, Void>.init()
		
		
		tableView.beginUpdates()
		
		currentList = toList
		
		tableView.insertSections(animations.sections.toInsert, with: .fade)
		tableView.deleteSections(animations.sections.toDelete, with: .fade)
		
		for move in animations.sections.toMove {
			tableView.moveSection(move.from, toSection: move.to)
		}
		
		tableView.reloadSections(animations.sections.toUpdate, with: .none)
		
		tableView.insertRows(at: animations.cells.toInsert, with: .fade)
		tableView.deleteRows(at: animations.cells.toDelete, with: .fade)
		
		for move in animations.cells.toMove {
			tableView.moveRow(at: move.from, to: move.to)
		}
		
		tableView.endUpdates()
		
	}
	
	
	
	func generateFromList() -> MySequence {
		
		let cells = (1...6).map{ MyCell(id: $0) }
		
		let sections = MySection(id: 0, cells: cells)
		
		return MySequence(sections: [sections])
	}
	
	
	func generateToList() -> MySequence {
		
		let zeroCell = MyCell(id: 0)
		
		var result = MySection(id: 0, cells: [])
		
		result.cells.append(zeroCell)
		result.cells.append(currentList[0][2])
		result.cells.append(currentList[0][5])
		result.cells.append(currentList[0][4])
		result.cells.append(currentList[0][3])
		
		return MySequence(sections: [result])
	}
	
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		currentList = generateFromList()
		
    }

	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return currentList.sections.count
	}
	
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return currentList.sections[section].cells.count
	}
	
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = UITableViewCell()
		
		cell.textLabel?.text = String(currentList[indexPath.section].cells[indexPath.row].id)
		
		return cell
	}

}









