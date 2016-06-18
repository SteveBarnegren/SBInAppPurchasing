//
//  SBInAppPurchasing.swift
//  SwipeBall
//
//  Created by Steve Barnegren on 11/06/2016.
//  Copyright © 2016 Steve Barnegren. All rights reserved.
//

import Foundation
import StoreKit

let SBInAppPurchaseCompleted = "SBInAppPurchaseCompleted"
let SBInAppPurchaseRestored = "SBInAppPurchaseRestored"
let SBInAppPurchaseFailed = "SBInAppPurchaseFailed"

@objc public protocol SBInAppPurchasingDelegate {
    func purchaseCompleted(identifier: String)
    func purchaseRestored(identifier: String)
    func purchaseFailed(errorDescription: String)
}

@objc public class SBInAppPurchasing: NSObject {
    
    static let sharedInstance = SBInAppPurchasing()
    public var delegate: SBInAppPurchasingDelegate?

    private var productsRequest: SKProductsRequest?
    public var products: [SKProduct] = [SKProduct]()
    private var productRequestCompletion: (([SKProduct])->())?
    
    private override init() {
        /* SBInAppPurchasing can only be created as a singleton. Use SBInAppPurchasing.sharedInstance :) */
        
        super.init()
        SKPaymentQueue.defaultQueue().addTransactionObserver(self)
    }
    
    public func canMakePayments() -> Bool{
        return SKPaymentQueue.canMakePayments()
    }
    
    public func requestProducts(productIdentifiers: Set<String>, completion: ([SKProduct]) -> ()){
        
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
        self.productRequestCompletion?(response.products)
        
    }
    
    public func request(request: SKRequest, didFailWithError error: NSError) {
        print("Failed to load list of products.")
        print("Error: \(error.localizedDescription)")
        //productsRequestCompletionHandler?(success: false, products: nil)
        clearRequestAndHandler()
    }
    
    public func requestDidFinish(request: SKRequest) {
        print("Request did finish")
    }
    
    private func clearRequestAndHandler() {
        productsRequest = nil
        //productsRequestCompletionHandler = nil
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
        postPurchaseNotificationWithIdentifier(transaction.payment.productIdentifier, notificationName: SBInAppPurchaseCompleted)
        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
    }
    
    private func restoreTransaction(transaction: SKPaymentTransaction) {
        
        print("Transaction restored")
       
        guard let productIdentifier = transaction.originalTransaction?.payment.productIdentifier else { return }
        print("Transaction restored past guard")

        self.delegate?.purchaseRestored(transaction.payment.productIdentifier);
        postPurchaseNotificationWithIdentifier(productIdentifier, notificationName: SBInAppPurchaseRestored)
        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
    }
    
    private func failedTransaction(transaction: SKPaymentTransaction) {
        
        if transaction.error!.code != SKErrorCode.PaymentCancelled.rawValue {
            print("Transaction Error: \(transaction.error?.localizedDescription)")
        }
        
        self.delegate?.purchaseFailed(transaction.error?.localizedDescription ?? "Failed")
        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
        NSNotificationCenter.defaultCenter().postNotificationName(SBInAppPurchaseFailed, object: transaction.error)
    }
    
    private func postPurchaseNotificationWithIdentifier(identifier: String?, notificationName: String) {
        
        guard let identifier = identifier else { return }
        NSNotificationCenter.defaultCenter().postNotificationName(notificationName, object: identifier)
    }
}

// MARK: - Logging

extension SBInAppPurchasing{
    func print(string: String){
        Swift.print("SBInAppPurchasing - \(string)")
    }
}
