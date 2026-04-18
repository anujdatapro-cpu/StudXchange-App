# Firebase Setup Guide for StudXchange

## ✅ Already Configured
- Android: `google-services.json` exists ✅
- Flutter dependencies: Added ✅
- Firebase initialization: Fixed ✅

## 📱 To Run on iOS (Optional)
If you want to run on iOS, add `GoogleService-Info.plist` to:
```
ios/Runner/GoogleService-Info.plist
```

## 🔧 Firebase Rules
Set these Firestore rules in Firebase Console:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /items/{itemId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow delete: if request.auth != null && 
        resource.data.ownerEmail == request.auth.token.email;
      allow update: if false; // No updates needed
    }
  }
}
```

## 🚀 Run the App
```bash
flutter run
```

## 📋 Features Working
- ✅ Email/Password Authentication
- ✅ User Registration/Login
- ✅ Add Electronics Items
- ✅ View All Items (Live from Firestore)
- ✅ Delete Own Items
- ✅ Search/Filter Items
- ✅ Logout
- ✅ Persistent Auth State
