# SBInAppPurchasing

[![Version](https://img.shields.io/cocoapods/v/SBInAppPurchasing.svg?style=flat)](http://cocoapods.org/pods/SBInAppPurchasing)
[![License](https://img.shields.io/cocoapods/l/SBInAppPurchasing.svg?style=flat)](http://cocoapods.org/pods/SBInAppPurchasing)
[![Platform](https://img.shields.io/cocoapods/p/SBInAppPurchasing.svg?style=flat)](http://cocoapods.org/pods/SBInAppPurchasing)

SBInAppPurchasing makes In App Purchasing easier. Written in Swift, Objective-C compatible.

**Features:**

- Checking if device is able to make payments
- Requesting list of IAPs
- Making purchases
- Restoring Purchases
- Callbacks and notifications

## Installation

SBInAppPurchasing is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "SBInAppPurchasing"
```

## Usage

####Use the SBInAppPurchasing Singleton:
```swift
import SBInAppPurchasing

let purchaser = SBInAppPurchasing.sharedInstance
```

####To check if a device can make payments:

Some devices make not be able to make payments, for not permitted by parental controls. You shoudl always check if the device can make payments before making a purchase

```swift
if (purchaser.canMakePayments()){
	// Make a purchase
}
else{
	// Alert user IAPs are disabled
}
```

####To request list of products:
```swift
// Products from previous requests are cached.
//Check the products optional if you do not want to refresh
if let products = purchaser.products{
	// Products already downloaded
 	return   
}

// The identifiers you set up in iTunes Connect 
let identifiers = Set(["com.some.iap", "com.some.other.iap"])

purchaser.requestProducts(identifiers) { (products, error) in
            
	if let error = error{
		print("An error occurred: \(error.localizedDescription)")
		return
	}
            
	if let products = products{
		// Array of SKProduct received
	}
}
```
####To make a purchase with SKProduct
If you have called `requestProducts()` already, you can make a purchase using one of the returned products

```swift
purchaser.purchaseProduct(product)
```

####To make a purchase with identifier

It is also possible to make a purchase without calling `requestProducts()` by using the product identifier

```swift
purchaser.purchaseProductWithIdentifier("com.some.iap")
```

####Delegate Callbacks

An object implementing the `SBInAppPurchasingDelegate` protocol can recieve callbacks:

```swift
purchaser.delegate = someObject

// Recieves the following callbacks:
func purchaseCompleted(identifier: String)
func purchaseRestored(identifier: String)
func purchaseFailed(errorDescription: String)
```

####Notifications

Alternatively, objects can listen to notifications via NSNotificationCenter

```swift
NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(purchaseCompleted), name: SBInAppPurchaseCompletedNotification, object: nil)
NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(purchaseCompleted), name: SBInAppPurchaseRestoredNotification, object: nil)
NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(purchaseFailed), name: SBInAppPurchaseFailedNotification, object: nil)

func purchaseCompleted(notification: NSNotification){ 
	let identifier = notification.object       
}
    
func purchaseRestored(notification: NSNotification){    
	let identifier = notification.object       
}
    
func purchaseFailed(notification: NSNotification){     
	let error = notification.object        
}
```

## Author

Steve Barnegren, steve.barnegren@gmail.com

Follow me on twitter @SteveBarnegren

## License

SBInAppPurchasing is available under the MIT license. See the LICENSE file for more info.
