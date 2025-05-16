//
//  OrderManagementViewModel.swift
//  Bufflo-OrderSystem
//
//  Created by Muhammad Azmi on 16/05/25.
//

import SwiftUI

import Realtime // For Channel type

@MainActor
class OrderManagementViewModel: ObservableObject {
    @Published var activeOrders: [Order] = []
    @Published var completedOrders: [Order] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private var allOrders: [Order] = [] {
        didSet {
            filterOrders()
        }
    }
    private var channel: RealtimeChannelV2?
    private var listenerTasks: [Task<Void, Never>] = []

    init() {
        loadInitialOrders()
        Task {
            await subscribeToChanges()
        }
    }

    deinit {
        Task {
            await SupabaseService.shared.unsubscribeFromChannel(channel, listenerTasks: listenerTasks)
        }
    }

    func loadInitialOrders() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let fetchedOrders = try await SupabaseService.shared.fetchOrdersWithItems()
                self.allOrders = fetchedOrders
                self.isLoading = false
            } catch {
                print("Error fetching orders: \(error)")
                self.errorMessage = "Failed to load orders: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    private func filterOrders() {
        activeOrders = allOrders.filter { $0.status == .pending || $0.status == .processing }
                                .sorted(by: { $0.createdAt ?? Date.distantPast > $1.createdAt ?? Date.distantPast })
        completedOrders = allOrders.filter { $0.status == .completed || $0.status == .cancelled }
                                 .sorted(by: { $0.createdAt ?? Date.distantPast > $1.createdAt ?? Date.distantPast })
    }

    func updateOrderStatus(orderId: UUID, newStatus: Order.OrderStatus) {
        Task {
            do {
                try await SupabaseService.shared.updateOrderStatus(orderId: orderId, newStatus: newStatus)
                // Realtime update should handle this, but an optimistic update can be added here
                // if let index = allOrders.firstIndex(where: { $0.id == orderId }) {
                //     allOrders[index].status = newStatus
                // }
            } catch {
                print("Error updating order status: \(error)")
                self.errorMessage = "Failed to update order: \(error.localizedDescription)"
            }
        }
    }

    private func subscribeToChanges() async { // Make this async
        let subscriptionResult = SupabaseService.shared.subscribeToOrderChanges(
            onNewOrUpdatedOrder: { [weak self] (changedOrder: Order) in
                guard let self = self else { return }
                Task { @MainActor in
                    print("ViewModel received new/updated order: \(changedOrder.id)")
                    if let index = self.allOrders.firstIndex(where: { $0.id == changedOrder.id }) {
                        self.allOrders[index] = changedOrder
                    } else {
                        self.allOrders.append(changedOrder)
                    }
                }
            },
            onDeletedOrder: { [weak self] (deletedOrderId: UUID) in
                guard let self = self else { return }
                Task { @MainActor in
                    print("ViewModel received deleted order: \(deletedOrderId)")
                    self.allOrders.removeAll { $0.id == deletedOrderId }
                }
            }
        )
        self.channel = subscriptionResult.channel
        self.listenerTasks = subscriptionResult.listenerTasks

        do {
            if let channel = self.channel {
                try await channel.subscribe()
            }
            print("OrderManagementViewModel: Successfully subscribed to RealtimeV2 channel.")
        } catch {
            print("OrderManagementViewModel: Error subscribing to RealtimeV2 channel: \(error)")
            self.errorMessage = "Realtime connection failed: \(error.localizedDescription)"
            // Clean up if subscription fails
            await SupabaseService.shared.unsubscribeFromChannel(self.channel, listenerTasks: self.listenerTasks)
            self.channel = nil // Nullify to prevent further operations on a failed channel
            self.listenerTasks = []
        }
    }
}
