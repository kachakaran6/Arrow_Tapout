#!/usr/bin/env bash
set -e

echo "1. Formatting check..."
dart format --output=none --set-exit-if-changed .

echo "2. Flutter analyze..."
flutter analyze

echo "3. Flutter test..."
flutter test

echo "4. Offline check..."
bash tool/check_offline.sh

echo "All checks passed successfully!"
