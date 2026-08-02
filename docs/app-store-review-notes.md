# Cup Tales — App Store Review Notes

Use the following text in **App Store Connect → App Review Information → Notes**.
Keep the password in the secure release handoff; do not commit it to GitHub.

## Review notes

Cup Tales is a café ordering app for physical food and beverages.

- The app is browseable at all times on iOS.
- Normal customer orders are accepted daily from 07:30 through 00:30
  Africa/Cairo time. Outside these hours, tapping Confirm Order displays the
  operating-hours message without blocking the rest of the app.
- The supplied App Review account is authorized to complete test orders at any
  time so App Review can verify the full checkout flow.
- All payments in this release are cash on pickup, drive-thru, or delivery.
  The app does not sell digital goods or subscriptions.
- iOS uses Cup Tales email/password authentication only. Google Sign-In is
  offered on Android only. Sign in with Apple is not included.
- Account deletion is available in Profile → Delete account.
- Push notifications are not offered or initialized on iOS in this release.

### Demo account

- Email: `appreview@cuptales.test`
- Password: paste the password from the secure release handoff

### Checkout test

1. Sign in with the demo account.
2. Add any product to the cart.
3. Continue to checkout.
4. Select pickup, drive-thru, or home delivery.
5. Confirm the cash order.

The backend is live and the demo profile already contains a valid test phone
number.
