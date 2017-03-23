//
//  ViewController.swift
//  NPTableAnimator
//
//  Created by Nikita Patskov on 03/23/2017.
//  Copyright (c) 2017 Nikita Patskov. All rights reserved.
//

import UIKit
import NPTableAnimator


func == (lhs: MySection, rhs: MySection) -> Bool {
	let order = Calendar.current.compare(lhs.firstCellDate, to: rhs.firstCellDate, toGranularity: .day)
	return order == .orderedSame
}


func == (lhs: MyCell, rhs: MyCell) -> Bool {
	return lhs.id == rhs.id
}


struct MySection: TableAnimatorSection {
	
	typealias Cell = MyCell
	
	typealias UpdateCellType = Date
	
	typealias MoveCellType = Int
	
	
	var hashValue: Int {
		return firstCellDate.hashValue
	}
	
	let firstCellDate: Date
	
	var cells: [MyCell]
	
	var updateField: Date {
		return firstCellDate
	}
	
	var moveField: Int {
		return 0
	}
	
}


struct MyCell: TableAnimatorCell {
	
	typealias UpdateCellType = Date
	
	typealias MoveCellType = Date
	
	let id: String
	let timestamp: Date
	let dateSend: Date
	
	var hashValue: Int {
		return id.hashValue
	}
	
	var updateField: Date {
		return timestamp
	}
	
	var moveField: Date {
		return dateSend
	}
	
}


struct MySequenceIterator: IteratorProtocol {
	
	typealias Element = MySection
	
	let sequence: MySequence
	
	init(sequence: MySequence) {
		self.sequence = sequence
	}
	
	mutating func next() -> MySection? {
		
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


struct MySequence: TableAnimationSequence {
	
	typealias Iterator = MySequenceIterator
	
	/// Returns an iterator over the elements of this sequence.
	public func makeIterator() -> MySequenceIterator {
		return MySequenceIterator(sequence: self)
	}
	
	
	typealias Section = MySection
	
	var sections: [MySection]
	
}



class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
		
		
		let fromList = MySequence(sections: [])
		let toList = MySequence(sections: [])
		
		let exceptionableAnimator = TableAnimationsExcaptionable<MySequence>()
		
		exceptionableAnimator.registerReloadExceptionComparingListClosure {
			fromList, toList in
			
			if fromList.sections.count == 0 && toList.sections.count == 0 {
				return true
			}
			
			return false
		}
		
		exceptionableAnimator.registerReloadException(key: "test", defaultPersistenceValue: Date()) {
			persistableValue in
			
			let myDate = persistableValue as! Date
			
			if myDate == Date() {
				return (true, Date())
			}
			
			return (false, myDate)
		}
		
		let result = exceptionableAnimator.buildAnimations(from: fromList, to: toList)
		
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

