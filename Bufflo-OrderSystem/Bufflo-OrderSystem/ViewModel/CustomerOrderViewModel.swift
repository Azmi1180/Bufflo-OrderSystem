//
//  CustomerOrderViewModel.swift
//  Bufflo-OrderSystem
//
//  Created by Muhammad Azmi on 16/05/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class CustomerOrderViewModel: ObservableObject {
    @Published var currentOrderItems = [OrderItemFS]()
//    @Published var orderNumber: String = "001" // You might want a more robust way to generate this
    @Published var currentDisplayOrderNumber: String = "Loading..." // For UI display
    
    

    private var db = Firestore.firestore()
    private let orderCounterRef: DocumentReference
    
    init() {
            // Define the reference to the counter document
            orderCounterRef = db.collection("counters").document("orderCounter")
            fetchInitialOrderNumber()
    }
    
    private func fetchInitialOrderNumber() {
        orderCounterRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let lastNumber = document.data()?["lastOrderNumber"] as? Int ?? 0
                DispatchQueue.main.async {
                    self.currentDisplayOrderNumber = String(format: "%03d", lastNumber + 1)
                }
            } else {
                print("Order counter document does not exist. Creating with initial value.")
                self.orderCounterRef.setData(["lastOrderNumber": 0]) { err in
                    if let err = err {
                        print("Error creating counter document: \(err)")
                        DispatchQueue.main.async {
                            self.currentDisplayOrderNumber = "Error"
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.currentDisplayOrderNumber = "001"
                        }
                    }
                }
            }
        }
    }
        
    private func getNextOrderNumber(completion: @escaping (String?) -> Void) {
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let counterDocument: DocumentSnapshot
            do {
                try counterDocument = transaction.getDocument(self.orderCounterRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }

            guard let oldCounterValue = counterDocument.data()?["lastOrderNumber"] as? Int else {
                // If counter field doesn't exist, or document doesn't exist (though we try to create it in init)
                // We might initialize it here, or assume it should exist.
                // For robustness, let's try to set it if it's missing.
                print("lastOrderNumber field missing or document not found in transaction. Initializing.")
                transaction.setData(["lastOrderNumber": 1], forDocument: self.orderCounterRef)
                return 1
            }

            let newCounterValue = oldCounterValue + 1
            transaction.updateData(["lastOrderNumber": newCounterValue], forDocument: self.orderCounterRef)
            return newCounterValue

        }) { (object, error) in
            if let error = error {
                print("Order number transaction failed: \(error)")
                completion(nil)
            } else if let newOrderNumberInt = object as? Int {
                let formattedOrderNumber = String(format: "%03d", newOrderNumberInt)
                completion(formattedOrderNumber)
            } else {
                print("Transaction completed but didn't return the expected number.")
                completion(nil)
            }
        }
    }
    
    var totalCartPrice: Double {
        currentOrderItems.reduce(0) { $0 + ($1.price * Double($1.quantity)) }
    }

    func addItemToOrder(menuItem: MenuItemFS) {
        if let index = currentOrderItems.firstIndex(where: { $0.name == menuItem.name }) {
            currentOrderItems[index].quantity += 1
        } else {
            let newOrderItem = OrderItemFS(name: menuItem.name, quantity: 1, price: menuItem.price)
            currentOrderItems.append(newOrderItem)
        }
    }

    func decrementOrRemoveOrderItem(item: OrderItemFS) {
        if let index = currentOrderItems.firstIndex(where: { $0.id == item.id }) {
            if currentOrderItems[index].quantity > 1 {
                currentOrderItems[index].quantity -= 1
            } else {
                currentOrderItems.remove(at: index)
            }
        }
    }

    func placeOrder(completion: @escaping (Bool, String?, Error?) -> Void) { 
        guard !currentOrderItems.isEmpty else {
            print("Cart is empty. Cannot place order.")
            completion(false, nil, nil)
            return
        }
        
        getNextOrderNumber { [weak self] newOrderNumberString in
            guard let self = self, let actualOrderNumber = newOrderNumberString else {
                print("Failed to get next order number.")
                completion(false, nil, NSError(domain: "OrderError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to generate order number."]))
                return
            }

            let userId = Auth.auth().currentUser?.uid
            let newOrder = OrderFS(
                orderNumber: actualOrderNumber,
                items: self.currentOrderItems,
                status: .pending,
                totalPrice: self.totalCartPrice,
                userId: userId ?? "anonymous",
                orderDate: Timestamp(date: Date())
            )

            do {
                _ = try self.db.collection("orders").addDocument(from: newOrder) { error in
                    if let error = error {
                        print("Error placing order: \(error.localizedDescription)")
                        completion(false, actualOrderNumber, error)
                    } else {
                        print("Order placed successfully: \(newOrder.orderNumber), Total: \(newOrder.totalPrice)")
                        DispatchQueue.main.async {
                            self.currentOrderItems = []
                            self.fetchInitialOrderNumber()
                        }
                        completion(true, actualOrderNumber, nil)
                    }
                }
            } catch {
                print("Error encoding or saving order: \(error.localizedDescription)")
                completion(false, actualOrderNumber, error)
            }
        }
    }
}
