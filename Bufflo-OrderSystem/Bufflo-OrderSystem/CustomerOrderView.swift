//
//  CustomerOrder.swift
//  Bufflo-OrderSystem
//
//  Created by Muhammad Azmi on 14/05/25.
//

import SwiftUI

struct CustomerOrderView: View {
    @EnvironmentObject var menuViewModel: MenuViewModel
    @EnvironmentObject var customerOrderViewModel: CustomerOrderViewModel

    var body: some View {
        ZStack {
            Color(UIColor.systemGray6).ignoresSafeArea()
            HStack {
                VStack(spacing: 0) {
                    Text("Menu")
                        .font(.title)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top)

                    // Button to add sample data (for testing, remove in production)
//                     Button("Add Sample Menu Items to Firebase") {
//                         menuViewModel.addSampleMenuItems()
//                     }
//                     .padding()


                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(menuViewModel.menuItems) { item in // Use menuItems from ViewModel
                                MenuItemViewFS(item: item, addToOrder: { menuItem in
                                    customerOrderViewModel.addItemToOrder(menuItem: menuItem)
                                })
                            }
                        }
                        .padding()
                    }
                }
                .frame(width: 700)

                VStack {
                    HStack {
                        Spacer()
                        OrderListViewFS(
                            orderItems: $customerOrderViewModel.currentOrderItems,
                            displayOrderNumber: customerOrderViewModel.currentDisplayOrderNumber,
                            removeItem: { item in
                                customerOrderViewModel.decrementOrRemoveOrderItem(item: item)
                            },
                            placeOrder: customerOrderViewModel.placeOrder
                        )
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 3)
                    }
                    .padding()
                    Spacer()
                }
            }
        }
        // .onAppear { // Data is fetched by ViewModel's init
        //     menuViewModel.fetchMenuItems()
        // }
    }
}

// Updated MenuItemView to use MenuItemFS
struct MenuItemViewFS: View {
    let item: MenuItemFS // Use Firebase model
    let addToOrder: (MenuItemFS) -> Void

    var body: some View {
        VStack {
            VStack{
                Image(item.image) // Ensure these images are in your Assets.xcassets
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 144, height: 144)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 0))
                    .padding(0)
                VStack{
                    Text(item.name)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("Rp. \(Int(item.price))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(8)
            }
            .onTapGesture {
                addToOrder(item)
            }
        }
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}


// Updated OrderListView to use OrderItemFS and ViewModel interaction
struct OrderListViewFS: View {
    @Binding var orderItems: [OrderItemFS]
    // orderNumber now comes from CustomerOrderViewModel's currentDisplayOrderNumber
    let displayOrderNumber: String // Renamed from orderNumber
    let removeItem: (OrderItemFS) -> Void
    // Update placeOrder signature to match the new ViewModel
    let placeOrder: (@escaping (Bool, String?, Error?) -> Void) -> Void

    @State private var showingPlaceOrderConfirmAlert = false
    @State private var showingOrderSuccessAlert = false
    @State private var orderSuccessMessage: String = ""
    @State private var showingOrderErrorAlert = false
    @State private var orderErrorAlertMessage: String = ""


    private var total: Double {
        orderItems.reduce(0) { $0 + ($1.price * Double($1.quantity)) }
    }

    var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text("Order List (Next No. \(displayOrderNumber))") // Use displayOrderNumber
                    .font(.headline)
                    .padding(.vertical, 8)

            if orderItems.isEmpty {
                Text("No items added")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical)
            } else {
                List {
                    ForEach(orderItems) { item in
                        HStack {
                            Text("\(item.quantity)x") // ...
                            Text(item.name) // ...
                            Spacer() // ...
                            Text("Rp. \(Int(item.price * Double(item.quantity)))") // ...
                            Button(action: { removeItem(item) }) { // ...
                                Image(systemName: "x.circle") // ...
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                }
                .frame(height: min(CGFloat(orderItems.count) * 44 + 20, 300))
                .listStyle(PlainListStyle())

                Divider()

                HStack {
                    Text("Total :")
                        .font(.headline)
                    Spacer()
                    Text("Rp. \(Int(total))")
                        .font(.headline)
                }
                .padding(.vertical, 4)

                Button(action: {
                    // Trigger the confirmation alert
                    self.showingPlaceOrderConfirmAlert = true
                }) {
                    Text("Order")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .disabled(orderItems.isEmpty)
                .alert("Confirm Order", isPresented: $showingPlaceOrderConfirmAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Confirm") {
                        placeOrder { success, placedOrderNumber, error in // Capture placedOrderNumber
                            if success, let orderNum = placedOrderNumber {
                                self.orderSuccessMessage = "Your order (No. \(orderNum)) has been successfully placed."
                                self.showingOrderSuccessAlert = true
                            } else {
                                self.orderErrorAlertMessage = error?.localizedDescription ?? "An unknown error occurred while placing the order."
                                self.showingOrderErrorAlert = true
                            }
                        }
                    }
                } message: {
                    Text("Are you sure you want to place this order for Rp. \(Int(total))?")
                }
                .alert("Order Placed!", isPresented: $showingOrderSuccessAlert) { // Success Alert
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(orderSuccessMessage) // Use dynamic success message
                }
                // Error Alert
                .alert("Order Failed", isPresented: $showingOrderErrorAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(orderErrorAlertMessage)
                }

            }
        }
        .padding()
    }
}

struct CustomerOrderView_Previews: PreviewProvider {
    static var previews: some View {
        // For preview, you might need to mock the environment objects
        CustomerOrderView()
            .environmentObject(MenuViewModel())
            .environmentObject(CustomerOrderViewModel())
    }
}
