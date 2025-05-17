//
//  OrderModel.swift
//  Bufflo-OrderSystem
//
//  Created by Muhammad Azmi on 14/05/25.
//

import Foundation
import FirebaseFirestore

// Represents an item on the menu
struct MenuItemFS: Identifiable, Codable {
    @DocumentID var id: String? // This now comes from FirebaseFirestore
    var name: String
    var price: Double
    var image: String
}

// Represents an item within an order
struct OrderItemFS: Identifiable, Codable {
    var id = UUID().uuidString
    var name: String
    var quantity: Int
    var price: Double
}

// Represents a customer's order
struct OrderFS: Identifiable, Codable {
    @DocumentID var id: String? // This now comes from FirebaseFirestore
    var orderNumber: String
    var items: [OrderItemFS]
    var status: OrderStatusFS
    var totalPrice: Double
    var userId: String?
    var orderDate: Timestamp // This comes from FirebaseFirestore

    enum OrderStatusFS: String, Codable, CaseIterable {
        case pending = "Pending"
        case processing = "Processing"
        case completed = "Completed"
        case cancelled = "Cancelled"
    }
}
