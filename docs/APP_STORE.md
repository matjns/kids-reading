# Putting Reading Quest on the Mac App Store

The GitHub download is an unsigned app for use at home. The App Store needs a signed archive from Xcode. The pieces below are already in this folder so that archive can be a normal Mac app.

Already included:

- Bundle id `com.kidscomputer.reading`
- Version 1.0.0, build 1 (`VERSION` and `Packaging/Info.plist`)
- App icon images in `Packaging/AppIcon.iconset`
- Sandbox entitlements in `Packaging/ReadingQuest.entitlements` (no network, no special files)
- Privacy manifest `Packaging/PrivacyInfo.xcprivacy` (no tracking, no collected data)
- `ITSAppUsesNonExemptEncryption` set to false, so export questions stay simple
- Category: Education
- Lowest system: macOS 14
- No private Apple APIs, no ads, no accounts, no analytics

The app does not collect data. An optional name and the stars stay in a file on the Mac. For the App Store privacy label, choose **Data Not Collected**.

## Steps still left

1. Join the Apple Developer Program and sign in with Xcode.
2. In Certificates, Identifiers & Profiles, register the App ID `com.kidscomputer.reading`.
3. Create a new macOS App project in Xcode. Name it Reading Quest. Interface: SwiftUI. Language: Swift. Leave the bundle id as `com.kidscomputer.reading`.
4. Delete the template `ContentView` file. Add the Swift files from `App/` and `Sources/ReadingCore/` to the app target. Do not add the test folder to the app target.
5. Add `Sources/ReadingCore/Passages` as a folder of resources so the JSON files are copied into the app.
6. Add `Packaging/PrivacyInfo.xcprivacy` to the app target.
7. Drag the icon PNGs into `Assets.xcassets` as an App Icon, or point the target at `Packaging/AppIcon.iconset`.
8. Set the deployment target to macOS 14.0. Set Marketing Version to 1.0.0 and Build to 1.
9. In Signing & Capabilities, turn on App Sandbox. Do not add network, camera, microphone, or file entitlements. You can use `Packaging/ReadingQuest.entitlements` as the entitlements file.
10. For a release archive, build for Any Mac (Apple silicon and Intel), with "Build Active Architecture Only" turned off.
11. Product, Archive, then Distribute App, App Store Connect.
12. In App Store Connect, set the age rating to 4+, the category to Education, and the privacy nutrition label to Data Not Collected.
13. Add a support URL. The public GitHub page for this project is enough.
14. Take screenshots on a Mac at the sizes App Store Connect asks for (often 1280 x 800 and 2560 x 1600, and the larger Retina sizes if it asks). Leave the name field blank. Do not include a child's name or photo.

Home installs do not need these steps. Use `./build.sh` and the notes in `README-mac.txt`.
