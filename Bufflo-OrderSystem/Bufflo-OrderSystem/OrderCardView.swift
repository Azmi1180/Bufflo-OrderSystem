//
//  OrderCardView.swift
//  Bufflo-OrderSystem
//
//  Created by Muhammad Azmi on 12/05/25.
//

// OrderCardView.swift
import SwiftUI
import FirebaseFirestore
// Updated OrderCardView to use OrderFS
struct OrderCardViewFS: View {
    let order: OrderFS // Use Firebase model
    let onDone: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Order No. \(order.orderNumber)")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
            
            Text("Status: \(order.status.rawValue)") // Display status
                .font(.caption)
                .padding(.bottom, 5)
                .foregroundColor(statusColor(order.status))


            VStack(alignment: .leading, spacing: 12) {
                ForEach(order.items) { item in // OrderItemFS is Identifiable
                    HStack {
                        Text(item.name)
                            .font(.system(size: 20)) // Consider making font size smaller if many items
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

                // Show buttons only if order is in a state that allows these actions
                if order.status == .pending || order.status == .processing {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .frame(minWidth: 44, minHeight:44)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .cornerRadius(8)
                    }
                    .padding(.trailing, 5) // Add some spacing

                    Button(action: onDone) {
                        Text("Done")
                            .frame(minWidth: 44, minHeight:44)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.green)
                            .cornerRadius(8)
                    }
                } else if order.status == .completed {
                    Text("Completed")
                        .font(.headline)
                        .foregroundColor(.green)
                } else if order.status == .cancelled {
                     Text("Cancelled")
                        .font(.headline)
                        .foregroundColor(.red)
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
        formatter.groupingSeparator = "." // Or "," depending on your locale preference
        formatter.decimalSeparator = ","   // Or "."
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0 // For whole numbers like Rupiah

        return formatter.string(from: NSNumber(value: order.totalPrice)) ?? "0"
    }
    
    private func statusColor(_ status: OrderFS.OrderStatusFS) -> Color {
        switch status {
        case .pending: return .orange
        case .processing: return .blue
        case .completed: return .green
        case .cancelled: return .red
        }
    }
}

// Preview for OrderCardViewFS
struct OrderCardViewFS_Previews: PreviewProvider {
    static var previews: some View {
        let sampleOrder = OrderFS(
            id: "sample123",
            orderNumber: "001",
            items: [
                OrderItemFS(name: "Nasi Putih", quantity: 1, price: 20000),
                OrderItemFS(name: "Es Teh", quantity: 2, price: 5000)
            ],
            status: .pending,
            totalPrice: 30000,
            userId: "testUser",
            orderDate: Timestamp(date: Date())
        )

        return OrderCardViewFS(
            order: sampleOrder,
            onDone: { print("Done tapped") },
            onCancel: { print("Cancel tapped") }
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
