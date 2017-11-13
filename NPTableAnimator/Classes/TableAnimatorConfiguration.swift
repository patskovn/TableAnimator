//
//  TableAnimatorConfiguration.swift
//  NPTableAnimator
//
//  Created by Nikita Patskov on 13.11.17.
//

import Foundation




open class TableAnimatorMoveRecognizer<Element> {
	
	open func recognizeMove(from: Element, to: Element) -> Bool {
		fatalError("You must override this function for move recognition. Default implementation is not valid.")
	}
	
}


open class TableAnimatorUpdateRecognizer<Element, InteractiveUpdate> {
	
	open func recognizeInteractiveUpdate(from: Element, to: Element) -> [InteractiveUpdate] {
		return []
	}
	
}


public enum MoveCalculatingStrategy<Element> {
	
	case top
	
	case bottom
	
	case directRecognition(TableAnimatorMoveRecognizer<Element>)
	
}


public enum UpdateCalculatingStrategy<Element, InteractiveUpdate> {
	
	case `default`
	
	case withInteractiveUpdateRecognition(TableAnimatorUpdateRecognizer<Element, InteractiveUpdate>)
	
}
