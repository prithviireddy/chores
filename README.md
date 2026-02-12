# FlatChore 🏠✨

A Flutter-based chore management application designed for shared living spaces (flats/apartments). Manage household chores with automatic rotation, track completion, and keep everyone accountable!

## 📱 Features

### 🔐 Authentication
- **Email/Password Sign Up & Login** - Secure user authentication via Firebase Auth
- **User Profiles** - Display names and email management

### 🏘️ Flat Management
- **Create Flats** - Set up your shared living space with a unique code
- **Join Flats** - Use a flat code to join existing households
- **Password Protection** - Optional password protection for flats
- **Leave Flat** - Exit from a flat with proper data cleanup
- **Multi-Flat Support** - Users can be members of multiple flats

### 📋 Chore Management
- **Add Chores** - Create chores with customizable settings:
  - Title
  - Frequency (Daily, Weekly, Monthly)
  - Participant selection
  - Rotation order (drag-to-reorder)
- **Automatic Rotation** - Chores automatically rotate to the next person after completion
- **Due Date Tracking** - Visual indicators for upcoming and overdue chores
- **Completion Tracking** - Mark chores as complete with timestamp and user tracking
- **Chore History** - View who completed chores and when

### 🎉 User Experience
- **Confetti Celebrations** - Fun animations when completing chores
- **Real-time Updates** - Firestore integration for instant synchronization
- **Responsive UI** - Works across multiple platforms (Android, iOS, Web, Desktop)

## 🛠️ Tech Stack

- **Framework**: Flutter (SDK ^3.10.8)
- **Backend**: Firebase
  - Firebase Core (^3.4.0)
  - Firebase Auth (^5.1.4)
  - Cloud Firestore (^5.4.4)
- **UI Libraries**:
  - Cupertino Icons (^1.0.8)
  - Confetti (^0.8.0)
- **Utilities**:
  - Intl (^0.19.0) - Date formatting

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration
├── models/                   # Data models
│   ├── user_model.dart       # User data structure
│   ├── flat_model.dart       # Flat/household data structure
│   └── chore_model.dart      # Chore data structure
├── screens/                  # UI screens
│   ├── auth/                 # Authentication screens
│   │   ├── login_screen.dart
│   │   └── signup_screen.dart
│   ├── flat/                 # Flat management screens
│   │   ├── create_flat_screen.dart
│   │   └── join_flat_screen.dart
│   ├── home/                 # Main app screens
│   │   ├── add_chore_screen.dart
│   │   └── home_screen.dart
│   └── wrapper.dart          # Auth state wrapper
├── services/                 # Business logic & Firebase operations
│   ├── auth_service.dart     # Authentication service
│   ├── flat_service.dart     # Flat management service
│   └── chore_service.dart    # Chore management service
├── utils/                    # Utilities
│   └── theme.dart            # App theme configuration
└── widgets/                  # Reusable UI components
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (^3.10.8 or higher)
- Dart SDK
- Firebase account
- IDE (VS Code, Android Studio, or IntelliJ IDEA)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd flat_chore
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Authentication (Email/Password)
   - Create a Firestore Database
   - Download and configure Firebase for your platforms:
     ```bash
     # Install FlutterFire CLI
     dart pub global activate flutterfire_cli
     
     # Configure Firebase
     flutterfire configure
     ```

4. **Firestore Security Rules**
   
   Deploy the security rules from `firestore.rules`:
   ```bash
   firebase deploy --only firestore:rules
   ```

5. **Run the app**
   ```bash
   # For development
   flutter run
   
   # For specific platform
   flutter run -d chrome      # Web
   flutter run -d android     # Android
   flutter run -d ios         # iOS
   ```

## 🗄️ Data Models

### User Model
```dart
{
  uid: String,
  email: String,
  displayName: String?,
  currentFlatId: String?,
  flatIds: List<String>,
  createdAt: DateTime
}
```

### Flat Model
```dart
{
  id: String,
  code: String,
  name: String,
  ownerId: String,
  memberIds: List<String>,
  memberCount: int,
  password: String?,
  createdAt: DateTime
}
```

### Chore Model
```dart
{
  id: String,
  title: String,
  frequency: String,
  participants: List<String>,
  rotationIndex: int,
  assignedTo: String,
  nextDueDate: DateTime,
  lastCompletedAt: DateTime?,
  lastCompletedBy: String?,
  createdAt: DateTime,
  isActive: bool
}
```

## 🔒 Security

- Firestore security rules enforce proper access control
- Users can only access flats they are members of
- Chore operations require flat membership
- Password-protected flats for additional privacy

### Firebase API Keys & Security Model

> **Important**: Firebase client-side API keys (in `lib/firebase_options.dart`) are **designed to be public** and can be safely committed to version control. They are not secret credentials.

**Security is enforced through:**
- ✅ **Firestore Security Rules** (`firestore.rules`) - Controls data access at the database level
- ✅ **Firebase Authentication** - Verifies user identity
- ✅ **App Restrictions** - Configure in Firebase Console to restrict API key usage to your app

**Protected Files (NOT in repository):**
- `android/app/google-services.json` - Platform-specific Android configuration
- `ios/Runner/GoogleService-Info.plist` - Platform-specific iOS configuration
- `.env` files - For future runtime secrets (API keys, tokens, etc.)

### Setting Up Firebase for New Developers

If you're setting up this project for the first time:

1. **Get Firebase Access**
   - Request access to the Firebase project from the team
   - OR create your own Firebase project for development

2. **Configure Firebase**
   ```bash
   # Install FlutterFire CLI
   dart pub global activate flutterfire_cli
   
   # Configure Firebase (generates firebase_options.dart and platform files)
   flutterfire configure
   ```

3. **Deploy Firestore Rules** (if using your own project)
   ```bash
   firebase deploy --only firestore:rules
   ```

4. **Enable Authentication**
   - Go to Firebase Console → Authentication
   - Enable Email/Password sign-in method


## 🎯 Usage

1. **Sign Up/Login** - Create an account or log in
2. **Create or Join a Flat** - Set up your household or join an existing one
3. **Add Chores** - Create chores and assign participants
4. **Complete Chores** - Mark chores as done and watch them rotate!
5. **Track Progress** - See who's doing what and when

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is private and not published to pub.dev.

## 🐛 Known Issues

- Refer to recent conversation logs for any ongoing bug fixes

## 📞 Support

For issues or questions, please create an issue in the repository.

---

**Built with Flutter 💙**
