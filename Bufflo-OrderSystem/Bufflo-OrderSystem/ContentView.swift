//
//  ContentView.swift
//  Bufflo-OrderSystem
//
//  Created by Muhammad Azmi on 09/05/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
//    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]

    var body: some View {
        OrderManagementView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
