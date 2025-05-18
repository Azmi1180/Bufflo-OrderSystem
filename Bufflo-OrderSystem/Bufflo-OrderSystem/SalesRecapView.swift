//
//  SalesRecapView.swift
//  Bufflo-OrderSystem
//
//  Created by Muhammad Azmi on 17/05/25.
//

// SalesRecapView.swift
import SwiftUI

struct SalesRecapView: View {
    @StateObject private var viewModel = SalesRecapViewModel()
    private let detailGridColumns = [GridItem(.adaptive(minimum: 120), spacing: 10)]
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        NavigationSplitView {
            sidebarView()
                .navigationTitle("Sales Recap")
        } detail: {
            detailAreaView()
                .navigationTitle(detailNavigationTitle())
                .navigationBarTitleDisplayMode(.inline)
        }
        .background(Color(.systemGray6))
        .onAppear {
            // viewModel.fetchCompletedOrders() // Fetch di init
        }
    }

    // MARK: - Sidebar View (Filters and List)
    @ViewBuilder
    private func sidebarView() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if viewModel.isLoading {
                ProgressView("Loading Sales Data...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            } else {
                summaryCard()
                    .padding([.horizontal, .top])
                    .padding(.bottom, 10)

                Picker("Time Range", selection: $viewModel.timeRange) {
                    ForEach(SalesRecapTimeRange.allCases) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 10)
                .onChange(of: viewModel.timeRange) { _ in
                    viewModel.changeTimeRange(to: viewModel.timeRange)
                    viewModel.clearDetailSelection()
                }
                
                listAreaForSelection()
            }
        }
        .background(Color(.systemGray5))
    }

    // MARK: - Summary Card
    @ViewBuilder
    private func summaryCard() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Total Income This Week")
                .font(horizontalSizeClass == .compact ? .title3 : .title2).bold()
            Text(viewModel.formatCurrency(viewModel.incomeThisWeek))
                .font(horizontalSizeClass == .compact ? .title : .largeTitle).bold()
                .padding(.bottom, 5)

            HStack {
                VStack(alignment: .leading) {
                    Text("Today's Income")
                        .font(.caption)
                    HStack(alignment: .lastTextBaseline, spacing: 4){
                        Text(viewModel.formatCurrency(viewModel.incomeToday))
                            .font(.headline).bold()
                        if viewModel.incomeToday != 0 || viewModel.incomeDifferenceFromYesterdayAmount != 0 {
                            Label(viewModel.formatCurrency(viewModel.incomeDifferenceFromYesterdayAmount), systemImage: viewModel.incomeDifferenceFromYesterdaySign)
                                .font(.caption2).bold()
                                .foregroundColor(viewModel.incomeDifferenceFromYesterdaySign == "arrow.up" ? .green : (viewModel.incomeDifferenceFromYesterdaySign == "arrow.down" ? .red : .gray))
                        }
                    }
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text("Today's Sales")
                        .font(.caption)
                    Text("\(viewModel.salesCountToday)")
                        .font(.headline).bold()
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.8))
        .foregroundColor(.white)
        .cornerRadius(15)
    }
    
    @ViewBuilder
    private func listAreaForSelection() -> some View {
        List {
            switch viewModel.timeRange {
            case .today:
                if viewModel.todayIndividualOrders.isEmpty {
                    noDataView(for: .today)
                } else {
                    ForEach(viewModel.todayIndividualOrders) { order in
                        todayOrderRow(order: order)
                            .contentShape(Rectangle())
                            .onTapGesture { viewModel.selectOrderForDetail(order) }
                            .listRowBackground(viewModel.selectedOrderForDetail?.id == order.id ? Color.blue.opacity(0.2) : Color.clear)
                    }
                }
            case .daily:
                if viewModel.dailyAggregatedGroups.isEmpty {
                    noDataView(for: .daily)
                } else {
                    ForEach(viewModel.dailyAggregatedGroups) { group in
                        dailyGroupRow(group: group)
                            .contentShape(Rectangle())
                            .onTapGesture { viewModel.selectDailyGroupForDetail(group) }
                            .listRowBackground(viewModel.selectedDailyGroupForDetail?.id == group.id ? Color.blue.opacity(0.2) : Color.clear)
                    }
                }
            case .weekly:
                if viewModel.weeklyAggregatedGroups.isEmpty {
                    noDataView(for: .weekly)
                } else {
                    ForEach(viewModel.weeklyAggregatedGroups) { group in
                        weeklyGroupRow(group: group)
                            .contentShape(Rectangle())
                            .onTapGesture { viewModel.selectWeeklyGroupForDetail(group) }
                            .listRowBackground(viewModel.selectedWeeklyGroupForDetail?.id == group.id ? Color.blue.opacity(0.2) : Color.clear)
                    }
                }
            }
        }
        .listStyle(.plain) // atau .insetGrouped
    }
    
    @ViewBuilder
    private func noDataView(for range: SalesRecapTimeRange) -> some View {
        Section {
            Text("No Sales Data for \(range.rawValue)")
                .font(.headline)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 50)
        }
    }

    
    @ViewBuilder
    private func todayOrderRow(order: OrderFS) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Order #\(order.orderNumber)")
                    .font(.headline)
                Text(viewModel.formatDateForDisplay(order.orderDate.dateValue()))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(viewModel.formatCurrency(order.totalPrice))
                .font(.subheadline).bold()
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func dailyGroupRow(group: DailySalesGroup) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(group.date, style: .date)
                    .font(.headline)
                Text("\(group.salesCount) sales")
                    .font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Text(viewModel.formatCurrency(group.totalIncome))
                .font(.subheadline).bold()
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private func weeklyGroupRow(group: WeeklySalesGroup) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(viewModel.formatWeekRange(start: group.startDate, end: group.endDate))
                    .font(.headline)
                Text("\(group.salesCount) sales")
                    .font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Text(viewModel.formatCurrency(group.totalIncome))
                .font(.subheadline).bold()
        }
        .padding(.vertical, 4)
    }


    // MARK: - Detail Area View
    @ViewBuilder
    private func detailAreaView() -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                switch viewModel.detailContentType {
                case .none:
                    Text("Select an item from the list to see details.")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .padding()
                case .order(let order):
                    orderDetailView(order: order)
                case .dailyGroup(let group):
                    dailyGroupDetailView(group: group)
                case .weeklyGroup(let group):
                    weeklyGroupDetailView(group: group)
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    private func detailNavigationTitle() -> String {
        switch viewModel.detailContentType {
        case .none:
            return "Details"
        case .order(let order):
            return "Order #\(order.orderNumber)"
        case .dailyGroup(let group):
            return group.date.formatted(date: .long, time: .omitted)
        case .weeklyGroup(let group):
            return viewModel.formatWeekRange(start: group.startDate, end: group.endDate)
        }
    }
    
    @ViewBuilder
    private func orderDetailView(order: OrderFS) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Order Date:").bold()
                Text(viewModel.formatDateForDisplay(order.orderDate.dateValue()))
            }
            HStack {
                Text("Total Amount:").bold()
                Text(viewModel.formatCurrency(order.totalPrice))
            }
            HStack {
                Text("Status:").bold()
                Text(order.status.rawValue)
            }
            if let userId = order.userId, !userId.isEmpty, userId != "anonymous" {
                HStack {
                    Text("User ID:").bold()
                    Text(userId)
                }
            }
            
            Divider()
            Text("Items:").font(.title3).bold()
            ForEach(order.items) { item in
                HStack {
                    Text("• \(item.quantity)x \(item.name)")
                    Spacer()
                    Text(viewModel.formatCurrency(item.price * Double(item.quantity)))
                }
                .font(.subheadline)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))
    }

    @ViewBuilder
    private func dailyGroupDetailView(group: DailySalesGroup) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Total Sales:").bold()
                Text("\(group.salesCount)")
            }
            HStack {
                Text("Total Income:").bold()
                Text(viewModel.formatCurrency(group.totalIncome))
            }
            
            Divider()
            Text("Top Sold Items:").font(.title3).bold()
            if group.aggregatedItems.isEmpty {
                Text("No item data for this day.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(group.aggregatedItems) { item in
                    HStack {
                        Text("• \(item.name)")
                        Spacer()
                        Text("\(item.count) sold")
                    }
                    .font(.subheadline)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))
    }
    
    @ViewBuilder
    private func weeklyGroupDetailView(group: WeeklySalesGroup) -> some View {
         VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Total Sales:").bold()
                Text("\(group.salesCount)")
            }
            HStack {
                Text("Total Income:").bold()
                Text(viewModel.formatCurrency(group.totalIncome))
            }
            
            Divider()
            Text("Top Sold Items:").font(.title3).bold()
             if group.aggregatedItems.isEmpty {
                 Text("No item data for this week.")
                     .foregroundColor(.secondary)
             } else {
                 ForEach(group.aggregatedItems) { item in
                     HStack {
                         Text("• \(item.name)")
                         Spacer()
                         Text("\(item.count) sold")
                     }
                     .font(.subheadline)
                 }
             }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))
    }
}

struct SalesRecapView_Previews: PreviewProvider {
    static var previews: some View {
        SalesRecapView()
            .previewDevice("iPad Pro (11-inch) (4th generation)")
            // .environmentObject(SalesRecapViewModel())
    }
}
