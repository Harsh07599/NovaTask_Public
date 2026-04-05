# 📱 NovaTask - Premium Task & Alarm Management App

NovaTask is a production-ready Flutter application that combines intelligent task management with powerful alarm notifications and cloud synchronization. Designed for reliability with offline-first architecture, beautiful AMOLED-optimized UI, and seamless Firebase integration.

## 🎯 Project Overview

**NovaTask** empowers users to manage tasks efficiently while ensuring important reminders never get missed. Whether you need to track daily tasks, set up recurring routines, or manage urgent alarms, NovaTask delivers with a sleek "True Black" AMOLED theme, intelligent offline capabilities, and automatic cloud backup.

### Problem It Solves
- 📌 **Task reminders that matter**: Full-screen, persistent alarms ensure critical tasks are never ignored
- 🔄 **Seamless multi-device sync**: Cloud Firestore synchronization keeps your data consistent across devices
- 📵 **Works offline**: Complete functionality without internet; automatic sync when online
- 🎨 **Eye-friendly design**: AMOLED-optimized dark theme designed for extended use

### Target Users
- Professionals managing complex daily workflows
- Students tracking assignments and deadlines
- Anyone needing reliable alarm-based reminders for important tasks

---

## ✨ Core Features

### 📋 Task Management
- Create, edit, and delete tasks with custom descriptions
- Organize tasks into color-coded categories
- Filter and search tasks by status, priority, or category
- Mark tasks complete with one tap

### 🔔 Advanced Alarm System
- **Full-screen alarms** that activate even when app is closed or screen is off
- **Custom sounds** for different task priorities
- **Persistent notifications** that loop until manually dismissed
- **Background scheduling** using Android Alarm Manager for reliability
- **Timezone support** for accurate alarm timing across regions

### ⏰ Smart Reminders
- Configurable interval-based reminders (e.g., remind me 1 hour before)
- Local push notifications for non-urgent reminders
- Quiet hours support (coming soon)

### 🔄 Recurring Tasks & Routines
- Create **recurring tasks** (daily, weekly, monthly, yearly)
- **Routine tracking** for habits and workflows with completion analytics
- **Checklist support** for multi-step tasks and structured workflows
- Auto-generate next occurrences automatically

### 📝 Quick Notes
- Create color-coded notes for quick reference
- Synced across devices via Firestore
- Light, quick note-taking without overhead of full tasks

### ☁️ Cloud Synchronization
- **Real-time sync** with Firebase Firestore
- **Offline-first architecture**: Works perfectly without internet
- **Last-write-wins** conflict resolution for reliability
- **Anonymous authentication** for frictionless onboarding
- **Automatic background sync** when connectivity returns

### 🎨 Beautiful UI
- **AMOLED-optimized dark theme** with pure black backgrounds
- **Emerald accent colors** for visual clarity
- **Smooth animations** and intuitive navigation
- **Responsive design** for phones and tablets

---

## 🛠️ Tech Stack

| Technology | Purpose | Version |
|-----------|---------|----------|
| **Framework** | Flutter | Latest |
| **Language** | Dart | ^3.8.1 |
| **Local DB** | SQLite via sqflite | ^2.4.2 |
| **Cloud DB** | Firebase Firestore | ^5.6.9 |
| **Authentication** | Firebase Auth (Anonymous) | ^5.5.1 |
| **State Management** | Provider | ^6.1.5 |
| **Notifications** | flutter_local_notifications | ^20.1.0 |
| **Alarms** | android_alarm_manager_plus | ^5.0.0 |
| **Timezone** | flutter_timezone | ^5.0.2 |
| **UI Fonts** | google_fonts | ^6.3.2 |
| **File System** | path_provider | ^2.1.2 |

### Architecture
- **Dual-layer database**: SQLite for instant offline access + Firestore for cloud backup
- **Provider pattern**: Reactive state management with automatic UI updates
- **Service-oriented**: Clean separation of concerns (Notifications, Alarms, Sync, Auth)
- **Background processing**: Alarms continue running even when app is minimized/closed

---

## 📋 Prerequisites

Before you begin, ensure you have:

