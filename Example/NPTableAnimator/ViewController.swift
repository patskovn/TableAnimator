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
	
	let id: String
	
	public var hashValue: Int {
		return id.hashValue
	}
	
	public var updateField: String
	
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
	
	let animator: TableAnimator<MySection> = {
		
		let config = TableAnimatorConfiguration<MySection>(cellMoveCalculatingStrategy: MoveCalculatingStrategy<MyCell>.top, sectionMoveCalculatingStrategy: MoveCalculatingStrategy<MySection>.bottom, isConsistencyValidationEnabled: true)
		let a = TableAnimator<MySection>.init(configuration: config)
		
		return a
	}()
	
	var animationCount = 0
	
	@IBAction func animate(_ sender: UIBarButtonItem) {
		
		let toList: MySequence
		
		if animationCount % 2 == 0 {
			toList = generateToList()
			
		} else {
			toList = generateFromList()
		}
		
		animationCount += 1
		
		let getCurrentListBlock: () -> [MySection]? = { [weak self] in
			guard let strong = self else { return nil }
			return strong.currentList.sections
		}
		
		let setNewListBlock: ([MySection]) -> Bool = { [weak self] toList in
			guard let strong = self else { return false }
			strong.currentList = MySequence(sections: toList)
			return true
		}
		
		tableView.apply(newList: toList.sections,
				    animator: animator,
				    getCurrentListBlock: getCurrentListBlock,
				    setNewListBlock: setNewListBlock,
				    rowAnimation: .fade,
				    completion: { print("Animation finished") },
				    error: { error in print("Oops, we have an error: \(error)") })
		
	}
	
	
	
	func generateFromList() -> MySequence {
		let cells = [MyCell(id: "Lorem", updateField: "1513766375.251"), MyCell(id: "ipsum", updateField: "1513765277.575"), MyCell(id: "dolor", updateField: "1513761009.891"), MyCell(id: "sit", updateField: "1513760850.515"), MyCell(id: "amet", updateField: "1513760822.751"), MyCell(id: "consectetur", updateField: "1513757906.778"), MyCell(id: "adipiscing", updateField: "1513757303.262"), MyCell(id: "elit", updateField: "1513759397.366"), MyCell(id: "sed", updateField: "1513756789.611"), MyCell(id: "eiusmod", updateField: "1513756791.426"), MyCell(id: "tempor", updateField: "1513756443.792"), MyCell(id: "incididunt", updateField: "1513756032.948"), MyCell(id: "labore", updateField: "1513753540.683"), MyCell(id: "dolore", updateField: "1513753648.081"), MyCell(id: "magna", updateField: "1513753646.2"), MyCell(id: "enim", updateField: "1513753643.751"), MyCell(id: "aliqua", updateField: "1513752177.573"), MyCell(id: "minim", updateField: "1513752175.253"), MyCell(id: "veniam", updateField: "1513752194.75"), MyCell(id: "quis", updateField: "1513752195.705")]

		
//		let cells = [MyCell.init(id: "1", updateField: "2")]
		
		let sections = MySection(id: 0, cells: cells)
		
		return MySequence(sections: [sections])
	}
	
	
	
	func test() {
		
	}
	
	
	func generateToList() -> MySequence {
		
		var cells = generateFromList().sections[0].cells
		cells.swapAt(2, 3)
		cells.remove(at: 0)
		cells.insert(.init(id: "Hello", updateField: "0"), at: 5)
		cells.remove(at: 8)
		
		let sections = MySection(id: 0, cells: cells)
		
		return MySequence(sections: [sections])
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
		
		cell.textLabel?.font = UIFont.systemFont(ofSize: 26)
		cell.textLabel?.text = String(currentList[indexPath.section].cells[indexPath.row].id)
		
		return cell
	}

}









