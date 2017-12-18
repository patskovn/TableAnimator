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
		
		let fromList = ["762092_10001_7eb46772-48cf-4646-9867-1cccb77acd89", "762092_10001_20110216-02b4-4648-9817-3b7e0517eb0b", "762092_10001_78900e22-e010-4bc4-be69-3a296afe9d4f", "762092_10001_7616224a-ecbb-4a67-a88d-ec59a1df6ace", "762092_10001_5bdb021a-71cb-46b2-8022-76173d088ed6", "762092_10001_0ec5f819-82b9-4d28-a6fe-1574e0460918", "762092_10001_fc8e8819-6d93-4d35-b799-2056f898ca33", "762092_10001_a6397e70-3626-4400-9916-e636879a0b02", "762092_10001_8b9ef2a1-0c45-4d31-ae16-4d792c698db1", "762092_10001_2149b04b-e3f2-4ea5-9b57-3e2e5f638e53", "762092_10001_18a53241-b8df-403a-a95b-9d0eb0c1e95b", "762092_10001_efa0feda-c15d-4829-9185-6959dbcb4925", "762092_10001_d00bd26e-34f5-47d7-a100-a00479b6d42c", "762092_10001_c4db9f97-65af-462b-a474-01fd1c376506", "762092_10001_bbbc1c46-a65c-42bd-ad52-900657e5e974", "762092_10001_b783197d-f2bd-4c90-8c90-0b81b186c4ee", "762092_10001_a9cd4975-343f-4125-8e0f-6baefc851f04", "762092_10001_6bc79485-5195-4c06-a43a-e28861dbfffd", "762092_10001_3d83ccf1-bc76-4e27-a4be-dfbd16f6cdcd", "762092_10001_3bb0804d-1890-4c6c-851e-43fa2ec4cadc", "762092_10001_1efe2094-dc9b-454c-bc1f-f1757e85e352", "762092_10001_07919e5a-cc0e-4b70-bd39-8ce1b50d487c", "762092_10001_f80a398b-2415-49fd-9a75-b971084fb62f", "762092_10001_e4f5c900-5e16-4e2d-9de9-6cf04c0baa2a", "762092_10001_e401e63d-7182-4932-b8a8-98dee6273a55", "762092_10001_d2600e67-396d-4982-a5b3-5726cc77fb6f", "762092_10001_af3fd204-d2dd-4156-9582-bbf3f7aca458", "762092_10001_a960971b-551d-42d2-b640-f2f4b1e5b234", "762092_10001_a0ac4e8b-f5ed-4403-8801-a9cc05fa736e", "762092_10001_9971709d-229d-47fb-9190-01526080c249", "762092_10001_94db51d9-0719-48e7-84d5-326048c09c31", "762092_10001_84005169-ee64-47d9-b7c6-e1fddd879d65", "762092_10001_7a1402fe-ef87-49af-8d98-7d5e8ea3d83f", "762092_10001_769cf7f9-5872-49f8-8eb9-99c9c1b9c3a2", "762092_10001_600d2822-4892-4d10-b107-f4a4a8501625", "762092_10001_3ee3da73-5c29-4893-89a3-71c56436343c", "762092_10001_368bb191-3c5c-4f0b-8e27-5dbf0756d6af", "762092_10001_3245d052-fecf-49ff-b470-260baea8ba5d", "762092_10001_30826f11-f6a3-4106-ad91-dd49978fe0b2"]
		
		let cells = fromList.enumerated().map{ MyCell(id: $0.element, updateField: 0) }
		
		let sections = MySection(id: 0, cells: cells)
		
		return MySequence(sections: [sections])
	}
	
	
	func generateToList() -> MySequence {
		
		var toList = generateFromList().sections[0].cells.map { $0.id }
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









