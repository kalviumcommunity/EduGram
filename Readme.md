# EduGram App

A Flutter-based mobile application for rural coaching centers to manage attendance, marks, and student performance with offline-first capabilities.

## Features

- 📱 Phone OTP Authentication
- 👥 Student Management
- ✅ Attendance Tracking
- 📊 Marks Entry
- 📈 Performance Reports
- 🔄 Offline-First Sync
- 📲 Parent Notifications

## Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Android Studio / VS Code
- Android device or emulator

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd EduGram
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── theme/                    # Design system
│   ├── app_colors.dart
│   ├── app_text_styles.dart
│   ├── app_dimensions.dart
│   └── app_theme.dart
├── screens/                  # UI screens
│   └── auth/
│       └── login_screen.dart
└── widgets/                  # Reusable components
```

## Design System

- **Colors**: Green primary theme (education/growth)
- **Typography**: Large, readable fonts (18-28px)
- **Touch Targets**: Minimum 56dp for rural users
- **Offline Indicator**: Shows sync status

## Development

This is the frontend implementation. Backend team handles:
- Firebase setup
- Authentication logic
- Database operations
- Offline sync mechanism

## License

Copyright © 2026 Rural Coach
