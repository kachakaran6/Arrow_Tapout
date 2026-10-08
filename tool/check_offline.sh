#!/usr/bin/env bash
set -e

echo "=== Running Offline Audit ==="

# Check banned dependencies in pubspec.yaml
BANNED_PACKAGES=("http:" "dio:" "firebase" "google_fonts:" "google_mobile_ads:" "analytics" "sentry" "amplitude")
for pkg in "${BANNED_PACKAGES[@]}"; do
  if grep -E "^[ ]*${pkg}" pubspec.yaml > /dev/null; then
    echo "ERROR: Banned package '$pkg' found in pubspec.yaml!"
    exit 1
  fi
done

# Check manifest for INTERNET permission
if grep -i "android.permission.INTERNET" android/app/src/main/AndroidManifest.xml > /dev/null; then
  echo "ERROR: android.permission.INTERNET found in AndroidManifest.xml!"
  exit 1
fi

echo "Offline audit passed: Zero network dependencies and zero internet permissions."
