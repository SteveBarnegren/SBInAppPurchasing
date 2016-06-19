//
//  SBInAppPurchasing.swift
//  SwipeBall
//
//  Created by Steve Barnegren on 11/06/2016.
//  Copyright © 2016 Steve Barnegren. All rights reserved.
//

import Foundation
import StoreKit

public let SBInAppPurchaseCompletedNotification = "SBInAppPurchaseCompleted"
public let SBInAppPurchaseRestoredNotification = "SBInAppPurchaseRestored"
public let SBInAppPurchaseFailedNotification = "SBInAppPurchaseFailed"

@objc public protocol SBInAppPurchasingDelegate {
    func purchaseCompleted(identifier: String)
    func purchaseRestored(identifier: String)
    func purchaseFailed(errorDescription: String)
}

@objc public class SBInAppPurchasing: NSObject {
    
    public static let sharedInstance = SBInAppPurchasing()
    public var delegate: SBInAppPurchasingDelegate?
    public let debugLoggingEnabled = true

    private var productsRequest: SKProductsRequest?
    public var products: [SKProduct]?
    private var productRequestCompletion: ((products: [SKProduct]?, error: NSError?)->())?
    
    private override init() {
        /* SBInAppPurchasing can only be created as a singleton. Use SBInAppPurchasing.sharedInstance :) */
        
        super.init()
        SKPaymentQueue.defaultQueue().addTransactionObserver(self)
    }
    
    public func canMakePayments() -> Bool{
        return SKPaymentQueue.canMakePayments()
    }
    
    public func requestProducts(productIdentifiers: Set<String>, completion: ( (products: [SKProduct]?, error: NSError?) -> ())? ){
        
        print("Requesting Products")
        
        productsRequest?.cancel();
        
        productRequestCompletion = completion
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers);
        productsRequest?.delegate = self;
        productsRequest?.start()
        
    }
    
    public func purchaseProduct(product: SKProduct){
        
        print("Puchasing Product: \(product.productIdentifier)")
        
        let payment = SKPayment(product: product)
        SKPaymentQueue.defaultQueue().addPayment(payment)
    }
    
    public func purchaseProductWithIdentifier(identifier: String){
    
        let payment = SKMutablePayment()
        payment.productIdentifier = identifier
        SKPaymentQueue.defaultQueue().addPayment(payment)
    }
    
    public func restorePurchases() {
        SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
    }

}

// MARK: - SKProductsRequestDelegate

extension SBInAppPurchasing: SKProductsRequestDelegate {
    
    public func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
        print("Loaded list of products")

        // Print any invalid identifiers to the console
        for invalidIdentifier in response.invalidProductIdentifiers {
            print("Invalid Identifier: \(invalidIdentifier)")
        }
        
        // Print products
        for p in response.products {
            print("Found product: \(p.productIdentifier) \(p.localizedTitle) \(p.price.floatValue)")
        }
        
        // Store Products
        self.products = response.products
        
        // Call Completion handler
        self.productRequestCompletion?(products: response.products, error: nil)
        self.productRequestCompletion = nil
        
    }
    
    public func request(request: SKRequest, didFailWithError error: NSError) {
        print("Failed to load list of products.")
        print("Error: \(error.localizedDescription)")
        self.productRequestCompletion?(products: nil, error: error)
    }
    
    public func requestDidFinish(request: SKRequest) {
        print("Request did finish")
    }
    
}

// MARK: - SKPaymentTransactionObserver

extension SBInAppPurchasing: SKPaymentTransactionObserver {
    
    public func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch (transaction.transactionState) {
            case .Purchased:
                completeTransaction(transaction)
                break
            case .Failed:
                failedTransaction(transaction)
                break
            case .Restored:
                restoreTransaction(transaction)
                break
            case .Deferred:
                break
            case .Purchasing:
                break
            }
        }
    }
    
    private func completeTransaction(transaction: SKPaymentTransaction) {

        self.delegate?.purchaseCompleted(transaction.payment.productIdentifier);
        postPurchaseNotificationWithIdentifier(transaction.payment.productIdentifier, notificationName: SBInAppPurchaseCompletedNotification)
        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
    }
    
    private func restoreTransaction(transaction: SKPaymentTransaction) {
        
        guard let productIdentifier = transaction.originalTransaction?.payment.productIdentifier else { return }

        self.delegate?.purchaseRestored(transaction.payment.productIdentifier);
        postPurchaseNotificationWithIdentifier(productIdentifier, notificationName: SBInAppPurchaseRestoredNotification)
        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
    }
    
    private func failedTransaction(transaction: SKPaymentTransaction) {
        
        if transaction.error!.code != SKErrorCode.PaymentCancelled.rawValue {
            print("Transaction Error: \(transaction.error?.localizedDescription)")
        }
        
        self.delegate?.purchaseFailed(transaction.error?.localizedDescription ?? "Failed")
        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
        NSNotificationCenter.defaultCenter().postNotificationName(SBInAppPurchaseFailedNotification, object: transaction.error)
    }
    
    private func postPurchaseNotificationWithIdentifier(identifier: String?, notificationName: String) {
        
        guard let identifier = identifier else { return }
        NSNotificationCenter.defaultCenter().postNotificationName(notificationName, object: identifier)
    }
}

// MARK: - Logging

extension SBInAppPurchasing{

    func print(string: String){
        
        if self.debugLoggingEnabled {
            Swift.print("SBInAppPurchasing - \(string)")
        }
    }
}
