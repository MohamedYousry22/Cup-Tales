# Cup Tales store submission checklist

## Google Play update

- Upload `Cup-Tales-1.0.5-build-6.aab` to Internal or Closed testing first.
- Install the Play-distributed build and test Google Sign-In and one order.
- Confirm target API 36, version name 1.0.5, version code 6.
- Update Data safety for name, email, phone, addresses, user ID, cart/order
  history, and Android push identifiers.
- Set the privacy-policy URL to
  `https://mohamedyousry22.github.io/Cup-Tales/privacy-policy.html`.
- Set the account-deletion URL to
  `https://mohamedyousry22.github.io/Cup-Tales/delete-account.html`.
- Provide an active review account under App access if Google requests login.
- Roll out to production after the closed/internal test succeeds.

## New App Store listing

- Create an App ID and App Store Connect app using bundle ID
  `com.cup.tales.cupTales`.
- Use the Cup Tales display name, primary language Arabic or English, and the
  correct SKU.
- Create or allow Xcode to manage an Apple Distribution certificate and App
  Store provisioning profile.
- Upload the signed 1.0.5 (6) archive through Xcode Organizer or Transporter.
- Add the public privacy-policy URL.
- Set the support URL to
  `https://mohamedyousry22.github.io/Cup-Tales/support.html`.
- Complete App Privacy using the categories declared in
  `ios/Runner/PrivacyInfo.xcprivacy`; data is linked to the user and used only
  for app functionality, not tracking.
- Add screenshots for each required device size, app description, keywords,
  support URL, age rating, and category.
- Paste `docs/app-store-review-notes.md` into App Review notes and add the demo
  password from the secure release handoff.
- Submit TestFlight first, verify the full demo flow, then submit for App Review.
