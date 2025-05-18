# Bufflo - Order Management System

**Bufflo** is a SwiftUI-based application designed to streamline order management for GOP Food Tenants (you can use it for small restaurants too). It leverages Firebase for real-time data synchronization and backend services. 
Bufflo helps you ensure accurate order processing and provides continuous monitoring of your kitchen's incoming orders.


## Features

*   **Real-time Order Tracking:** View and manage orders as they come in.
*   **Customer Ordering Interface:** Allows customers (or staff) to place new orders from a configurable menu.
*   **Order Management Dashboard:** Staff/admins can view active and completed orders, and update order statuses (e.g., Pending, Completed, Cancelled).
*   **Sales Recap & Analytics:** Provides a dashboard to view sales summaries for today, daily breakdowns, and weekly trends, including total income and top-selling items.
*   **Firebase Backend:**
    *   **Firestore:** Used as the primary database for menu items, orders, and application counters (like sequential order numbers).
    *   **Firebase Authentication (Anonymous):** Provides a basic user identity for associating orders, even for guest users. [Mention if you implement fuller authentication].
*   **iPad Optimized:** The Sales Recap dashboard and other relevant views are designed for a good user experience on iPad, including landscape and portrait orientations.

## Tech Stack

*   **UI:** SwiftUI
*   **Backend & Database:** Firebase (Firestore, Firebase Authentication)
*   **Voice Integration:** App Intents for Siri
*   **Language:** Swift
*   **Platform:** iOS (and iPadOS)
