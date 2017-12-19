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
	
	let id: String
	
	public var hashValue: Int {
		return id.hashValue
	}
	
	public var updateField: Int
	
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
		
		let config = TableAnimatorConfiguration<MySection>.init(cellMoveCalculatingStrategy: MoveCalculatingStrategy<MyCell>.top, sectionMoveCalculatingStrategy: MoveCalculatingStrategy<MySection>.bottom, isConsistencyValidationEnabled: true)
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
		
//		'attempt to perform an insert and a move to the same index path (<NSIndexPath: 0xc000000000000116> {length = 2, path = 1 - 0})'
		
		let animations = try! animator.buildAnimations(from: currentList.sections, to: toList.sections)
		
		tableView.apply(animations: animations,
						setNewListBlock: { [weak self] in
							if let strong = self {
								strong.currentList = toList
								return true
							} else {
								return false
							}
						},
						completion: nil,
						cancelBlock: nil,
						rowAnimation: .fade)
	}
	
	
	
	func generateFromList() -> MySequence {
		
		
		let s1 = [MyCell.init(id: "123456", updateField: 0)]
		
		let fromList = ["762092_10001_7eb46772-48cf-4646-9867-1cccb77acd89", "762092_10001_20110216-02b4-4648-9817-3b7e0517eb0b", "762092_10001_78900e22-e010-4bc4-be69-3a296afe9d4f", "762092_10001_7616224a-ecbb-4a67-a88d-ec59a1df6ace"]
		
		let cells = fromList.enumerated().map{ MyCell(id: $0.element, updateField: 0) }
		
		let sections = MySection(id: 0, cells: cells)
		
		return MySequence(sections: [MySection(id: -1, cells: s1), sections])
	}
	
	
	func generateToList() -> MySequence {
		
		var toList = generateFromList().sections[1].cells.map { $0.id }
		toList.swapAt(0, 1)
		
		var cells = toList.enumerated().map{ MyCell(id: $0.element, updateField: 0) }
		cells[0].updateField = 1
		
		
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
		
		cell.textLabel?.text = String(currentList[indexPath.section].cells[indexPath.row].id)
		
		return cell
	}

}









