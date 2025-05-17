//
//  OrderManagementViewModel.swift
//  Bufflo-OrderSystem
//
//  Created by Muhammad Azmi on 15/05/25.
//

import SwiftUI
import FirebaseFirestore

class OrderManagementViewModel: ObservableObject {
    @Published var activeOrders = [OrderFS]()
    @Published var completedOrders = [OrderFS]()
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?

    init() {
        fetchOrders()
    }

    deinit {
        listener?.remove() // Stop listening when ViewModel is deallocated
    }

    func fetchOrders() {
        listener?.remove() // Remove existing listener before attaching a new one

        listener = db.collection("orders")
                      .order(by: "orderDate", descending: true) // Show newest first
                      .addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("Error fetching orders: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            let allOrders = documents.compactMap { document -> OrderFS? in
                try? document.data(as: OrderFS.self)
            }

            // Filter orders based on status
            self.activeOrders = allOrders.filter { $0.status == .pending || $0.status == .processing }
            self.completedOrders = allOrders.filter { $0.status == .completed }
            // You might want to include .cancelled in a separate list or within completed with different UI
        }
    }

    func completeOrder(order: OrderFS) {
        guard let orderId = order.id else {
            print("Order ID is missing, cannot complete.")
            return
        }
        var updatedOrder = order
        updatedOrder.status = .completed
        
        do {
            try db.collection("orders").document(orderId).setData(from: updatedOrder, merge: true) { error in
                 if let error = error {
                    print("Error updating order to completed: \(error.localizedDescription)")
                } else {
                    print("Order \(orderId) marked as completed.")
                    // The listener will automatically refresh the lists
                }
            }
        } catch {
             print("Error encoding order for completion: \(error.localizedDescription)")
        }
    }

    func cancelOrder(order: OrderFS) {
        guard let orderId = order.id else {
            print("Order ID is missing, cannot cancel.")
            return
        }
        
        var updatedOrder = order
        updatedOrder.status = .cancelled
        
        do {
            try db.collection("orders").document(orderId).setData(from: updatedOrder, merge: true) { error in
                if let error = error {
                    print("Error updating order to cancelled: \(error.localizedDescription)")
                } else {
                    print("Order \(orderId) marked as cancelled.")
                    // The listener will automatically refresh the lists
                    // If you want to remove cancelled orders from active list immediately:
                    // self.activeOrders.removeAll { $0.id == orderId }
                }
            }
        } catch {
            print("Error encoding order for cancellation: \(error.localizedDescription)")
        }
    }
}

