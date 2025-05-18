//
//  SalesRecapViewModel.swift
//  Bufflo-OrderSystem
//
//  Created by Muhammad Azmi on 17/05/25.
//

import SwiftUI
import FirebaseFirestore
import Combine

class SalesRecapViewModel: ObservableObject {
    @Published var completedOrders: [OrderFS] = []
    private var db = Firestore.firestore()
    private var ordersListener: ListenerRegistration?

    // MARK: - Published Properties for UI
    @Published var timeRange: SalesRecapTimeRange = .today
    @Published var timeOfDay: String = "Day"

    // Buat Summary
    @Published var incomeThisWeek: Double = 0
    @Published var incomeToday: Double = 0
    @Published var salesCountToday: Int = 0
    @Published var incomeDifferenceFromYesterdaySign: String = "arrow.left.and.right.circle" // Placeholder
    @Published var incomeDifferenceFromYesterdayAmount: Double = 0

    // Buat filter disalay
    @Published var todayIndividualOrders: [OrderFS] = []
    @Published var dailyAggregatedGroups: [DailySalesGroup] = []
    @Published var weeklyAggregatedGroups: [WeeklySalesGroup] = []

    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
        
    @Published var selectedOrderForDetail: OrderFS? = nil
    @Published var selectedDailyGroupForDetail: DailySalesGroup? = nil
    @Published var selectedWeeklyGroupForDetail: WeeklySalesGroup? = nil
    
    // Dah gk kepake harusnya cuman nanti cek ulang lagi
//    private let regularDishNames = ["Nasi Putih", "Ayam Goreng", "Tahu Goreng", "Ayam Bakar", "Ayam Gulai", "Tempe Orek", "Sayur Toge", "Sayur Pare Teri"]
//    private let dishColors: [String: Color] = [
//        "Nasi Putih": .gray, "Ayam Goreng": .red, "Tahu Goreng": .orange, "Ayam Bakar": .brown,
//        "Ayam Gulai": .yellow, "Tempe Orek": .purple, "Sayur Toge": .green, "Sayur Pare Teri": .cyan,
//        "Other": .pink
//    ]    

    init() {
        updateTimeOfDayGreeting()
        fetchCompletedOrders()
    }

    deinit {
        ordersListener?.remove()
    }
    
    enum DetailContentType {
        case none
        case order(OrderFS)
        case dailyGroup(DailySalesGroup)
        case weeklyGroup(WeeklySalesGroup)
    }
    @Published var detailContentType: DetailContentType = .none
    
    func clearDetailSelection() {
        selectedOrderForDetail = nil
        selectedDailyGroupForDetail = nil
        selectedWeeklyGroupForDetail = nil
        detailContentType = .none
    }
     
    func selectOrderForDetail(_ order: OrderFS) {
        clearDetailSelection()
        selectedOrderForDetail = order
        detailContentType = .order(order)
    }

    func selectDailyGroupForDetail(_ group: DailySalesGroup) {
        clearDetailSelection()
        selectedDailyGroupForDetail = group
        detailContentType = .dailyGroup(group)
    }

