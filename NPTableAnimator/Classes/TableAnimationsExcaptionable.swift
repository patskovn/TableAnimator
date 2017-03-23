//
//  TableAnimationsExcaptionable.swift
//  NPTableViewAnimator
//
//  Created by Nikita Patskov on 21.03.17.
//  Copyright © 2017 Nikita Patskov. All rights reserved.
//

import Foundation


public enum TableAnimatorResult {
	
	case reloadData
	
	case animations(TableAnimations)
	
}


open class TableAnimationsExcaptionable<Sequence : TableAnimationSequence> {
	
	private let animator = TableAnimator<Sequence.Section>()
	private var comparingListClosure: ((Sequence, Sequence) -> Bool)?
	private var exceptionValuesDictionary = [String : Any?]()
	private var exceptionClosuresDictionary = [String : (Any?) -> (Bool, Any?)]()
	
	
	public init(){}
	
	
	open func registerReloadExceptionComparingListClosure(closure: ((Sequence, Sequence) -> Bool)?) {
		self.comparingListClosure = closure
	}
	
	
	open func registerReloadException<Type>(key: String, defaultPersistenceValue: Type?, comparingClosure: @escaping (Any?) -> (Bool, Type?)) {
		exceptionValuesDictionary[key] = defaultPersistenceValue
		exceptionClosuresDictionary[key] = comparingClosure
	}
	
	
	
	
	
	open func buildAnimations(from fromList: Sequence, to toList: Sequence) -> TableAnimatorResult {
		
		if isExceptionableTransformation(fromList: fromList, toList: toList) {
			return .reloadData
			
		} else {
			let animations = animator.buildAnimations(from: fromList.sections, to: toList.sections)
			return .animations(animations)
		}
		
	}
	
	
	
	private func checkExceptions() -> Bool {
		
		var shouldReload = false
		
		for (key, closure) in exceptionClosuresDictionary {
			
			let currentValue = exceptionValuesDictionary[key]!
			
			let (shouldReloadByClosure, newValue) = closure(currentValue)
			
			shouldReload = shouldReload || shouldReloadByClosure
			
			exceptionValuesDictionary[key] = newValue
			
			
		}
		
		return shouldReload
	}
	
	private func isExceptionableTransformation(fromList: Sequence, toList: Sequence) -> Bool {
		let comparingListClosureResult = comparingListClosure?(fromList, toList) ?? false
		let registeredExceptionsResult = checkExceptions()
		
		return comparingListClosureResult || registeredExceptionsResult
	}
	
}
