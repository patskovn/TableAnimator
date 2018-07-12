//
//  ApplyAnimationOptions.swift
//  NPTableAnimator
//
//  Created by Admin on 12/07/2018.
//

import Foundation

/// Additional options for applying animations.
public struct ApplyAnimationOptions: OptionSet {
    
    public var rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    /// If table have no cells at all, calls *reloadData()* instead of animatable apply.
    public static let withoutAnimationForEmptyTable = ApplyAnimationOptions(rawValue: 1 << 0)
    
    /// Deleting first responder cell row index from passed to table reload index paths.
    public static let excludeFirstResponderCellFromReload = ApplyAnimationOptions(rawValue: 1 << 1)
    
    /// Deleting first responder cell section index from passed to table reload index set.
    public static let excludeFirstResponderSectionFromReload = ApplyAnimationOptions(rawValue: 1 << 2)
    
    /// Not calls reload at all, but calls new list setting.
    public static let withoutActuallyRefreshTable = ApplyAnimationOptions(rawValue: 1 << 3)
    
    /// Removes all operations from apply operation queue before requesting new animation operation. Not cancel currently executing operation.
    public static let cancelPreviousAddedOperations = ApplyAnimationOptions(rawValue: 1 << 4)
}
