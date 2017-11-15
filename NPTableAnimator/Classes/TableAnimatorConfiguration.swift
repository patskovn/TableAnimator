//
//  TableAnimatorConfiguration.swift
//  NPTableAnimator
//
//  Created by Nikita Patskov on 13.11.17.
//

import Foundation




/// You should implement this if your sections or cells has special *sortKey*. Details are described in **MoveCalculatingStrategy** description.
open class TableAnimatorMoveRecognizer<Element> {
	
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



/// You shold implement this if your sections or cells has interactive update behavior. Details are described in **UpdateCalculatingStrategy** description.
open class TableAnimatorUpdateRecognizer<Element, InteractiveUpdate> {
	
	/// Animator asks your help to recognize, that new element has only updates, that should not cause cell height change.
	///
	/// - Parameters:
	///   - from: Old element in sequence.
	///   - to: New element in sequence.
	/// - Returns: Array of interactive updates.
	/// - Note: If your cell should change its size with new element, you sould return empty list and have proper implementation of **TableAnimatorUpdatable**.
	open func recognizeInteractiveUpdate(from: Element, to: Element) -> [InteractiveUpdate] {
		return []
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




/** **UpdateCalculatingStrategy** describes algorhytm for detecting sections and cells updates.

When update happenes, cell can apply its animation without recalculating its size.
For implementing that behavior you may provide specal **TableAnimatorUpdateRecognizer**.
Animator will do next:
	1. TableAnimator checks setted strategy while comparing old cell and new cell for updates
		1. If *default* will used, animator compare **TableAnimatorUpdatable.updateField** of old cell and new cell.
		If its equals, animator continue iteration, if its not, animator put old cell index into **CellsAnimations.toUpdate** array.
		2. If *withInteractiveUpdateRecognition*, animator asks **TableAnimatorUpdateRecognizer** for interactive updates recognition.
			1. If **TableAnimatorUpdateRecognizer** returned empty list, animator goto 1.1
			2. If **TableAnimatorUpdateRecognizer** returned some sequence, animatir put old cell index into **CellsAnimations.toInteractiveUpdate**
	2. TableAnimator calculate all item moves, then looking for intersects of move and update and delete intersected elements from **CellsAnimations.toUpdate**
	and put updated elements in **CellsAnimations.toDeferredUpdate** based on new element index.
- Note: InteractiveUpdate works only for cells, not for sections. Sections update calculating use *default* strategy all the time.

*/
public enum UpdateCalculatingStrategy<Element, InteractiveUpdate> {
	
	case `default`
	
	case withInteractiveUpdateRecognition(TableAnimatorUpdateRecognizer<Element, InteractiveUpdate>)
	
}