1. **Flutter SDK** (v3.19.0 or higher)
   - [Install Flutter](https://docs.flutter.dev/get-started/install)

2. **Dart SDK** (v3.8.1 or higher)
   - Included with Flutter, but verify:
     ```bash
     flutter --version
     dart --version
     ```

3. **Android Development Setup**
   - Android SDK (API level 21 or higher)
   - Android Studio or alternative IDE
   - USB debugging enabled on test device (for `flutter run`)

4. **Google Account** (for Firebase)
   - Create free Firebase account at [firebase.google.com](https://firebase.google.com)

---

## 🔥 Firebase Setup & Configuration

### Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"+ Add project"**
3. Enter project name (e.g., "NovaTask" or "My Task Manager")
4. Click **"Continue"**
5. Choose your Google analytics preferences (optional) and click **"Create project"**
6. Wait for the project to initialize, then click **"Continue"**

### Step 2: Register Your Android App & Generate google-services.json

#### 2a. Register the Android App

1. In the Firebase Console, click the **Android icon** (or **+ Add app** if project is already created)
2. Fill in the registration form:
   - **Android package name**: `com.app.task_alarm` *(Must match exactly)*
   - **App nickname**: "NovaTask" (optional but helpful)
   - **Debug signing certificate SHA-1**: (Optional - leave blank for now)
3. Click **"Register app"**

#### 2b. Download google-services.json

1. After registration, Firebase will show a download button for **google-services.json**
2. Click **"Download google-services.json"**
3. Save the file locally

#### 2c. Place google-services.json in Your Project

1. Navigate to your project directory locally:
   ```bash
   cd path/to/NovaTask
   ```

2. **Copy** the downloaded `google-services.json` to:
   ```
   android/app/google-services.json
   ```

3. **Verify placement**:
   ```bash
   # On Windows (PowerShell)
   ls android/app/google-services.json
   
   # On macOS/Linux
   ls -la android/app/google-services.json
   ```
   You should see the file listed.

4. **Important**: This file is in `.gitignore` for security. Each developer must generate their own from Firebase.

### Step 3: Enable Firebase Authentication

1. In Firebase Console, go to **Build > Authentication**
2. Click **"Get started"** (if first time)
3. Click **Sign-in method** tab
4. Find **"Anonymous"** provider
5. Click on it and toggle **"Enable"**
6. Click **"Save"**

*NovaTask uses anonymous authentication for frictionless onboarding. Users don't need accounts.*

### Step 4: Create Cloud Firestore Database

1. In Firebase Console, go to **Build > Firestore Database**
2. Click **"Create database"**
3. Choose a location closest to your users
4. Select **"Production mode"** (for added security)
5. Click **"Create"**

### Step 5: Configure Firestore Security Rules

1. In Firestore Database, go to **Rules** tab
2. Replace the default rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users (including anonymous)
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

3. Click **"Publish"**

**Security Notes**:
- `request.auth != null` ensures only authenticated users (including anonymous) can access data
- Each user can only access their own data in the app logic (uid-based filtering)
- In production, you may want stricter rules:
  ```javascript
  match /{uid}/tasks/{taskId} {
    allow read, write: if request.auth.uid == uid;
  }
  ```

---

## 🚀 Installation & Getting Started

### Clone the Repository

```bash
git clone <your-repository-url>
cd NovaTask
```

### Install Dependencies

```bash
flutter pub get
```

This will fetch all dependencies listed in `pubspec.yaml`.

### Verify Setup

```bash
# Check Flutter Doctor to ensure everything is configured
flutter doctor

# Should show:
# ✓ Flutter (Channel stable, ...)
# ✓ Android toolchain (Android SDK version ...)
# ✓ Android Studio
# ✓ VS Code
```

### Run the App

**On Physical Device**:
```bash
# Enable USB debugging on your Android device
flutter run
```

**On Emulator**:
```bash
# Start Android emulator first, then:
flutter run
```

**With Specific Device**:
```bash
flutter devices              # List available devices
flutter run -d <device-id> # Run on specific device
```

### First Launch

1. App will prompt for permissions (notifications, alarms)
2. Grant all permissions for full functionality
3. Create your first task and set an alarm
4. Data will automatically sync to Firebase (if configured)

---

## 📁 Project Structure

```
lib/
├── main.dart                          # App entry point & theme setup
├── database/
│   └── database_helper.dart           # SQLite database operations & queries
├── models/
│   ├── task.dart                      # Task data model
│   ├── category.dart                  # Category data model
│   ├── routine.dart                   # Recurring routine model
│   └── note.dart                      # Note data model
├── providers/
│   ├── task_provider.dart             # Task state management
│   ├── category_provider.dart         # Category state management
│   ├── routine_provider.dart          # Routine state management
│   ├── note_provider.dart             # Note state management
│   └── settings_provider.dart         # App settings state
├── screens/
│   ├── main_navigation_screen.dart    # Tab navigation (Home, Checklist, Notes)
│   ├── home_screen.dart               # Task list & creation
│   ├── add_edit_task_screen.dart      # Task form
│   ├── task_detail_screen.dart        # Task details & alarm
│   ├── checklist_screen.dart          # Routine & checklist view
│   ├── checklist_detail_screen.dart   # Routine details
│   ├── notes_screen.dart              # Color-coded notes
│   ├── add_edit_note_screen.dart      # Note form
│   ├── categories_screen.dart         # Category management
│   ├── routine_report_screen.dart     # Routine analytics
│   └── settings_screen.dart           # App settings
├── services/
│   ├── alarm_service.dart             # Full-screen alarm notifications
│   ├── notification_service.dart      # Local push notifications
│   ├── firebase_service.dart          # Firestore read/write operations
│   ├── sync_service.dart              # Offline-first sync engine
│   ├── recurring_service.dart         # Recurring task generation
│   └── database_helper.dart           # (Alternative location)
├── theme/
│   └── app_theme.dart                 # AMOLED dark theme & colors
└── widgets/
    ├── task_card.dart                 # Reusable task list item
    ├── filter_bar.dart                # Category/priority filter UI
    └── (other reusable widgets)
```

### Key Directories Explained

- **models/** — Data structures (Tasks, Categories, Routines, Notes)
- **providers/** — Provider classes for state management and reactive updates
- **screens/** — Full-screen UI pages and navigation
- **services/** — Business logic (alarms, notifications, Firebase, sync)
- **database/** — SQLite operations for offline storage
- **theme/** — App-wide colors, fonts, and styling

---

## 🔧 Development

### Building for Release

```bash
# Build APK for Android
flutter build apk --release

# Build App Bundle (for Google Play Store)
flutter build appbundle --release
```

### Debugging

```bash
# Enable verbose logging
flutter run -v

# Run in debug mode with breakpoints
flutter run --debug
```

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart
```

---

## 🆘 Troubleshooting

### Firebase Connection Issues
- Verify `google-services.json` is in `android/app/` (correct path)
- Check package name matches Firebase registration (`com.app.task_alarm`)
- Ensure Anonymous Authentication is enabled in Firebase Console
- Check Firestore security rules allow your user (rule example above)

### Alarms Not Triggering
- Verify notification permissions are granted on device
- Check device battery optimization settings (alarms may be throttled)
- Ensure Android version is 7.0+ (API level 21+)

### Sync Not Working
- Verify internet connectivity
- Check Firestore Database exists in Firebase
- Confirm `.env` variables are correct (if used)
- Check app logs: `flutter logs`

---

## 📄 License

This project is licensed under the **MIT License** — see [LICENSE](LICENSE) file for details.

MIT License allows free use, modification, and distribution with minimal restrictions.

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/awesome-feature`)
3. Commit your changes (`git commit -m 'Add awesome feature'`)
4. Push to branch (`git push origin feature/awesome-feature`)
5. Open a Pull Request

---

## 📧 Support

If you encounter issues or have questions:
- Check [Troubleshooting](#-troubleshooting) section above
- Review Firebase documentation: [firebase.google.com/docs](https://firebase.google.com/docs)
- Flutter documentation: [flutter.dev](https://flutter.dev)

---

**Happy task managing! 🚀**
