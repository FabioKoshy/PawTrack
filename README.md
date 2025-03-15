# PawTrack 🐾

PawTrack is a Flutter-based mobile application designed to help pet owners track their pets' health and location. With PawTrack, you can monitor your pet's adventures, manage their well-being, and stay connected with them wherever they go. The app features user authentication, customizable themes, and a user-friendly interface to ensure a seamless experience for pet owners.

## Features

- **Pet Health Tracking**: Monitor your pet's health metrics (coming soon)
- **Location Tracking**: Track your pet's location in real-time (coming soon)
- **User Authentication**: Secure login and registration using Firebase Authentication
- **Customizable Themes**: Switch between dark and light themes for a personalized experience

## Tech Stack

- **Flutter**: Frontend framework for building cross-platform mobile apps
- **Dart**: Programming language used with Flutter
- **Firebase**: Backend services for authentication and (future) data storage
- **Provider**: State management for theme toggling and app state
- **flutter_dotenv**: Secure management of sensitive configuration data
- **Shared Preferences**: Persistent storage for user settings (e.g., welcome page status, login credentials)

## Prerequisites

Before setting up the project, ensure you have the following installed:

- Flutter SDK (version >= 3.27.0, Dart >= 3.0.0 < 4.0.0)
- Android Studio or Visual Studio Code with Flutter and Dart plugins
- A Firebase project 


## Setup Instructions

### 1. Clone the Repository

Clone the PawTrack repository to your local machine:

```bash
git clone <repository-url>
cd pawtrack
```

### 2. Install Dependencies

Install the required Flutter dependencies:

```bash
flutter pub get
```

### 3. Set Up Environment Variables

PawTrack uses environment variables to manage sensitive Firebase configuration data. You'll need a `.env` file with the necessary Firebase credentials.

1. **Obtain the `.env` File**: Contact a team member or project admin to get the `.env` file securely (via an encrypted channel, e.g., email, secure file-sharing service, or secret management tool).

2. **Place the `.env` File**: Copy the `.env` file to the root of the project directory.

3. **Example `.env` File**: The `.env` file should contain the following Firebase configuration variables (values below are examples; replace them with the actual values provided by your team):

```
FIREBASE_PROJECT_ID=<FIREBASE_PROJECT_ID goes here>
FIREBASE_APP_ID=1:<FIREBASE_APP_ID=1 goes here>
FIREBASE_API_KEY=<FIREBASE_API_KEY goes here>
FIREBASE_MESSAGING_SENDER_ID=<FIREBASE_MESSAGING_SENDER_ID goes here>
FIREBASE_STORAGE_BUCKET=<FIREBASE_STORAGE_BUCKET goes here>
```

**Important**: Do not commit the `.env` file to the repository. It's already ignored in `.gitignore`.

### 4. Run the App

Launch the app on an emulator or physical device:

```bash
flutter run
```

- **First Launch**: You'll see the WelcomePage, where you can toggle between dark and light themes.
- **Subsequent Launches**: After logging in or registering, you'll be directed to the HomePage, where pet tracking features will be available (in development).

## Project Structure

Here's an overview of the project's directory structure:

```
pawtrack/
│
├── android/               # Android-specific configuration
├── ios/                   
├── lib/                   # Main application code
│   ├── auth/              # Authentication-related logic
│   ├── components/        # Reusable UI components 
│   ├── pages/             # Main app screens
│   ├── services/          # Backend services 
│   ├── theme/             # Theme definitions 
│   ├── utils/             # Utility functions and constants
│   └── main.dart          # App entry point
├── assets/                # Static assets 
│   ├── images/            # App logos 
│   └── .env               # Environment variables 
├── pubspec.yaml           # Project dependencies and metadata
└── README.md              # Project documentation 
```

## Firebase Configuration

PawTrack uses Firebase for authentication and backend services. Firebase is initialized manually using environment variables to ensure sensitive data is not hardcoded in the codebase.

- **Sensitive Files Removed**: The following files are not used in the repository and should not be present:
    - `android/app/google-services.json` 
    - `ios/Runner/GoogleService-Info.plist` 
    - `lib/firebase_options.dart` 
    - `firebase.json` 

- **Updating Firebase Config**: If you need to update Firebase configuration (e.g., add a new app, change API keys), contact the project admin to get an updated `.env` file.

## Contributing

1. Fork the repository and create a new branch for your feature or bug fix:

```bash
git checkout -b feature/your-feature-name
```

2. Make your changes and test them thoroughly.

3. Commit your changes with a descriptive commit message:

```bash
git commit -m "Add your commit message here"
```

4. Push your branch to the repository:

```bash
git push origin feature/your-feature-name
```

5. Create a pull request and describe your changes in detail.

## Troubleshooting

- **Build Fails Due to Missing `.env` File**:
    - Ensure the `.env` file is in the project root and contains the correct Firebase configuration.

- **Firebase Authentication Not Working**:
    - Verify that the Firebase project (pawtrack-1) is correctly set up in the Firebase console and that Authentication is enabled.
    - Check that the `.env` file values match your Firebase project settings.
    - Ensure `firebase_auth` version (4.17.0) is compatible with your Flutter version.

- **Theme Not Switching**:
    - Ensure the `provider` package is correctly set up and that `ThemeProvider` is being used in `main.dart`.

## Future Enhancements

- **Real-Time Location Tracking**: Integrate GPS and mapping services to track pets in real-time.
- **Health Metrics**: Add features to log and monitor pet health data (e.g., vaccinations, vet visits).
- **Push Notifications**: Implement Firebase Cloud Messaging for alerts and reminders.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
