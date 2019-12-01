//
//  Helpers.swift
//  NPTableAnimator
//
//  Created by Admin on 12/07/2018.
//

import UIKit


protocol EmptyCheckableSequence: class {
    var isEmpty: Bool { get }
}

extension UIView {
    
    var isActuallyResponder: Bool {
        if isFirstResponder {
            return true
        }
        for subview in subviews {
            if subview.isActuallyResponder {
                return true
            }
        }
        
        return false
    }
    
}
