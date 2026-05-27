# Fix Payment Reliability: Auto-Complete Orders After Network Drops

## Problem

When a user pays and their internet disconnects immediately after:

1. **Stripe charges successfully** (money is taken)
2. **Webhook fails or is delayed** → MongoDB stays `pending`
3. **No email, no notification** sent
4. **User must tap "Pay Again"** which triggers recovery, but the experience is broken

### Current Architecture Gaps

| Path | What it does | What's missing |
|------|-------------|----------------|
| `confirmOrder` endpoint | Sets status to `paid` | ❌ No email sent, no notification |
| Webhook (`payment_intent.succeeded`) | Sets status to `paid` + sends email | ❌ Only works if webhook URL is reachable |
| No background recovery | — | ❌ No cron/polling to catch orphaned orders |

## Desired Flow

```
User pays → Internet drops → Stripe charges → Backend auto-recovers →
MongoDB updated + Email sent + Notification triggered
```

## Proposed Changes

### 1. Backend: Extract shared `finalizeOrder` helper

#### [MODIFY] [paymentcontroller.js](file:///f:/nodejs_bike/controllers/paymentcontroller.js)

Add a new `confirmOrder` that **also sends the confirmation email** (reuse the email logic from `webhookcontroller.js`). Currently it only sets `status: 'paid'` without sending email.

Changes:
- Import `transporter` from `../config/mailer`
- After updating status to `paid`, call `sendOrderConfirmationEmail(order)` (same helper used by webhook)
- Extract the email-sending helper into a shared utility so both webhook and confirmOrder use the same function

---

### 2. Backend: Create shared email helper

#### [NEW] [helpers/orderEmail.js](file:///f:/nodejs_bike/helpers/orderEmail.js)

Extract `sendOrderConfirmationEmail()` from `webhookcontroller.js` into a shared module so:
- `confirmOrder` (direct client callback) can send emails
- `handleWebhook` (Stripe webhook) can send emails
- Future recovery job can send emails

---

### 3. Backend: Update webhook to use shared helper

#### [MODIFY] [webhookcontroller.js](file:///f:/nodejs_bike/controllers/webhookcontroller.js)

- Remove inline `sendOrderConfirmationEmail` function
- Import from `../helpers/orderEmail`

---

### 4. Backend: Add payment recovery endpoint

#### [MODIFY] [paymentcontroller.js](file:///f:/nodejs_bike/controllers/paymentcontroller.js)

Add `recoverPendingOrders` endpoint:
- Accepts `customerId` from the Flutter app
- Finds all orders for that customer with `status: 'pending'`
- For each, queries Stripe API to check if the PaymentIntent actually succeeded
- If Stripe says `succeeded` → update MongoDB to `paid` + send email
- Returns list of recovered orders so the Flutter app can refresh UI

#### [MODIFY] [payments.js](file:///f:/nodejs_bike/routes/payments.js)

- Register `POST /payments/recover-pending` route

---

### 5. Backend: Add background recovery cron job

#### [NEW] [jobs/recoverOrders.js](file:///f:/nodejs_bike/jobs/recoverOrders.js)

A periodic job (runs every 5 minutes) that:
- Finds all `pending` orders older than 2 minutes
- For each, checks Stripe PaymentIntent status via metadata lookup
- If Stripe says `succeeded` → mark as `paid` + send email
- If Stripe says `canceled` or intent doesn't exist → mark as `failed`
- Logs all recovery actions

#### [MODIFY] [server.js](file:///f:/nodejs_bike/server.js)

- Import and start the recovery cron using `setInterval` (no extra dependencies needed)

---

## Summary of All Changes

| File | Action | Purpose |
|------|--------|---------|
| `helpers/orderEmail.js` | **NEW** | Shared email helper |
| `controllers/paymentcontroller.js` | **MODIFY** | `confirmOrder` sends email; add `recoverPendingOrders` |
| `controllers/webhookcontroller.js` | **MODIFY** | Use shared email helper |
| `routes/payments.js` | **MODIFY** | Add recovery route |
| `jobs/recoverOrders.js` | **NEW** | Background cron to catch orphaned orders |
| `server.js` | **MODIFY** | Start recovery cron on boot |

## Open Questions

> [!IMPORTANT]
> **Recovery cron interval**: I'm defaulting to every 5 minutes. Would you prefer a different interval?

> [!IMPORTANT]
> **Pending order age threshold**: The cron only recovers orders that have been `pending` for more than 2 minutes (to avoid racing with normal webhook flow). Is 2 minutes acceptable?

> [!NOTE]
> **No new npm dependencies needed** — `setInterval` is used for the cron instead of adding `node-cron`. The email helper is just a file refactor.

## Verification Plan

### Automated Tests
- Start the server with `npm start`
- Hit `/health` to verify it boots
- Check console logs for the recovery cron starting

### Manual Verification
- Create a test pending order in MongoDB
- Wait for the cron to pick it up and verify it transitions to `paid` (if Stripe confirms)
- Verify confirmation email is sent by `confirmOrder` endpoint (not just webhook)
