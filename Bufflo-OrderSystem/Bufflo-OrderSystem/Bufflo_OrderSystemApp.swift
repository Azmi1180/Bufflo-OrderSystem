//
//  Bufflo_OrderSystemApp.swift
//  Bufflo-OrderSystem
//
//  Created by Muhammad Azmi on 09/05/25.
//


// Bufflo_OrderSystemApp.swift
import SwiftUI

@main
struct Bufflo_OrderSystemApp: App {
    // Register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate // Add this line

    @StateObject var menuViewModel = MenuViewModel()
    @StateObject var customerOrderViewModel = CustomerOrderViewModel()
    @StateObject var orderManagementViewModel = OrderManagementViewModel()

    var body: some Scene {
        WindowGroup {
            MainAppView()
                .environmentObject(menuViewModel)
                .environmentObject(customerOrderViewModel)
                .environmentObject(orderManagementViewModel)
        }
    }
}

// A simple TabView to navigate
struct MainAppView: View {
    var body: some View {
        TabView {
            CustomerOrderView()
                .tabItem {
                    Label("Order", systemImage: "cart")
                }

            OrderManagementView()
                .tabItem {
                    Label("Manage Orders", systemImage: "list.bullet.clipboard")
                }
        }
    }
}

