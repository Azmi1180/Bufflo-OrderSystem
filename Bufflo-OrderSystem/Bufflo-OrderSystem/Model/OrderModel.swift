//
//  OrderModel.swift
//  Bufflo-OrderSystem
//
//  Created by Muhammad Azmi on 14/05/25.
//

// OrderModel.swift
import Foundation

struct OrderItem: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    var quantity: Int
    let price: Double
    

    init(id: UUID = UUID(), name: String, quantity: Int, price: Double) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.price = price
    }
}

struct Order: Identifiable, Codable, Hashable {
    let id: UUID
    let orderNumber: String
    var items: [OrderItem]
    var status: OrderStatus
    var totalPrice: Double

    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case orderNumber = "order_number" // Map to snake_case in DB
        case items // We'll handle this. If items are in a separate table, this won't be directly decoded.
        case status
        case totalPrice = "total_price"
        case createdAt = "created_at"
    }

    // Make OrderStatus Codable
    enum OrderStatus: String, Codable, CaseIterable, Hashable { // Added String raw value, Codable, CaseIterable, Hashable
        case pending
        case processing
        case completed
        case cancelled
    }

    // Client-side convenience initializer
    init(id: UUID = UUID(), orderNumber: String, items: [OrderItem], status: OrderStatus, createdAt: Date? = nil) {
        self.id = id
        self.orderNumber = orderNumber
        self.items = items
        self.status = status
        self.totalPrice = items.reduce(0) { $0 + ($1.price * Double($1.quantity)) }
        self.createdAt = createdAt
    }

    // If you are fetching OrderItems separately, you might have an init like this:
    // init(id: UUID, orderNumber: String, status: OrderStatus, totalPrice: Double, createdAt: Date? = nil, items: [OrderItem] = []) { ... }
}

// MenuItem remains largely the same as it's for UI presentation of the menu
struct MenuItem: Identifiable {
    let id = UUID()
    let name: String
    let price: Double
    let image: String
}
