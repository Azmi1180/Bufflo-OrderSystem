//
//  OrderCardView.swift
//  Bufflo-OrderSystem
//
//  Created by Muhammad Azmi on 12/05/25.
//

import SwiftUI

// Order Item struct to represent individual items in an order
//struct OrderItem: Identifiable {
//    let id = UUID()
//    let name: String
//    let quantity: Int
//    let price: Double
//}
//
//struct Order: Identifiable {
//    let id = UUID()
//    let orderNumber: String
//    let items: [OrderItem]
//    let status: OrderStatus
//    
//    enum OrderStatus {
//        case pending
//        case processing
//        case completed
//        case cancelled
//    }
//        
//    var totalPrice: Double {
//        items.reduce(0) { $0 + ($1.price * Double($1.quantity)) }
//    }
//}

struct OrderCardView: View {
    let order: Order
    let onDone: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Order No. \(order.orderNumber)")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
                        
            VStack(alignment: .leading, spacing: 12) {
                ForEach(order.items) { item in
                    HStack {
                        Text(item.name)
                            .font(.system(size: 20))
                        Spacer()
                        Text("x\(item.quantity)")
                            .font(.system(size: 20))
                    }
                }
            }
            .padding(.vertical, 10)
                        
            
                        
            HStack {
                VStack(alignment: .leading) {
                    Text("Total :")
                        .font(.headline)
                        .foregroundColor(.black)
                    Text("Rp. \(formattedTotalPrice)")
                        .font(.title2.bold())
                        .foregroundColor(.black)
                }
                Spacer()
                Spacer()
                Button(action: onCancel) {
                    Text("Cancel")
                        .frame(minWidth: 44, minHeight:44)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
//                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Spacer()
                
                Button(action: onDone) {
                    Text("Done")
                        .frame(minWidth: 44, minHeight:44)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .cornerRadius(8)
                }
            }
            .padding(.top, 10)
        }
        .frame(maxWidth: 450)
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
        
    private var formattedTotalPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        formatter.decimalSeparator = ","
        
        return formatter.string(from: NSNumber(value: order.totalPrice)) ?? "0"
    }
}

#Preview {
    let sampleOrder = Order(
        orderNumber: "001",
        items: [
            OrderItem(name: "Nasi Putih", quantity: 1, price: 20000),
            OrderItem(name: "Es Teh", quantity: 2, price: 5000)
        ],
        status: .pending
    )
    
    return OrderCardView(
        order: sampleOrder,
        onDone: { },
        onCancel: { }
    )
}
