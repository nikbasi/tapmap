#!/bin/bash
# Alternative method to get SHA-1 using Android Studio's Java

echo "🔍 Getting SHA-1 fingerprint..."
echo ""

# Find Android Studio's Java
AS_JAVA_PATHS=(
    "/Applications/Android Studio.app/Contents/jre/Contents/Home/bin/keytool"
    "/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool"
    "/Applications/Android Studio.app/Contents/jre/jdk/Contents/Home/bin/keytool"
)

KEYTOOL=""
for path in "${AS_JAVA_PATHS[@]}"; do
    if [ -f "$path" ]; then
        KEYTOOL="$path"
        echo "✓ Found keytool at: $path"
        break
    fi
done

if [ -z "$KEYTOOL" ]; then
    echo "❌ Could not find Android Studio's keytool"
    echo ""
    echo "Please run this in Android Studio's Terminal:"
    echo "1. In Android Studio, open Terminal (View → Tool Windows → Terminal)"
    echo "2. Run: cd android && ./gradlew signingReport"
    echo "3. Look for SHA1 in the output"
    exit 1
fi

# Get SHA-1 from debug keystore
if [ -f ~/.android/debug.keystore ]; then
    echo ""
    echo "=== SHA-1 Fingerprint (COPY THIS) ==="
    $KEYTOOL -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android 2>&1 | grep "SHA1:" | sed 's/.*SHA1: *//'
    echo ""
    echo "=== SHA-256 Fingerprint (optional) ==="
    $KEYTOOL -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android 2>&1 | grep "SHA256:" | sed 's/.*SHA256: *//'
    echo ""
    echo "📋 Next Steps:"
    echo "1. Copy the SHA-1 fingerprint above"
    echo "2. Go to: https://console.firebase.google.com/project/tapmap-7b2f2/settings/general"
    echo "3. Scroll to 'Your apps' → Android app (com.dbasi.tapmap)"
    echo "4. Click 'Add fingerprint' and paste: DF:37:BB:19:90:27:09:13:70:EA:FE:BC:E5:00:55:24:D0:9E:2C:7E"
    echo "5. Click 'Save'"
    echo "6. Download the updated google-services.json"
    echo "7. Replace: tapmap_app/android/app/google-services.json"
    echo "8. Rebuild: flutter clean && flutter build apk --release"
else
    echo "❌ Debug keystore not found at ~/.android/debug.keystore"
    exit 1
fi

