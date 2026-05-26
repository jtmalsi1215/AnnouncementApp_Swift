# ACADvisory Swift/Xcode Conversion

This folder contains a SwiftUI conversion of the uploaded Flutter announcement app.

## What was converted

The Swift version keeps the same app flow and Firestore structure:

- Firebase Authentication login and sign up
- Firestore `users` collection
- Firestore `announcements` collection
- Dashboard with user header, search, featured announcement, category filters, and recent updates
- Calendar/detail announcement screen with date selector, swipable announcement cards, and recent updates
- New announcement publishing page
- Profile page, edit profile page, logout, and base64 profile photo saving
- Same category names: `Academics`, `Events`, `Urgent`, `Organization`, `Campus Updates`

## Important Firebase note

Your uploaded Flutter project is connected to this Firebase project:

- Project ID: `announcement-test-d8873`
- Firestore collections used: `users`, `announcements`

However, the uploaded Flutter Firebase config only has Web and Android settings. For a real native Swift/Xcode app, you must add an iOS app inside the same Firebase project and download the iOS `GoogleService-Info.plist`.

Without `GoogleService-Info.plist`, Firebase will not start in Xcode.

## Xcode setup steps

1. Open Xcode.
2. Click **Create New Project**.
3. Choose **iOS > App**.
4. Use these settings:
   - Product Name: `Acadvisory`
   - Interface: `SwiftUI`
   - Language: `Swift`
   - Storage: `None`
   - Minimum iOS Deployment Target: `iOS 16.0` or newer
5. Create the project.
6. In Xcode, delete the default Swift files if Xcode created `ContentView.swift` and `[ProjectName]App.swift`.
7. Drag all `.swift` files from `SwiftFiles/Acadvisory/` into your Xcode project navigator.
8. When Xcode asks, check:
   - **Copy items if needed**
   - Your app target under **Add to targets**
9. Go to your Firebase Console.
10. Open the same Firebase project: `announcement-test-d8873`.
11. Click **Add app** and choose **iOS**.
12. In Xcode, click your project > target > **Signing & Capabilities** and copy your **Bundle Identifier**.
13. Paste that Bundle Identifier into Firebase while registering the iOS app.
14. Download `GoogleService-Info.plist`.
15. Drag `GoogleService-Info.plist` into the root of your Xcode project navigator.
16. Make sure **Copy items if needed** and your app target are checked.
17. In Xcode, go to **File > Add Package Dependencies**.
18. Add this package URL:

```text
https://github.com/firebase/firebase-ios-sdk.git
```

19. Select these Firebase products:
   - `FirebaseAuth`
   - `FirebaseFirestore`
20. Click **Add Package**.
21. In Firebase Console > Authentication > Sign-in method, make sure **Email/Password** is enabled.
22. In Firebase Console > Firestore Database, make sure your database exists.
23. Click the simulator selector in Xcode, choose an iPhone simulator, then press **Run**.

## Firestore fields used

### `users/{uid}`

```text
uid: String
firstName: String
lastName: String
username: String
email: String
role: String, default Student
photoUrl: String
photoBase64: String
createdAt: server timestamp
updatedAt: server timestamp
```

### `announcements/{autoId}`

```text
title: String
details: String
category: String
createdAt: server timestamp
```

## Temporary Firestore rules for testing only

Use your own secure rules before real deployment. This development version lets signed-in users read announcements/users and write announcements/users.

```text
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /announcements/{announcementId} {
      allow read, create: if request.auth != null;
      allow update, delete: if false;
    }

    match /users/{userId} {
      allow read: if request.auth != null;
      allow create, update: if request.auth != null && request.auth.uid == userId;
      allow delete: if false;
    }
  }
}
```

## Notes

- This conversion uses SwiftUI, not Storyboard.
- The profile photo is saved as compressed base64 text in Firestore, matching the uploaded Flutter behavior.
- Firebase Storage is not required for this converted version.
- The app uses the same Firestore collection names, so it will read the same database records after your iOS app is registered in the same Firebase project.
