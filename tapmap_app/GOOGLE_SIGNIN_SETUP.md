# Google Sign-In Setup for Android

If you're experiencing issues with Google Sign-In on Android, follow these steps:

## 1. Get Your SHA-1 Fingerprint

Run the helper script:
```bash
cd tapmap_app
./get_sha1.sh
```

Or manually:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Look for the **SHA1:** line and copy the fingerprint (format: `XX:XX:XX:...`).

## 2. Add SHA-1 to Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **tapmap-7b2f2**
3. Click the gear icon ⚙️ next to "Project Overview"
4. Select **Project Settings**
5. Scroll down to **Your apps** section
6. Click on your Android app (package: `com.dbasi.tapmap`)
7. Click **Add fingerprint**
8. Paste your SHA-1 fingerprint
9. Click **Save**

## 3. Download Updated google-services.json

1. Still in Firebase Console > Project Settings
2. In the **Your apps** section, find your Android app
3. Click **Download google-services.json**
4. Replace the file at: `tapmap_app/android/app/google-services.json`

## 4. Verify OAuth Client Configuration

The `google-services.json` should contain an Android OAuth client (client_type: 1). If it only has a web client (client_type: 3), you may need to:

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select project: **tapmap-7b2f2**
3. Go to **APIs & Services** > **Credentials**
4. Ensure there's an **OAuth 2.0 Client ID** for Android
5. If missing, create one with package name: `com.dbasi.tapmap`
6. Add the SHA-1 fingerprint to the OAuth client
7. Download the updated `google-services.json` from Firebase

## 5. Rebuild Your App

After updating `google-services.json`:
```bash
cd tapmap_app
flutter clean
flutter build apk --release
```

## Common Issues

- **PlatformException: sign_in_failed**: Usually means SHA-1 fingerprint is missing or incorrect
- **PlatformException: SIGN_IN_REQUIRED**: OAuth client not properly configured
- **ID token is null**: Check that `serverClientId` matches your Web OAuth client ID

## Testing

After setup, test Google Sign-In:
1. Install the APK on your device
2. Open the app and tap "Login"
3. Tap "Continue with Google"
4. Select your Google account
5. You should be signed in successfully

