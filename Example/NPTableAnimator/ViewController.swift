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
	
	public typealias UpdateCellType = String
	
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
		let cells = [MyCell(id: "6144a9cc-85be-430e-91f9-02ba7875b99a", updateField: "мет_1513761009.891"), MyCell(id: "01ca1615-01b0-731b-2144-9612e1958c19", updateField: "мет_1513760850.515"), MyCell(id: "01971613-014c-6917-0157-b913614f0b18", updateField: "мет_1513756032.948"), MyCell(id: "55d76c15-0844-45e1-8d41-4cc245a94b48", updateField: "мет_1513659868.054"), MyCell(id: "01ad1619-01c1-691d-31e6-1e1081cb8816", updateField: "мет_1513594370.461"), MyCell(id: "01c31610-01b4-591f-f17a-511c2189bb13", updateField: "мет_1513339294.34"), MyCell(id: "8b682b1d-7561-4665-84c9-50d8682c055b", updateField: "мет_1512996044.11"), MyCell(id: "01761612-0154-3512-2144-941ad18a0410", updateField: "мет_1512721548.355"), MyCell(id: "01d21612-01bd-3118-6112-5f14f1eafc1a", updateField: "мет_1512711149.897"), MyCell(id: "f557d8ff-0097-4a2c-a901-0e63bd49f6cc", updateField: "мет_1512649908.115"), MyCell(id: "017c1612-010e-3014-413a-0812f15bf61a", updateField: "мет_1512650689.975"), MyCell(id: "f1ca27b4-c909-476a-bce4-8f7e03a7089c", updateField: "мет_1512626202.733"), MyCell(id: "0127161d-0134-2b11-81a7-4618d1f7f318", updateField: "мет_1512559621.02"), MyCell(id: "01641619-01a7-2b1f-31f7-f11e414dcf11", updateField: "мет_1512556009.254"), MyCell(id: "01b71618-0116-261f-1166-3d1d01e1fa1d", updateField: "мет_1512467671.287"), MyCell(id: "508237f4-5715-4c44-bf76-48018107fc72", updateField: "мет_1512461077.854"), MyCell(id: "011b1612-0163-0e1c-f1cc-d91f71c0eb1d", updateField: "мет_1512102887.94"), MyCell(id: "0166161e-017d-071e-d184-e71091248712", updateField: "мет_1512040012.444"), MyCell(id: "01091610-01ca-0710-510c-f41031b9ed15", updateField: "мет_1511955219.468"), MyCell(id: "01a31617-0113-0714-11ea-7f1c511e1d1c", updateField: "мет_1511951994.352"), MyCell(id: "01f1161f-01e5-061f-71cd-c01fb1cca01d", updateField: "мет_1511945274.372"), MyCell(id: "017b1510-f1c4-fc10-d134-041f81dda412", updateField: "мет_1511775164.308"), MyCell(id: "01f11518-f1a7-fc17-d13d-0d131197c517", updateField: "мет_1511775163.429"), MyCell(id: "01851516-f1d4-fc15-41f2-041b31d27315", updateField: "мет_1511766340.231"), MyCell(id: "0129151d-f162-e21f-e1d9-69136187af16", updateField: "мет_1511340507.036"), MyCell(id: "01841517-f110-d913-c123-28147112ae10", updateField: "мет_1511246933.297"), MyCell(id: "01e2151c-f125-c816-c1a3-201621cd2b14", updateField: "мет_1510902625.788"), MyCell(id: "01781515-f134-c411-d1cf-2912b1abc11d", updateField: "мет_1510905786.954"), MyCell(id: "01f61513-f127-b91b-c141-5711a1d2741f", updateField: "мет_1510659262.773"), MyCell(id: "01eb1514-f1f2-a61d-017f-441f3122b917", updateField: "мет_1510557070.709"), MyCell(id: "016e151c-f163-9a1a-916c-651aa13c0f14", updateField: "мет_1510130466.436"), MyCell(id: "016c1517-f170-5812-8176-bc1f81a10a16", updateField: "мет_1509025765.918"), MyCell(id: "014b151a-f136-5214-f174-4f1c51310f1a", updateField: "мет_1508933042.834"), MyCell(id: "08758d88-e3f6-4015-95a2-68a0d56e3fe9", updateField: "мет_1508829008.686"), MyCell(id: "01301512-f16b-3817-8107-1d1ee11a5319", updateField: "мет_1508481744.398"), MyCell(id: "0125151e-f1e7-151f-f134-1d1c01447c11", updateField: "мет_1508326035.717"), MyCell(id: "01fb151c-f1af-0e16-d125-1a1ba16e3d12", updateField: "мет_1507802418.143"), MyCell(id: "01971519-d166-5f18-8191-6a16e1956c17", updateField: "мет_1502450602.434"), MyCell(id: "01071518-d1ae-1c12-9167-8e16c172691e", updateField: "мет_1499752230.331")]
		
		let sections = MySection(id: 0, cells: cells)
		
		return MySequence(sections: [sections])
	}
	
	
	
	func test() {
		
	}
	
	
	func generateToList() -> MySequence {
		
		let cells = [MyCell(id: "6144a9cc-85be-430e-91f9-02ba7875b99a", updateField: "мет_1513761009.891"), MyCell(id: "01ca1615-01b0-731b-2144-9612e1958c19", updateField: "мет_1513760850.515"), MyCell(id: "01971613-014c-6917-0157-b913614f0b18", updateField: "мет_1513756032.948"), MyCell(id: "55d76c15-0844-45e1-8d41-4cc245a94b48", updateField: "мет_1513659868.054"), MyCell(id: "01ad1619-01c1-691d-31e6-1e1081cb8816", updateField: "мет_1513594370.461"), MyCell(id: "01c31610-01b4-591f-f17a-511c2189bb13", updateField: "мет_1513339294.34"), MyCell(id: "8b682b1d-7561-4665-84c9-50d8682c055b", updateField: "мет_1512996044.11"), MyCell(id: "01761612-0154-3512-2144-941ad18a0410", updateField: "мет_1512721548.355"), MyCell(id: "01d21612-01bd-3118-6112-5f14f1eafc1a", updateField: "мет_1512711149.897"), MyCell(id: "f557d8ff-0097-4a2c-a901-0e63bd49f6cc", updateField: "мет_1512649908.115"), MyCell(id: "017c1612-010e-3014-413a-0812f15bf61a", updateField: "мет_1512650689.975"), MyCell(id: "f1ca27b4-c909-476a-bce4-8f7e03a7089c", updateField: "мет_1512626202.733"), MyCell(id: "0127161d-0134-2b11-81a7-4618d1f7f318", updateField: "мет_1512559621.02"), MyCell(id: "01641619-01a7-2b1f-31f7-f11e414dcf11", updateField: "мет_1512556009.254"), MyCell(id: "01b71618-0116-261f-1166-3d1d01e1fa1d", updateField: "мет_1512467671.287"), MyCell(id: "508237f4-5715-4c44-bf76-48018107fc72", updateField: "мет_1512461077.854"), MyCell(id: "011b1612-0163-0e1c-f1cc-d91f71c0eb1d", updateField: "мет_1512102887.94"), MyCell(id: "0166161e-017d-071e-d184-e71091248712", updateField: "мет_1512040012.444"), MyCell(id: "01091610-01ca-0710-510c-f41031b9ed15", updateField: "мет_1511955219.468"), MyCell(id: "01a31617-0113-0714-11ea-7f1c511e1d1c", updateField: "мет_1511951994.352"), MyCell(id: "01f1161f-01e5-061f-71cd-c01fb1cca01d", updateField: "мет_1511945274.372"), MyCell(id: "017b1510-f1c4-fc10-d134-041f81dda412", updateField: "мет_1511775164.308"), MyCell(id: "01f11518-f1a7-fc17-d13d-0d131197c517", updateField: "мет_1511775163.429"), MyCell(id: "01851516-f1d4-fc15-41f2-041b31d27315", updateField: "мет_1511766340.231"), MyCell(id: "0129151d-f162-e21f-e1d9-69136187af16", updateField: "мет_1511340507.036"), MyCell(id: "01841517-f110-d913-c123-28147112ae10", updateField: "мет_1511246933.297"), MyCell(id: "01e2151c-f125-c816-c1a3-201621cd2b14", updateField: "мет_1510902625.788"), MyCell(id: "01781515-f134-c411-d1cf-2912b1abc11d", updateField: "мет_1510905786.954"), MyCell(id: "01f61513-f127-b91b-c141-5711a1d2741f", updateField: "мет_1510659262.773"), MyCell(id: "01eb1514-f1f2-a61d-017f-441f3122b917", updateField: "мет_1510557070.709"), MyCell(id: "016e151c-f163-9a1a-916c-651aa13c0f14", updateField: "мет_1510130466.436"), MyCell(id: "016c1517-f170-5812-8176-bc1f81a10a16", updateField: "мет_1509025765.918"), MyCell(id: "014b151a-f136-5214-f174-4f1c51310f1a", updateField: "мет_1508933042.834"), MyCell(id: "08758d88-e3f6-4015-95a2-68a0d56e3fe9", updateField: "мет_1508829008.686"), MyCell(id: "01301512-f16b-3817-8107-1d1ee11a5319", updateField: "мет_1508481744.398"), MyCell(id: "0125151e-f1e7-151f-f134-1d1c01447c11", updateField: "мет_1508326035.717"), MyCell(id: "01fb151c-f1af-0e16-d125-1a1ba16e3d12", updateField: "мет_1507802418.143"), MyCell(id: "01651516-e1e0-f016-810b-9c1e2100031b", updateField: "мет_1507278046.984"), MyCell(id: "01ab1510-e1ec-cd18-817a-011f01fcf013", updateField: "мет_1506690029.3"), MyCell(id: "01971519-d166-5f18-8191-6a16e1956c17", updateField: "мет_1502450602.434"), MyCell(id: "01071518-d1ae-1c12-9167-8e16c172691e", updateField: "мет_1499752230.331")]
		
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









