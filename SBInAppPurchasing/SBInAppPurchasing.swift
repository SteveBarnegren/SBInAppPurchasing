//
//  SBInAppPurchasing.swift
//  SwipeBall
//
//  Created by Steve Barnegren on 11/06/2016.
//  Copyright © 2016 Steve Barnegren. All rights reserved.
//

import Foundation
import StoreKit

extension Notification.Name {
    static let inAppPurchaseCompleted = NSNotification.Name("SBInAppPurchaseCompleted")
    static let inAppPurchaseRestored = NSNotification.Name("SBInAppPurchaseRestored")
    static let inAppPurchaseFailed = NSNotification.Name("SBInAppPurchaseFailed")
}

public protocol SBInAppPurchasingDelegate {
    func purchaseCompleted(identifier: String)
    func purchaseRestored(identifier: String)
    func purchaseFailed(errorDescription: String)
}

public class SBInAppPurchasing: NSObject {
    
    // MARK: - Types
    public typealias ProductPurchaseHandler = (_ success: Bool) -> ()
    public typealias ProductRestoreHandler = (_ identifier: String) -> ()

    // MARK: - Public
    public static let shared = SBInAppPurchasing()
    public var delegate: SBInAppPurchasingDelegate?
    public let debugLoggingEnabled = false

    public var canMakePayments: Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    public func requestProducts(productIdentifiers: Set<String>, completion: ( ([SKProduct]?, Error?) -> ())? ){
        
        print("Requesting Products")
        
        productsRequest?.cancel();
        
        productRequestCompletion = completion
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers);
        productsRequest?.delegate = self;
        productsRequest?.start()
        
    }
    
    public func purchase(product: SKProduct, handler: @escaping ProductPurchaseHandler){
        
        print("Puchasing Product: \(product.productIdentifier)")
        
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
        
        purchasehandlers[product.productIdentifier] = handler

    }
    
    public func purchase(productWithIdentifier identifier: String, handler: @escaping ProductPurchaseHandler){
    
        let payment = SKMutablePayment()
        payment.productIdentifier = identifier
        SKPaymentQueue.default().add(payment)
        
        purchasehandlers[identifier] = handler
    }
    
    public func restorePurchases(_ handler: @escaping ProductRestoreHandler) {
        
        restoreHandler = handler
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    // MARK: - private
    
    private var productsRequest: SKProductsRequest?
    public var products: [SKProduct]?
    fileprivate var productRequestCompletion: (([SKProduct]?, Error?)->())?
    fileprivate var purchasehandlers = [String : ProductPurchaseHandler]()
    fileprivate var restoreHandler: ProductRestoreHandler?

    private override init() {
        /* SBInAppPurchasing can only be created as a singleton. Use SBInAppPurchasing.shared */
        
        super.init()
        SKPaymentQueue.default().add(self)
    }
}

// MARK: - SKProductsRequestDelegate

extension SBInAppPurchasing: SKProductsRequestDelegate {
    
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
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
        self.productRequestCompletion?(response.products, nil)
        self.productRequestCompletion = nil
        
    }

    public func request(_ request: SKRequest, didFailWithError error: Error) {
        print("Failed to load list of products.")
        print("Error: \(error.localizedDescription)")
        self.productRequestCompletion?(nil, error)
    }
    
    public func requestDidFinish(_ request: SKRequest) {
        print("Request did finish")
    }
}

// MARK: - SKPaymentTransactionObserver

extension SBInAppPurchasing: SKPaymentTransactionObserver {
    
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch (transaction.transactionState) {
            case .purchased:
                completeTransaction(transaction: transaction)
                break
            case .failed:
                failedTransaction(transaction: transaction)
                break
            case .restored:
                restoreTransaction(transaction: transaction)
                break
            case .deferred:
                break
            case .purchasing:
                break
            }
        }
    }
    
    private func completeTransaction(transaction: SKPaymentTransaction) {

        self.delegate?.purchaseCompleted(identifier: transaction.payment.productIdentifier);
        NotificationCenter.default.post(name: .inAppPurchaseCompleted, object: transaction.payment.productIdentifier)
        
        if let handler = purchasehandlers[transaction.payment.productIdentifier] {
            handler(true)
        }
        
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func restoreTransaction(transaction: SKPaymentTransaction) {
        
        guard let productIdentifier = transaction.original?.payment.productIdentifier else {
            return
        }
        
        self.delegate?.purchaseRestored(identifier: transaction.payment.productIdentifier);
        NotificationCenter.default.post(name: .inAppPurchaseRestored, object: productIdentifier)
        
        restoreHandler?(productIdentifier)
        
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func failedTransaction(transaction: SKPaymentTransaction) {
    
        if let error = transaction.error {
            print("Transaction Error: \(error.localizedDescription)")
        }
        
        self.delegate?.purchaseFailed(errorDescription: transaction.error?.localizedDescription ?? "Failed")
        NotificationCenter.default.post(name: .inAppPurchaseFailed, object: transaction.error)
        
        if let handler = purchasehandlers[transaction.payment.productIdentifier] {
            handler(false)
        }
        
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
}

// MARK: - Logging

extension SBInAppPurchasing{

    func print(_ string: String){
        
        if self.debugLoggingEnabled {
            Swift.print("SBInAppPurchasing - \(string)")
        }
    }
}
