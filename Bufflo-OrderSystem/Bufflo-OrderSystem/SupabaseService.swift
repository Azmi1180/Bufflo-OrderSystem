//
//  SupabaseService.swift
//  Bufflo-OrderSystem
//
//  Created by Muhammad Azmi on 16/05/25.
//

import Foundation
import Supabase
import Realtime

class SupabaseService {
    static let shared = SupabaseService()
    let client: SupabaseClient

    private init() {
        guard let plistPath = Bundle.main.path(forResource: "SupabaseConfig", ofType: "plist"),
              let plistDict = NSDictionary(contentsOfFile: plistPath) else {
            fatalError("SupabaseConfig.plist not found or is invalid.")
        }

        guard let urlString = plistDict["SUPABASE_URL"] as? String,
              let anonKey = plistDict["SUPABASE_ANON_KEY"] as? String else {
            fatalError("SUPABASE_URL or SUPABASE_ANON_KEY not found in SupabaseConfig.plist.")
        }

        guard !urlString.contains("YOUR_SUPABASE_URL"), !anonKey.contains("YOUR_SUPABASE_ANON_KEY") else {
             fatalError("Please replace placeholder values in SupabaseConfig.plist with your actual Supabase URL and Anon Key.")
        }

        let supabaseURL = URL(string: urlString)!
        let supabaseKey = anonKey

        self.client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseKey)
        print("Supabase client initialized.")
    }

    func placeOrder(orderNumber: String, items: [OrderItem], status: Order.OrderStatus) async throws -> Order {
        let calculatedTotalPrice = items.reduce(0) { $0 + ($1.price * Double($1.quantity)) }
        let newOrderUUID = UUID()

        let orderRecord = OrderInsert(
            id: newOrderUUID,
            orderNumber: orderNumber,
            status: status,
            totalPrice: calculatedTotalPrice
        )

        let savedOrderBase: OrderInsert = try await client
            .from("orders")
            .insert(orderRecord, returning: .representation)
            .select("id, order_number, status, total_price, created_at")
            .single()
            .execute()
            .value

        let orderItemRecords = items.map { item in
            OrderItemInsert(
                orderId: newOrderUUID,
                name: item.name,
                quantity: item.quantity,
                price: item.price
            )
        }

        if !orderItemRecords.isEmpty {
            try await client
                .from("order_items")
                .insert(orderItemRecords)
                .execute()
        }

        return Order(
            id: savedOrderBase.id,
            orderNumber: savedOrderBase.orderNumber,
            items: items,
            status: savedOrderBase.status,
            createdAt: savedOrderBase.createdAt
        )
    }

    func fetchOrdersWithItems() async throws -> [Order] {
        let fetchedOrdersBase: [OrderBase] = try await client
            .from("orders")
            .select("id, order_number, status, total_price, created_at")
            .order("created_at", ascending: false)
            .execute()
            .value

        var ordersWithItems: [Order] = []
        for baseOrder in fetchedOrdersBase {
            let items: [OrderItem] = try await client
                .from("order_items")
                .select("id, name, quantity, price")
                .eq("order_id", value: baseOrder.id)
                .execute()
                .value

            ordersWithItems.append(Order(
                id: baseOrder.id,
                orderNumber: baseOrder.orderNumber,
                items: items,
                status: baseOrder.status,
                createdAt: baseOrder.createdAt
            ))
        }
        return ordersWithItems
    }

    func updateOrderStatus(orderId: UUID, newStatus: Order.OrderStatus) async throws {
        try await client
            .from("orders")
            .update(["status": newStatus.rawValue])
            .eq("id", value: orderId)
            .execute()
    }

    func subscribeToOrderChanges(
        onNewOrUpdatedOrder: @escaping @Sendable (Order) async -> Void,
        onDeletedOrder: @escaping @Sendable (UUID) -> Void
    ) async throws -> (RealtimeChannelV2, Task<Void, Never>) {

        let channel = client.realtimeV2.channel("public:orders")
        
        // Create a Task to listen for events asynchronously
        let listenerTask = Task {
            for await event in channel.events {
                // Check if the event is a Postgres Change event
                if case let .postgresChanges(message) = event {
                    guard let payload = message.payload,
                          let type = payload["type"] as? String,
                          let recordData = payload[type == "DELETE" ? "old_record" : "record"] as? [String: Any],
                          let data = try? JSONSerialization.data(withJSONObject: recordData),
                          let order = try? JSONDecoder().decode(OrderBase.self, from: data)
                    else {
                        print("Failed to decode realtime message")
                        continue
                    }

                    if type == "DELETE" {
                        onDeletedOrder(order.id)
                    } else {
                        do {
                            let items: [OrderItem] = try await self.client
                                .from("order_items")
                                .select("id, name, quantity, price")
                                .eq("order_id", value: order.id)
                                .execute()
                                .value

                            let fullOrder = Order(
                                id: order.id,
                                orderNumber: order.orderNumber,
                                items: items,
                                status: order.status,
                                createdAt: order.createdAt
                            )
                            await onNewOrUpdatedOrder(fullOrder)
                        } catch {
                            print("Error fetching order items: \(error)")
                        }
                    }
                }
            }
        }
        
        try await channel.subscribe()
        print("Subscribed to orders channel")
        
        return (channel, listenerTask)
    }


    func unsubscribeFromChannel(_ channel: RealtimeChannelV2?, listenerTasks: [Task<Void, Never>]) async {
        print("Unsubscribing and cancelling tasks...")
        listenerTasks.forEach { $0.cancel() }
        if let channel = channel {
            do {
                try await channel.unsubscribe()
                print("Successfully unsubscribed from channel.")
            } catch {
                print("Error unsubscribing: \(error)")
            }
        }
    }
}

struct OrderInsert: Codable {
    var id: UUID = UUID()
    let orderNumber: String
    let status: Order.OrderStatus
    let totalPrice: Double
    var createdAt: Date? = nil

    enum CodingKeys: String, CodingKey {
        case id
        case orderNumber = "order_number"
        case status
        case totalPrice = "total_price"
        case createdAt = "created_at"
    }
}

struct OrderBase: Codable, Identifiable {
    let id: UUID
    let orderNumber: String
    let status: Order.OrderStatus
    let totalPrice: Double
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case orderNumber = "order_number"
        case status
        case totalPrice = "total_price"
        case createdAt = "created_at"
    }
}

struct OrderItemInsert: Codable {
    var id: UUID = UUID()
    let orderId: UUID
    let name: String
    let quantity: Int
    let price: Double

    enum CodingKeys: String, CodingKey {
        case id
        case orderId = "order_id"
        case name
        case quantity
        case price
    }
}
