# NPTableAnimator

[![Version](https://img.shields.io/cocoapods/v/NPTableAnimator.svg?style=flat)](http://cocoapods.org/pods/NPTableAnimator)
[![License](https://img.shields.io/cocoapods/l/NPTableAnimator.svg?style=flat)](http://cocoapods.org/pods/NPTableAnimator)
[![Platform](https://img.shields.io/cocoapods/p/NPTableAnimator.svg?style=flat)](http://cocoapods.org/pods/NPTableAnimator)

## Requirements
iOS 8.0+ / OSX 10.9+ / watchOS 2.0+ &bull; Swift 4.0 / Xcode 9+

## Example
To run the example project, clone the repo, and run `pod install` from the Example directory first.

Import library for usage:
```swift
import NPTableAnimator
```

First of all, you need adopt your view model to **TableAnimatorCell** protocol: 

```swift
struct MyViewModel: TableAnimatorCell {

    let id: Int
    
    var hashValue: Int {
        return id.hashValue
    }
    
    var updateField: Date
    
    static func == (lhs: MyViewModel, rhs: MyViewModel) -> Bool {
         return lhs.id == rhs.id
    }
}
```
For proper and fast animation calculating your view model should adopt to Equatable and Hashable protocols. 
So you tell to animator how to calculate changes between cells, but tables have sections too, so you had to provide that information to animator. Your section should adopt to **TableAnimatorSection** protocol.

&bull; *Note: even if you have only one section, you had to provide section too. Just set default value for updateField and pass **true** in coparing function.*
```swift
struct MySection: TableAnimatorSection {

    let id: Int
    
    var cells: [MyCell]
    
    var updateField: Int
    
    static func == (lhs: MySection, rhs: MySection) -> Bool {
        return lhs.id == rhs.id
    } 
}
```

Then you should create animator instance for calculating animations and build animations between two lists:
```swift
let animator = TableAnimator<MySection>()
let animations = try! animator.buildAnimations(from: currentList, to: newList)
```

**animations** struct got sections and cells insertions, deletions, updates and moves which you may pass for updates.

```swift
tableView.beginUpdates()
self.currentList = newList

tableView.insertSections(animations.sections.toInsert, with: .fade)
tableView.deleteSections(animations.sections.toDelete, with: .fade)
tableView.reloadSections(animations.sections.toUpdate, with: .fade)
				
for (from, to) in animations.sections.toMove {
	tableView.moveSection(from, toSection: to)
}
				
tableView.reloadRows(animations.cells.toUpdate, with: .fade)
tableView.insertRows(at: animations.cells.toInsert, with: .fade)
tableView.deleteRows(at: animations.cells.toDelete, with: .fade)
tableView.reloadRows(at: animations.cells.toUpdate, with: .fade)

for (from, to) in animations.cells.toMove {
	tableView.moveRow(at: from, to: to)
}
tableView.endUpdates()

// You should call .reloadRows(_:with:) in another update circle cause of UITableView update bugs...
// Animator provide all updates in toUpdate only if toInsert, toDelete and toUpdate are empty 
// otherwise animator provides toDeferredUpdate array based on new cell indexes.
tableView.beginUpdates()
tableView.reloadRows(animations.cells.toDeferredUpdate, with: .fade)
tableView.endUpdates()
```

For your comfort animator may calculate and apply list. If you use code described above, you will see strange blink during update animation. Its not fatal but not cool. So animator may apply changes properly to your table. For that purposes you may use that code:
```swift

// We capturing `self` weakly cause of @escaping block. Each table has its onwn OperationQueue for animations synchronizing.
let getCurrentListBlock: () -> [MySection]? = { [weak self] in
    guard let strong = self else { return nil }
    return strong.currentList.sections
}
		
let setNewListBlock: ([MySection]) -> Bool = { [weak self] newList in
    guard let strong = self else { return false }
    strong.currentList = newList
    return true
}

// Note: - currentList **not** changed to newList instantly. That function only start applying and 
// adding request for change to newList into a queue.
tableView.apply(newList: newList,
                animator: animator,
                getCurrentListBlock: getCurrentListBlock,
                setNewListBlock: setNewListBlock,
                rowAnimation: .fade,
                completion: { print("Animation finished") },
                error: { error in print("Oops, we have an error: \(error)") })
```


## Installation

NPTableAnimator is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "NPTableAnimator"
```

## Author

Nikita Patskov, patskovn@yahoo.com

## License

NPTableAnimator is available under the MIT license. See the LICENSE file for more info.