    func selectWeeklyGroupForDetail(_ group: WeeklySalesGroup) {
        clearDetailSelection()
        selectedWeeklyGroupForDetail = group
        detailContentType = .weeklyGroup(group)
    }
    
    
    func fetchCompletedOrders() {
        isLoading = true
        errorMessage = nil
        ordersListener?.remove()
        
        ordersListener = db.collection("orders")
            .whereField("status", isEqualTo: OrderFS.OrderStatusFS.completed.rawValue)
            .order(by: "orderDate", descending: true)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                self.isLoading = false

                if let error = error {
                    self.errorMessage = "Error fetching orders: \(error.localizedDescription)"
                    print(self.errorMessage!)
                    return
                }

                guard let documents = querySnapshot?.documents else {
                    self.errorMessage = "No orders found."
                    print(self.errorMessage!)
                    self.completedOrders = []
                    self.recalculateAllMetrics()
                    return
                }

                self.completedOrders = documents.compactMap { document -> OrderFS? in
                    try? document.data(as: OrderFS.self)
                }
                self.recalculateAllMetrics()
            }
    }

    func changeTimeRange(to newRange: SalesRecapTimeRange) {
        timeRange = newRange
        filterDataForDisplay()
    }

    private func recalculateAllMetrics() {
        calculateSummaryCardMetrics()
        filterDataForDisplay()
        updateTimeOfDayGreeting()
    }

    private func updateTimeOfDayGreeting() {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        if hour >= 5 && hour < 12 { timeOfDay = "Morning" }
        else if hour >= 12 && hour < 17 { timeOfDay = "Afternoon" }
        else if hour >= 17 && hour < 21 { timeOfDay = "Evening" }
        else { timeOfDay = "Night" }
    }

    // MARK: - Summary Card Calculations
    private func calculateSummaryCardMetrics() {
        let calendar = Calendar.current
        let now = Date()
        
        
        let todayOrders = completedOrders.filter { calendar.isDate($0.orderDate.dateValue(), inSameDayAs: now) }
        incomeToday = todayOrders.reduce(0) { $0 + $1.totalPrice }
        salesCountToday = todayOrders.count

        
        guard let yesterdayDate = calendar.date(byAdding: .day, value: -1, to: now) else {
            incomeDifferenceFromYesterdayAmount = incomeToday // Or 0 if you prefer
            incomeDifferenceFromYesterdaySign = incomeToday > 0 ? "arrow.up" : "minus"
            return
        }
        let yesterdayOrders = completedOrders.filter { calendar.isDate($0.orderDate.dateValue(), inSameDayAs: yesterdayDate) }
        let incomeYesterday = yesterdayOrders.reduce(0) { $0 + $1.totalPrice }
        
        let difference = incomeToday - incomeYesterday
        incomeDifferenceFromYesterdayAmount = abs(difference)
        if difference > 0 { incomeDifferenceFromYesterdaySign = "arrow.up" }
        else if difference < 0 { incomeDifferenceFromYesterdaySign = "arrow.down" }
        else { incomeDifferenceFromYesterdaySign = "minus" }

        
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else {
            incomeThisWeek = 0
            return
        }
        let weekOrders = completedOrders.filter { order in
            weekInterval.contains(order.orderDate.dateValue())
        }
        incomeThisWeek = weekOrders.reduce(0) { $0 + $1.totalPrice }
    }


    // MARK: - Data Filtering & Aggregation for List Display
    private func filterDataForDisplay() {
        let calendar = Calendar.current
        let now = Date()
        
        todayIndividualOrders = completedOrders.filter { calendar.isDate($0.orderDate.dateValue(), inSameDayAs: now) }

        // Daily
        let groupedByDay = Dictionary(grouping: completedOrders) { order -> Date in
            calendar.startOfDay(for: order.orderDate.dateValue())
        }
        dailyAggregatedGroups = groupedByDay.map { (date, ordersInDay) -> DailySalesGroup in
            let totalIncome = ordersInDay.reduce(0) { $0 + $1.totalPrice }
            let aggregatedItems = aggregateAndPrepareDisplayItems(orders: ordersInDay, topN: 6)
            return DailySalesGroup(
                id: date.formatted(.iso8601.year().month().day()),
                date: date,
                totalIncome: totalIncome,
                salesCount: ordersInDay.count,
                aggregatedItems: aggregatedItems
            )
        }.sorted { $0.date > $1.date } // Newest first

        
        // Weekly
        let groupedByWeek = Dictionary(grouping: completedOrders) { order -> DateComponents in
            calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: order.orderDate.dateValue())
        }
        weeklyAggregatedGroups = groupedByWeek.compactMap { (components, ordersInWeek) -> WeeklySalesGroup? in
            guard let weekStartDate = calendar.date(from: components),
                  let weekInterval = calendar.dateInterval(of: .weekOfYear, for: weekStartDate),
                  // weekInterval.end is non-optional if weekInterval is successfully unwrapped
                  let actualWeekEndDate = calendar.date(byAdding: .second, value: -1, to: weekInterval.end)
            else {
                print("Could not determine week start, interval, or actual end date for components: \(components)")
                return nil
            }

            let totalIncome = ordersInWeek.reduce(0) { $0 + $1.totalPrice }
            let aggregatedItems = aggregateAndPrepareDisplayItems(orders: ordersInWeek, topN: 6)

            return WeeklySalesGroup(
                id: "\(components.yearForWeekOfYear ?? 0)-\(components.weekOfYear ?? 0)",
                startDate: weekInterval.start,
                endDate: actualWeekEndDate,
                totalIncome: totalIncome,
                salesCount: ordersInWeek.count,
                aggregatedItems: aggregatedItems
            )
        }.sorted { $0.startDate > $1.startDate } // Newest week first
    }
    
        private func aggregateAndPrepareDisplayItems(orders: [OrderFS], topN: Int) -> [RecapDisplayItem] {
        var finalDisplayItems: [RecapDisplayItem] = []
        var tempItemCounts: [String: Int] = [:]
        for order in orders {
            for item in order.items {
                tempItemCounts[item.name, default: 0] += item.quantity
            }
        }

        let sortedAllItems = tempItemCounts.sorted { $0.value > $1.value }
        var currentOtherCount = 0
                
        for (name, count) in sortedAllItems {
            if finalDisplayItems.count < (topN - 1) {                
                finalDisplayItems.append(RecapDisplayItem(name: name, count: count))
            } else {
                currentOtherCount += count
            }
        }
        if currentOtherCount > 0 {
            finalDisplayItems.append(RecapDisplayItem(name: "Other", count: currentOtherCount))
        }

        return finalDisplayItems.sorted { $0.count > $1.count }.prefix(topN).map{$0}
    }

    func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "Rp "
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "Rp 0"
    }

    func formatDateForDisplay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    func formatWeekRange(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDate(start, equalTo: end, toGranularity: .month) &&
           calendar.isDate(start, equalTo: end, toGranularity: .year) {
            formatter.dateFormat = "MMM d"
            let endDayFormatter = DateFormatter()
            endDayFormatter.dateFormat = "d, yyyy"
            return "\(formatter.string(from: start)) - \(endDayFormatter.string(from: end))"
        } else {
            formatter.dateFormat = "MMM d, yyyy"
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        }
    }
}

enum SalesRecapTimeRange: String, CaseIterable, Identifiable {
    case today = "Today"
    case daily = "Daily"
    case weekly = "Weekly"

    var id: String { self.rawValue }
}
