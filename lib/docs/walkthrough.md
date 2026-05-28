# Payment Reliability Fix — Walkthrough

## Problem Solved

When a user's internet drops after payment, Stripe charges successfully but MongoDB stays `pending`, no email is sent, and no notification fires. The user had to tap "Pay Again" to trigger recovery.

## Changes Made

### 1. [NEW] [orderEmail.js](file:///f:/nodejs_bike/helpers/orderEmail.js) — Shared Email Helper

Extracted `sendOrderConfirmationEmail()` from the webhook controller into a standalone module. Now used by **3 paths**:
- `confirmOrder` (client callback)
- `handleWebhook` (Stripe webhook)
- `recoverStalePendingOrders` (background cron)

---

### 2. [MODIFY] [paymentcontroller.js](file:///f:/nodejs_bike/controllers/paymentcontroller.js) — Core Fix

**`confirmOrder` now sends email** (lines ~210–230):
- Previously only set `status: 'paid'` — the email was webhook-only
- Now calls `sendOrderConfirmationEmail(updated)` after marking paid
- Idempotency guard prevents double emails

**New `recoverPendingOrders` endpoint** (lines ~240+):
- Accepts `{ customerId }` from Flutter app
- Finds all `pending` orders for that customer
- Searches Stripe API (`paymentIntents.search`) for each order's PaymentIntent
- If Stripe says `succeeded` → marks paid + sends email
- If Stripe says `canceled` → marks failed
- Returns list of recovered orders for Flutter to refresh UI

---

### 3. [MODIFY] [webhookcontroller.js](file:///f:/nodejs_bike/controllers/webhookcontroller.js) — Use Shared Helper

Replaced inline `sendOrderConfirmationEmail` with `require('../helpers/orderEmail')`. Webhook behavior is identical.

---

### 4. [MODIFY] [payments.js](file:///f:/nodejs_bike/routes/payments.js) — New Route

Added `POST /payments/recover-pending` → `recoverPendingOrders`

---

### 5. [NEW] [recoverOrders.js](file:///f:/nodejs_bike/jobs/recoverOrders.js) — Background Cron

Runs every 5 minutes via `setInterval` (no extra npm deps):
- Finds `pending` orders older than 2 minutes
- Checks Stripe for actual payment status
- Auto-completes paid orders + sends email
- Auto-fails orders older than 1 hour with no Stripe PaymentIntent
- First run happens 10 seconds after boot

---

### 6. [MODIFY] [server.js](file:///f:/nodejs_bike/server.js) — Start Cron

Imported and called `startRecoveryCron()` after DB connection.

## How the Fix Works — All 3 Recovery Paths

```
Path 1: NORMAL (internet works)
  Flutter → confirmPayment → confirmOrder → MongoDB paid ✅ + email ✅

Path 2: WEBHOOK (Stripe delivers event)
  Stripe → webhook → MongoDB paid ✅ + email ✅

Path 3: RECOVERY (internet dropped, both above failed)
  Background cron (every 5 min) → checks Stripe → MongoDB paid ✅ + email ✅
  OR
  Flutter app startup → POST /recover-pending → same result ✅
```

## Flutter Integration

To use the new recovery endpoint, call it on app startup:

```dart
// In your Flutter app initialization (after login):
Future<void> recoverPendingOrders(String customerId) async {
  try {
    final res = await http.post(
      Uri.parse('$_baseUrl/payments/recover-pending'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'customerId': customerId}),
    ).timeout(const Duration(seconds: 15));

    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && (data['recovered'] as List).isNotEmpty) {
      // Refresh orders list — some were auto-recovered
      debugPrint('🔄 Recovered ${data['recovered'].length} pending orders');
    }
  } catch (e) {
    debugPrint('recoverPendingOrders: $e');
  }
}
```

## Verification

- ✅ All modules load without import errors
- ✅ No new npm dependencies required
- ✅ Idempotency guards prevent duplicate emails/updates across all 3 paths

## Frontend App Fixes (Offline Payment Reliability)

### 1. [MODIFY] [order_viewmodel.dart](file:///f:/flutter-bike-shop/bike_shop/lib/viewmodels/order_viewmodel.dart)
- Added `checkAndRecover()` method to proactively check if the device is online and recover pending orders immediately.
- Updated `startConnectivityMonitor()` to call `checkAndRecover()` on startup rather than only waiting for network *changes*.
- Added a 2-second delay in the `onConnectivityChanged` listener before calling the recovery HTTP request, ensuring DNS and routing have time to settle after the connection event fires.

### 2. [MODIFY] [order_screen.dart](file:///f:/flutter-bike-shop/bike_shop/lib/views/order_screen.dart)
- Wrapped the active/completed orders list in a `RefreshIndicator`.
- Users can now manually pull-to-refresh to trigger `checkAndRecover()` and immediately move a stuck pending order to completed if the network is back online.

### 3. [MODIFY] [checkout_screen.dart](file:///f:/flutter-bike-shop/bike_shop/lib/views/checkout_screen.dart)
- `CheckoutScreen` now actively watches `OrdersProvider`.
- If an order is successfully recovered in the background (status becomes `delivered`), the screen automatically updates to prevent double payments and shows the Payment Success sheet immediately.
