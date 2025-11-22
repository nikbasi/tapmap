#!/bin/bash
# Script to get SHA-1 and SHA-256 fingerprints for Firebase configuration

echo "🔍 Getting SHA-1 and SHA-256 fingerprints for Firebase..."
echo ""

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ANDROID_DIR="$SCRIPT_DIR/android"

# Method 1: Try using Android Studio's bundled Java
JAVA_CMD=""
JAVA_PATHS=(
    "$HOME/Library/Android/sdk/jre/bin/keytool"
    "$HOME/Library/Android/sdk/jbr/bin/keytool"
    "/Applications/Android Studio.app/Contents/jre/Contents/Home/bin/keytool"
    "/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool"
)

for path in "${JAVA_PATHS[@]}"; do
    if [ -f "$path" ]; then
        JAVA_CMD="$path"
        break
    fi
done

# Method 2: Try system keytool
if [ -z "$JAVA_CMD" ] && command -v keytool &> /dev/null; then
    JAVA_CMD="keytool"
fi

# Try to get from debug keystore
if [ -n "$JAVA_CMD" ] && [ -f ~/.android/debug.keystore ]; then
    echo "=== Method 1: Debug Keystore Fingerprints ==="
    if $JAVA_CMD -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android 2>/dev/null | grep -E "SHA1:|SHA256:" | sed 's/^[[:space:]]*/  /'; then
        echo ""
    fi
fi

# Method 3: Try Gradle (requires Java to be set up)
if [ -f "$ANDROID_DIR/gradlew" ]; then
    echo "=== Method 2: Gradle Signing Report ==="
    cd "$ANDROID_DIR"
    chmod +x gradlew 2>/dev/null
    if ./gradlew signingReport 2>&1 | grep -A 5 -E "Variant:|SHA1:|SHA256:" | head -30; then
        echo ""
    fi
    cd "$SCRIPT_DIR"
fi

# If nothing worked, provide manual instructions
if [ -z "$JAVA_CMD" ]; then
    echo ""
    echo "⚠️  Java/keytool not found automatically."
    echo ""
    echo "📝 Manual Method - Get SHA-1 using Android Studio:"
    echo "1. Open Android Studio"
    echo "2. Open this project: $SCRIPT_DIR"
    echo "3. Click on 'Gradle' tab (right side)"
    echo "4. Navigate to: tapmap_app > android > Tasks > android > signingReport"
    echo "5. Double-click 'signingReport'"
    echo "6. Look for SHA1 in the output (usually under 'Variant: debug')"
    echo ""
    echo "OR use Android Studio Terminal:"
    echo "  cd $ANDROID_DIR"
    echo "  ./gradlew signingReport"
    echo ""
fi

echo "📋 Next Steps (after getting SHA-1):"
echo "1. Copy the SHA-1 fingerprint (format: XX:XX:XX:XX:...) from above"
echo "2. Go to: https://console.firebase.google.com/project/tapmap-7b2f2/settings/general"
echo "3. Scroll to 'Your apps' section"
echo "4. Click on your Android app (package: com.dbasi.tapmap)"
echo "5. Click 'Add fingerprint' button"
echo "6. Paste your SHA-1 fingerprint"
echo "7. Click 'Save'"
echo "8. Download the updated google-services.json"
echo "9. Replace: $SCRIPT_DIR/android/app/google-services.json"
echo "10. Rebuild: cd $SCRIPT_DIR && flutter clean && flutter build apk --release"
echo ""

