//
//  MenuViewModel.swift
//  Bufflo-OrderSystem
//
//  Created by Muhammad Azmi on 16/05/25.
//

import SwiftUI
import FirebaseFirestore

class MenuViewModel: ObservableObject {
    @Published var menuItems = [MenuItemFS]()
    private var db = Firestore.firestore()

    init() {
        fetchMenuItems()
    }

    func fetchMenuItems() {
        db.collection("menuItems").addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("Error fetching menu items: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            self.menuItems = documents.compactMap { document -> MenuItemFS? in
                try? document.data(as: MenuItemFS.self)
            }
        }
    }

    // Function to add sample menu items (call once for setup)
    func addSampleMenuItems() {
        let sampleItems: [MenuItemFS] = [
            MenuItemFS(name: "Nasi Putih", price: 4000, image: "white_rice_image"), // Ensure these images exist in your assets
            MenuItemFS(name: "Ayam Goreng", price: 12000, image: "ayam_goreng_image"),
            MenuItemFS(name: "Tahu Goreng", price: 2000, image: "tahu_goreng_image"),
            MenuItemFS(name: "Ayam Bakar", price: 12000, image: "ayam_bakar_image"),
            MenuItemFS(name: "Ayam Gulai", price: 12000, image: "ayam_gulai_image"),
            MenuItemFS(name: "Tempe Orek", price: 4000, image: "tempe_orek_image"),
            MenuItemFS(name: "Sayur Toge", price: 4000, image: "sayur_toge_image"),
            MenuItemFS(name: "Sayur Pare Teri", price: 4000, image: "tumis_pare_teri_image")
        ]

        for item in sampleItems {
            do {
                _ = try db.collection("menuItems").addDocument(from: item)
            } catch {
                print("Error adding sample menu item \(item.name): \(error.localizedDescription)")
            }
        }
        print("Sample menu items potentially added.")
    }
}
