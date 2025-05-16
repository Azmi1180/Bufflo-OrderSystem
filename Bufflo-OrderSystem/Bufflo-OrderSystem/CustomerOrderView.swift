//
//  CustomerOrder.swift
//  Bufflo-OrderSystem
//
//  Created by Muhammad Azmi on 14/05/25.
//

import SwiftUI

struct CustomerOrderView: View {    
    private let menuItems: [MenuItem] = [
        MenuItem(name: "Nasi Putih", price: 4000, image: "white_rice_image"),
        MenuItem(name: "Ayam Goreng", price: 12000, image: "ayam_goreng_image"),
        MenuItem(name: "Tahu Goreng", price: 2000, image: "tahu_goreng_image"),
        MenuItem(name: "Ayam Bakar", price: 12000, image: "ayam_bakar_image"),
        MenuItem(name: "Ayam Gulai", price: 12000, image: "ayam_gulai_image"),
        MenuItem(name: "Tempe Orek", price: 4000, image: "tempe_orek_image"),
        MenuItem(name: "Sayur Toge", price: 4000, image: "sayur_toge_image"),
        MenuItem(name: "Sayur Pare Teri", price: 4000, image: "tumis_pare_teri_image")
    ]
        
    @State private var orderItems: [OrderItem] = []
    @State private var orderNumber: String = "001"
    
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
                                        
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(menuItems) { item in
                                MenuItemView(item: item, addToOrder: addItemToOrder)
                            }
                        }
                        .padding()
                    }
                }
                .frame(width: 700)
                
                VStack {
                    HStack {
                        Spacer()
                        OrderListView(
                            orderItems: $orderItems,
                            orderNumber: orderNumber,
                            removeItem: removeItemFromOrder,
                            placeOrder: placeOrder
                        )
                        .frame(width: .infinity)
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 3)
                    }
                    .padding()
                    Spacer()
                }
            }
            
        }
    }
        
    private func addItemToOrder(item: MenuItem) {
        if let index = orderItems.firstIndex(where: { $0.name == item.name }) {
            let currentItem = orderItems[index]
            let updatedItem = OrderItem(
                name: currentItem.name,
                quantity: currentItem.quantity + 1,
                price: currentItem.price
            )
            orderItems[index] = updatedItem
        } else {
            orderItems.append(OrderItem(
                name: item.name,
                quantity: 1,
                price: item.price
            ))
        }
    }
        
    private func removeItemFromOrder(at indexSet: IndexSet) {
        for index in indexSet {
            if orderItems[index].quantity > 1 {
                orderItems[index].quantity -=  1
            } else {
                orderItems.remove(at: index)
            }
        }
    }

        
    private func placeOrder() {
        let order = Order(
            orderNumber: "No. \(orderNumber)",
            items: orderItems,
            status: .pending
        )
    
        print("Order placed: \(order.orderNumber), Total: Rp. \(Int(order.totalPrice))")
        
        orderItems = []
                
        let orderNum = Int(orderNumber) ?? 0
        orderNumber = String(format: "%03d", orderNum + 1)
    }
}

struct MenuItemView: View {
    let item: MenuItem
    let addToOrder: (MenuItem) -> Void
    
    var body: some View {
        VStack {
            VStack{
                Image(item.image)
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


// Order list panel
struct OrderListView: View {
    @Binding var orderItems: [OrderItem]
    let orderNumber: String
    let removeItem: (IndexSet) -> Void
    let placeOrder: () -> Void
    
    private var total: Double {
        orderItems.reduce(0) { $0 + ($1.price * Double($1.quantity)) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Order List No. \(orderNumber)")
                .font(.headline)
                .padding(.vertical, 8)
            
            if orderItems.isEmpty {
                Text("No items added")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical)
            } else {
                List {
                    ForEach(Array(orderItems.enumerated()), id: \.element.id) { index, item in
                        HStack {
                            Text("\(item.quantity)x")
                                .foregroundColor(.secondary)
                                .frame(width: 30, alignment: .leading)

                            Text(item.name)

                            Spacer()

                            Text("Rp. \(Int(item.price * Double(item.quantity)))")
                                .foregroundColor(.primary)

                            Button(action: {
                                removeItem(IndexSet(integer: index))
                            }) {
                                Image(systemName: "x.circle")
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
                
                Button(action: placeOrder) {
                    Text("Order")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .disabled(orderItems.isEmpty)
            }
        }
        .padding()
    }
}

struct CustomerOrderView_Previews: PreviewProvider {
    static var previews: some View {
        CustomerOrderView()
    }
}
