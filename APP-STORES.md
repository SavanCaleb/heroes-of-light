# Heroes of Light on phones

There are three ways to play on a phone, from easiest to most official.

## 1. Play in the browser (iPhone and Android, works today)

Open **https://savancaleb.github.io/heroes-of-light/next/** in Safari (iPhone) or Chrome (Android), turn the phone sideways, and tap Share > "Add to Home Screen" (iPhone) or menu > "Install app" (Android).

## 2. Android test app (APK)

Download it on the phone: **https://github.com/SavanCaleb/heroes-of-light/releases/download/v1.0-test/HeroesOfLight-android-test.apk** (74 MB, Android 7 or newer). It is also built at `apps/HeroesOfLight-android-test.apk` on Savan's PC.

1. Open the download link on the Android phone (or copy the file over).
2. Open it on the phone. Android asks to allow installing apps from that source: allow it once.
3. Tap Install. Heroes of Light appears with the sword-hero icon.

This test app is signed with a test (debug) key, so it can be shared with friends but not uploaded to the Play Store.

To rebuild it after changes:

```
godot --headless --path godot --export-debug "Android" build/android/HeroesOfLight.apk
```

## 3. Google Play Store

1. Create a Google Play developer account ($25 one time) at play.google.com/console.
2. Make a private **upload key** (keep the file and password safe forever, never commit it):
   `keytool -genkeypair -v -keystore heroes-upload.keystore -alias heroes -keyalg RSA -keysize 2048 -validity 10000`
3. In Godot: Project > Install Android Build Template, then in Export > Android set
   *Gradle Build > Use Gradle Build* on, *Export Format* to AAB, and the release keystore fields to the upload key.
4. Export Release (`HeroesOfLight.aab`), then in Play Console create the app, fill in the store listing, content rating (choose "Everyone"), and upload the AAB to Internal testing first, then Production.

## 4. Apple App Store (iPhone)

iPhone apps can only be built with Xcode on a Mac.

1. Join the Apple Developer Program ($99 per year) at developer.apple.com.
2. On a Mac, install Godot 4.7 and Xcode, open this project, and in Export > iOS set your **App Store Team ID** (from developer.apple.com > Membership) and the bundle ID `com.savan.heroesoflight`.
3. Export the Xcode project, open it in Xcode, choose your team under Signing, then Product > Archive > Distribute App > App Store Connect.
4. In App Store Connect, add screenshots and a description, test with TestFlight, then submit for review.

No Mac? A cloud build service such as Codemagic can build the iPhone app from this GitHub repository using Apple's servers.
