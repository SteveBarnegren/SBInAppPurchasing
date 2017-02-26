# SBInAppPurchasing

[![Version](https://img.shields.io/cocoapods/v/SBInAppPurchasing.svg?style=flat)](http://cocoapods.org/pods/SBInAppPurchasing)
[![License](https://img.shields.io/cocoapods/l/SBInAppPurchasing.svg?style=flat)](http://cocoapods.org/pods/SBInAppPurchasing)
[![Platform](https://img.shields.io/cocoapods/p/SBInAppPurchasing.svg?style=flat)](http://cocoapods.org/pods/SBInAppPurchasing)

SBInAppPurchasing makes In-App Purchasing easier. Written in Swift.

**Features:**

- Checking if device is able to make payments
- Requesting list of IAPs
- Making purchases
- Restoring Purchases
- Callbacks and notifications

Note that I haven't done any testing with Consumable IAPs at the current time.

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

let purchaser = SBInAppPurchasing.shared
```

####To check if a device can make payments:

Some devices make not be able to make payments, for instance, if not permitted by parental controls. You should always check if the device can make payments before making a purchase

```swift
if (purchaser.canMakePayments){
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
purchaser.purchase(product: someProduct) {
            (success: Bool) in
            
            if success {
            	// Unlock IAP
            }
            else{
	         	// Show error
            }   
}
```

####To make a purchase with identifier

It is also possible to make a purchase without calling `requestProducts()` by using the product identifier

```swift
purchaser.purchase(productWithIdentifier: "com.some.iap") {
            (success: Bool) in
            
            if success {
            		// Unlock IAP
            }
            else{
            		// Show error
            }   
}
```

####To restore Purchases

```swift
SBInAppPurchasing.shared.restorePurchases {
            (identifer: String) in
            
            if identifer == "com.some.iap" {
                // Unlock IAP
            }
        }
```

####Delegate Callbacks

Using the passed in closures is the easiest way to repond to purchase events, but an object implementing the `SBInAppPurchasingDelegate` protocol can recieve also receive callbacks for purchasing events, if required.  

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
NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(purchaseCompleted), name: .inAppPurchaseCompleted, object: nil)
NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(purchaseRestored), name: .inAppPurchaseRestored, object: nil)
NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(purchaseFailed), name: .inAppPurchaseFailed, object: nil)

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
