# Kawiarnia (Coffee Shop App)

A comprehensive mobile application designed for efficient coffee shop management, built with **Flutter** and **Firebase**. This project features distinct interfaces for both customers and employees, ensuring a seamless experience from order placement to fulfillment.

## Features

###  Customer Panel
- **Menu & Ordering:** Browse a categorized menu, view product details, and manage your cart.
- **Order Tracking:** Real-time updates on order status with push notifications.
- **Loyalty Program:** Collect points with every purchase and redeem vouchers for discounts.
- **Subscriptions:** Manage active coffee subscriptions.
- **QR Scanning:** Scan codes for instant promotions or loyalty actions.
- **Profile:** Manage personal details and view order history.

###  Employee Panel
- **Order Management:** View incoming orders in real-time and update their status (e.g., Preparing, Ready).
- **Payments:** Process payments securely and confirm transactions.
- **Analytics:** View daily sales statistics and performance metrics.
- **Promotions:** Create and manage active discounts and promotional campaigns.

## Technology Stack

- **Frontend:** Flutter (Dart)
- **Backend:** Firebase (Authentication, Firestore, Cloud Functions, Messaging)
- **State Management:** Provider
- **UI/UX:** Google Fonts, Flutter Animate
- **Hardware Integration:** Mobile Scanner (Camera for QR codes)

## Getting Started

To run this project locally, follow these steps:

1. **Prerequisites:**
   - Ensure you have the [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
   - Set up a Firebase project.

2. **Installation:**
   ```bash
   # Clone the repository
   git clone https://github.com/yourusername/kawiarnia.git

   # Navigate to the project directory
   cd kawiarnia

   # Install dependencies
   flutter pub get
   ```

3. **Configuration:**
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) files to the respective platform directories.

4. **Run the App:**
   ```bash
   flutter run
   ```

## License

This project is licensed under the MIT License - see the LICENSE file for details.
