//
//  OrderManagementView.swift
//  Bufflo-OrderSystem
//
//  Created by Muhammad Azmi on 09/05/25.
//

import SwiftUI

struct OrderManagementView: View {
    enum OrderTab: String, CaseIterable {
        case active = "Active Order"
        case completed = "Completed"
    }
        
    @State private var selectedTab: OrderTab = .active    
    @State private var activeOrders: [Order] = [
        Order(
            orderNumber: "01",
            items: [
                OrderItem(name: "Nasi Putih", quantity: 3, price: 5000),
                OrderItem(name: "Ayam Goreng", quantity: 1, price: 15000),
                OrderItem(name: "Tahu Goreng", quantity: 2, price: 5000),
                OrderItem(name: "Sayur Lodeh", quantity: 1, price: 10000)
            ],
            status: .processing
        ),
        Order(
            orderNumber: "02",
            items: [
                OrderItem(name: "Nasi Putih", quantity: 3, price: 5000),
                OrderItem(name: "Ayam Goreng", quantity: 1, price: 15000),
                OrderItem(name: "Tahu Goreng", quantity: 2, price: 5000),
                OrderItem(name: "Sayur Lodeh", quantity: 1, price: 10000)
            ],
            status: .processing
        ),
        Order(
            orderNumber: "03",
            items: [
                OrderItem(name: "Nasi Putih", quantity: 3, price: 5000),
                OrderItem(name: "Ayam Goreng", quantity: 1, price: 15000),
                OrderItem(name: "Tahu Goreng", quantity: 2, price: 5000),
                OrderItem(name: "Sayur Lodeh", quantity: 1, price: 10000)
            ],
            status: .processing
        ),
        Order(
            orderNumber: "03",
            items: [
                OrderItem(name: "Nasi Putih", quantity: 3, price: 5000),
                OrderItem(name: "Ayam Goreng", quantity: 1, price: 15000),
                OrderItem(name: "Tahu Goreng", quantity: 2, price: 5000),
                OrderItem(name: "Sayur Lodeh", quantity: 1, price: 10000)
            ],
            status: .processing
        )
        ,
        Order(
            orderNumber: "03",
            items: [
                OrderItem(name: "Nasi Putih", quantity: 3, price: 5000),
                OrderItem(name: "Ayam Goreng", quantity: 1, price: 15000),
                OrderItem(name: "Tahu Goreng", quantity: 2, price: 5000),
                OrderItem(name: "Sayur Lodeh", quantity: 1, price: 10000)
            ],
            status: .processing
        )
        ,
        Order(
            orderNumber: "03",
            items: [
                OrderItem(name: "Nasi Putih", quantity: 3, price: 5000),
                OrderItem(name: "Ayam Goreng", quantity: 1, price: 15000),
                OrderItem(name: "Tahu Goreng", quantity: 2, price: 5000),
                OrderItem(name: "Sayur Lodeh", quantity: 1, price: 10000)
            ],
            status: .processing
        )
        ,
        Order(
            orderNumber: "03",
            items: [
                OrderItem(name: "Nasi Putih", quantity: 3, price: 5000),
                OrderItem(name: "Ayam Goreng", quantity: 1, price: 15000),
                OrderItem(name: "Tahu Goreng", quantity: 2, price: 5000),
                OrderItem(name: "Sayur Lodeh", quantity: 1, price: 10000),
                OrderItem(name: "Nasi Putih", quantity: 3, price: 5000),
                OrderItem(name: "Ayam Goreng", quantity: 1, price: 15000),
                OrderItem(name: "Tahu Goreng", quantity: 2, price: 5000),
                OrderItem(name: "Sayur Lodeh", quantity: 1, price: 10000)
            ],
            status: .processing
        )
        ,
        Order(
            orderNumber: "03",
            items: [
                OrderItem(name: "Nasi Putih", quantity: 3, price: 5000),
                OrderItem(name: "Ayam Goreng", quantity: 1, price: 15000),
                OrderItem(name: "Tahu Goreng", quantity: 2, price: 5000),
                OrderItem(name: "Sayur Lodeh", quantity: 1, price: 10000)
            ],
            status: .processing
        )
        ,
        Order(
            orderNumber: "03",
            items: [
                OrderItem(name: "Nasi Putih", quantity: 3, price: 5000),
                OrderItem(name: "Ayam Goreng", quantity: 1, price: 15000),
                OrderItem(name: "Tahu Goreng", quantity: 2, price: 5000),
                OrderItem(name: "Sayur Lodeh", quantity: 1, price: 10000)
            ],
            status: .processing
        )
    ]
        
    @State private var completedOrders: [Order] = []
    
    var body: some View {
        VStack(spacing: 10) {
            Picker("Order Type", selection: $selectedTab) {
                ForEach(OrderTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(40)
            .frame(maxWidth: .infinity, maxHeight: 40)
                        
            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 20),
                        GridItem(.flexible(), spacing: 20),
                        GridItem(.flexible(), spacing: 20)
                    ],
                    spacing: 20
                ) {
                    ForEach(selectedTab == .active ? activeOrders : completedOrders) { order in
                        OrderCardView(
                            order: order,
                            onDone: {
                                if let index = activeOrders.firstIndex(where: { $0.id == order.id }) {
                                    let completedOrder = activeOrders.remove(at: index)
                                    completedOrders.append(completedOrder)
                                }
                            },
                            onCancel: {
                                activeOrders.removeAll { $0.id == order.id }
                            }
                        )
                    }
                }
                .padding(40)
            }
        }
        .background(Color(.systemGray6))
    }
}

#Preview {
    OrderManagementView()
}
