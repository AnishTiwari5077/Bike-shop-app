 1 The first issues  i got on termnial is
════════ Exception caught by Flutter framework ═════════════════════════════════
ListTile background color or ink splashes may be invisible.
════════════════════════════════════════════════════════════════════════════════

2. The second issues is on code releated to price and tax after adding taxes 
    i was not getting proper total and  tax amount after that  writing the code for price and tax calculation in cart_viewmodel. Also on foreground push notification inside app i get correct about price but on receiveing email i only got price on subtotal not Total also on MAngoDb i got price of subtotal not total also on stipe .

3. the  third issues is  on bike_shop\lib\views\cart_screen.dart
      Don't use 'BuildContext's across async gaps, guarded by an unrelated 'mounted' check.
      Guard a 'State.context' use with a 'mounted' check on the State, and other BuildContext use with a 'mounted' check on the BuildContext.


4. The fourth issues is on bike_shop\lib\views\checkout_screen.dart
      Use the null-aware marker '?' rather than a null check via an 'if'.
      Try using '?'.

5. The fifth issues is on bike_shop\lib\views\profile_screen.dart
      Don't use 'BuildContext's across async gaps, guarded by an unrelated 'mounted' check.
      Guard a 'State.context' use with a 'mounted' check on the State, and other BuildContext use with a 'mounted' check on the BuildContext.

6. The sixth issues releated to dialog  when i turn immediately wifi or net i got 
   this message StripeException: IOException during API request to Stripe (https://api.stripe.com/v1/payment_intents/pi_3TcHiXHKrFDpSpIk0aKAATjM/confirm): Failed to connect to api.stripe.com/52.74.98.83:443. Please check your internet connection and try again. If this problem persists, you should check Stripe's service status at https://status.stripe.com/, or let us know at support@stripe.com    instead of this i want professional like network interuptted or something else.
   