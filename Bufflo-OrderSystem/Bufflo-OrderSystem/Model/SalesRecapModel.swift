//
//  SalesRecapModel.swift
//  Bufflo-OrderSystem
//
//  Created by Muhammad Azmi on 17/05/25.
//

import SwiftUI
import FirebaseFirestore

struct RecapDisplayItem: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var count: Int
}


struct DailySalesGroup: Identifiable {
    let id: String
    var date: Date
    var totalIncome: Double
    var salesCount: Int
    var aggregatedItems: [RecapDisplayItem]
}

struct WeeklySalesGroup: Identifiable {
    let id: String
    var startDate: Date
    var endDate: Date
    var totalIncome: Double
    var salesCount: Int
    var aggregatedItems: [RecapDisplayItem]
}
