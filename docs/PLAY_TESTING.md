# Google Play Testing Guide

## In-App Update Testing
1. **Internal App Sharing / Internal Testing Track**:
   - Build a base release app bundle with version `1.0.0+1`.
   - Upload to Google Play Console -> Internal testing track.
   - Install version 1 onto a test Android device via the Play Store link.
   - Build a second bundle with version `1.0.1+2` (with priority >= 4 if testing immediate update).
   - Upload version 2 to the same track.
   - Open version 1 on device; on reaching Home screen, Play Services surfaces the native update sheet.

## In-App Review Testing
1. **Milestones & Conditions**:
   - Player clears 8 levels with 2 or 3 stars.
   - When returning to Level select, after 600ms delay, `PlayReviewService` triggers `InAppReview.instance.requestReview()`.
   - Google Play determines whether to show the native review dialog based on internal user quotas.
   - In internal test tracks, the review dialog always displays and allows submitting test ratings.
