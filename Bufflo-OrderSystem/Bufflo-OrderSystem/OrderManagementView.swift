//
//  OrderManagementView.swift
//  Bufflo-OrderSystem
//
//  Created by Muhammad Azmi on 09/05/25.
//

// OrderManagementView.swift
import SwiftUI
import FirebaseFirestore

struct OrderManagementView: View {
    enum OrderTab: String, CaseIterable {
        case active = "Active Order"
        case completed = "Completed"
    }

    @State private var selectedTab: OrderTab = .active
    @EnvironmentObject var viewModel: OrderManagementViewModel

    var body: some View {
        VStack(spacing: 10) {
            Picker("Order Type", selection: $selectedTab) {
                ForEach(OrderTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 40)
            .padding(.top, 20)
            .frame(height: 40)

            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 20),
                        GridItem(.flexible(), spacing: 20),
                        GridItem(.flexible(), spacing: 20)
                    ],
                    spacing: 20
                ) {
                    let ordersToShow: [OrderFS] = {
                        switch selectedTab {
                        case .active:
                            return viewModel.activeOrders
                        case .completed:
                            return viewModel.completedOrders
                        }
                    }()

                    ForEach(ordersToShow) { order in
                        OrderCardViewFS(
                            order: order,
                            onDone: {
                                viewModel.completeOrder(order: order)
                            },
                            onCancel: {
                                viewModel.cancelOrder(order: order)
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

// Preview for OrderManagementView
struct OrderManagementView_Previews: PreviewProvider {
    static var previews: some View {        
        let mockViewModel = OrderManagementViewModel()

        // If you want to populate the mockViewModel with sample data for the preview:
        let sampleActiveOrder = OrderFS( // <-- Use OrderFS
            id: "active123",
            orderNumber: "A001",
            items: [OrderItemFS(name: "Nasi Padang", quantity: 1, price: 25000)],
            status: .processing,
            totalPrice: 25000,
            userId: "previewUser",
            orderDate: Timestamp(date: Date()) // Make sure FirebaseFirestore is imported
        )
        let sampleCompletedOrder = OrderFS( // <-- Use OrderFS
            id: "completed456",
            orderNumber: "C002",
            items: [OrderItemFS(name: "Soto Ayam", quantity: 2, price: 15000)],
            status: .completed,
            totalPrice: 30000,
            userId: "previewUser",
            orderDate: Timestamp(date: Date().addingTimeInterval(-3600)) // Older date
        )
        mockViewModel.activeOrders = [sampleActiveOrder]
        mockViewModel.completedOrders = [sampleCompletedOrder]


        return OrderManagementView()
            .environmentObject(mockViewModel) // Provide the mock ViewModel
    }
}
