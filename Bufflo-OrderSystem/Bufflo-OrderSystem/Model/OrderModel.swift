//
//  OrderModel.swift
//  Bufflo-OrderSystem
//
//  Created by Muhammad Azmi on 14/05/25.
//

import Foundation
import SwiftData


struct OrderItem: Identifiable {
    let id = UUID()
    let name: String
    var quantity: Int
    let price: Double
}

struct Order: Identifiable {
    let id = UUID()
    let orderNumber: String
    let items: [OrderItem]
    let status: OrderStatus
    
    enum OrderStatus {
        case pending
        case processing
        case completed
        case cancelled
    }
        
    var totalPrice: Double {
        items.reduce(0) { $0 + ($1.price * Double($1.quantity)) }
    }
}
