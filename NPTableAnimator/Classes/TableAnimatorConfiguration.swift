//
//  TableAnimatorConfiguration.swift
//  NPTableAnimator
//
//  Created by Nikita Patskov on 13.11.17.
//

import Foundation



/// Configuration, that TableAnimator will use for calculations.
public struct TableAnimatorConfiguration<Section: TableAnimatorSection> {
	
	/// You may provide algorhytm for calculating cells move here. Details are described in **MoveCalculatingStrategy** description.
	public let cellMoveCalculatingStrategy: MoveCalculatingStrategy<Section.Cell>
	
	/// You may provide algorhytm for calculating sections move here. Details are described in **MoveCalculatingStrategy** description.
	public let sectionMoveCalculatingStrategy: MoveCalculatingStrategy<Section>
	
	
	
	/** Flag for configuring feed consistency checking. Adds additional check to cells uniqueness. Default is true.
	
	Section like
	
	[0, 1, 2, 3]
	will pass validation cause all elements in section are unique, but
	
	[0, 0, 1, 2]
	will throw **TableAnimatorError.inconsistencyError**.
	By setting this property to *false*, you guarantee that all cells are unique.
	If you set this flag to *false* and pass not unique items, animator may return wrong calculations.
	*/
	public let isConsistencyValidationEnabled: Bool
	
	
	public init(cellMoveCalculatingStrategy: MoveCalculatingStrategy<Section.Cell>,
																  sectionMoveCalculatingStrategy: MoveCalculatingStrategy<Section>,
																  isConsistencyValidationEnabled: Bool) {
		self.cellMoveCalculatingStrategy = cellMoveCalculatingStrategy
		self.sectionMoveCalculatingStrategy = sectionMoveCalculatingStrategy
		self.isConsistencyValidationEnabled = isConsistencyValidationEnabled
		
	}
	
	
	public init() {
		self.cellMoveCalculatingStrategy = .top
		self.sectionMoveCalculatingStrategy = .top
		self.isConsistencyValidationEnabled = true
	}
	
}




/// You should implement this if your sections or cells has special *sortKey*. Details are described in **MoveCalculatingStrategy** description.
open class TableAnimatorMoveRecognizer<Element> {
	
	public init() {}
	
	/// Animator asks your help to recognize, that element changed its position.
	///
	/// - Parameters:
	///   - from: Old element in sequence.
	///   - to: New element in sequence.
	/// - Returns: Boolean value that indicates element move.
	open func recognizeMove(from: Element, to: Element) -> Bool {
		fatalError("You must override this function for move recognition. Default implementation is not valid.")
	}
	
}




/** **MoveCalculatingStrategy** describes algorhytm for detecting sections and cells move.
The sipliest scenario for animator is when you pass **TableAnimatorMoveRecognizer** to *directRecognition* strategy.
So if move recognizer say that he recognized move between two elements, animator just mark element as moved.
For example:


		struct ChatViewModel {
			lastSendedMessageDate: Date
		}

		let oldList: ChatViewModel = [chatViewModel1, chatViewModel2, chatViewModel3]
		let newList: ChatViewModel = [chatViewModel2, chatViewModel1, chatViewModel3]

Your move recognizer may say, that *chatViewModel2.lastSendedMessageDate* changed, so animator will detect it and undarstand that just *chatViewModel2* moved.

If you not pass move recognizer and choose *.top* or *.bottom* move strategy recognition, animator will perform another move detecting algorhytm.
If you look and *oldList* and *newList* closer, you will see that changes could happen severel ways.

	1. *chatViewModel2* may move up (or left in array)
	2. *chatViewModel1* may move down (or right in array)
	3. *chatViewModel1* may move up, *chatViewModel2* may move down at the same time.

When you pass move recognizer, you say which cells moves directly, but if you choose *.up* strategy, table animator will say that *chatViewModel2* moved up
and if you choose *.down* strategy, he will say that *chatViewModel1* moved down.

Actually there is not so much difference in animation between this two changes, but for **perfect** animation, you should prefer pass **TableAnimatorMoveRecognizer**.

*/
public enum MoveCalculatingStrategy<Element> {
	
	case top
	
	case bottom
	
	case directRecognition(TableAnimatorMoveRecognizer<Element>)
	
}

