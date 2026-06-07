# 🚴‍♂️ Bike Shop App

A complete, full-stack modern e-commerce solution for browsing and purchasing bikes and accessories. The frontend is built with Flutter and adheres to strict MVVM architecture, while the backend is powered by Node.js/Express.

## ✨ Key Features

- **🛍️ Complete E-Commerce Flow:** Browse products, manage cart, and seamlessly checkout.
- **💳 Real Payments:** Integrated with Stripe for secure, real-time payment processing.
- **📱 Push Notifications:** Firebase Cloud Messaging (FCM) and local notifications for order status and payment success updates.
- **🚦 Robust Navigation:** Centralized routing and deep-linking powered by `go_router`.
- **📂 Dynamic Filtering:** Category filtering, Deals, and New Arrivals all driven by backend data.
- **🖼️ Rich Media:** Supports single or multiple images with carousel views for detailed product inspection.
- **🎨 Modern UI:** Glassmorphism cards, custom `AppTheme`, smooth animations (`AnimatedContainer`, `AnimatedScale`), and responsive layout.

## 📸 Screenshots

<table align="center">
  <tr>
    <td><img src="https://github.com/user-attachments/assets/a2c9768f-d1dc-4154-bea8-c1f64ae13a61" width="250" alt="Screenshot 1" /></td>
    <td><img src="https://github.com/user-attachments/assets/afa048dc-cc23-4f8a-bd2a-3b5c69f176a3" width="250" alt="Screenshot 2" /></td>
    <td><img src="https://github.com/user-attachments/assets/8f9bb44b-bb65-475f-8e07-94eda5c7269d" width="250" alt="Screenshot 3" /></td>
    <td><img src="https://github.com/user-attachments/assets/9b0f70bd-4c6a-4047-b595-fcb83b582bd0" width="250" alt="Screenshot 4" /></td>
  </tr>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/6d1170dc-b599-4941-99da-2abc3470a07b" width="250" alt="Screenshot 5" /></td>
    <td><img src="https://github.com/user-attachments/assets/68b69fb9-d2bd-426b-b3b5-bda50faf02d3" width="250" alt="Screenshot 6" /></td>
    <td><img src="https://github.com/user-attachments/assets/bcd9d614-2f19-4403-8989-d7abcd06682f" width="250" alt="Screenshot 7" /></td>
    <td><img src="https://github.com/user-attachments/assets/b9b3602c-33b3-44f9-b58d-76ad67c77fbb" width="250" alt="Screenshot 8" /></td>
  </tr>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/bb808d53-0f97-4a1d-b114-444e35a2d4c9" width="250" alt="Screenshot 9" /></td>
    <td><img src="https://github.com/user-attachments/assets/27606e60-2afe-450b-b96b-e758b50b4383" width="250" alt="Screenshot 10" /></td>
    <td><img src="https://github.com/user-attachments/assets/d58221fd-f8a5-4163-821b-99368dc90967" width="250" alt="Screenshot 11" /></td>
    <td></td>
  </tr>
</table>

## 🧩 Architecture

This project strictly adheres to the **MVVM (Model-View-ViewModel)** architectural pattern:
- **`BaseViewModel`**: Standardizes state management (`setLoading`, `setSuccess`, `setError`) for all ViewModels in the app.
- **Dependency Injection**: Utilizes `ChangeNotifierProvider` and `ChangeNotifierProxyProvider` to safely inject dependencies (e.g., Auth, Payment, and Notification services into the Checkout process) without coupling the Views to business logic.
- **Service Layer**: Dedicated singleton services for HTTP communication, Stripe operations, and Firebase Notifications to keep ViewModels lean and focused.

## 🛠️ Tech Stack

**Frontend (Flutter):**
- **Framework:** Flutter (Material 3)
- **State Management:** Provider
- **Routing:** go_router
- **Payments:** flutter_stripe
- **Notifications:** firebase_messaging, flutter_local_notifications

**Backend (Node.js):**
- **Server:** Node.js with Express
- **API:** RESTful endpoints for fetching products, categories, processing orders, and generating Stripe payment intents.

## 🚀 Getting Started

### 1. Backend Setup
1. Navigate to your Node.js backend directory.
2. Run `npm install` to install dependencies.
3. Configure your `.env` variables (e.g., Database URL, Stripe Secret Key, Firebase Admin credentials).
4. Run `npm start` to start the Node.js server.

### 2. Frontend Setup
1. Clone the repository and open the `bike_shop` folder.
2. Update the `baseUrl` in `lib/config/api_config.dart` to match your local IP address where the Node server is running.
3. Run `flutter pub get` to install dependencies.
4. Add your `google-services.json` and `GoogleService-Info.plist` for Firebase push notification support.
5. Run the app: `flutter run`
