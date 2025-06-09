
# 🐾 PawTrack

## 📌 About the App
**PawTrack** is a smart and intuitive Flutter-based mobile application that helps pet owners monitor their pets’ **health** and **location** in real time. Designed with convenience in mind, PawTrack offers **user authentication**, **multiple pet profiles**, and **customizable themes** to make tracking your furry friend's well-being simple and effective.

Stay connected with your pet — wherever they go. 🐶🐱

---

## ✨ Features

✅ **Pet Health Tracking** – Monitor key health metrics for each pet.  
✅ **Real-Time Location Tracking** – Live GPS tracking powered by Firebase.  
✅ **User Authentication** – Secure login and sign-up using Firebase Authentication.  
✅ **Multiple Pet Profiles** – Manage and track multiple pets from a single account.  
✅ **Customizable Themes** – Switch between dark and light themes for a personalized look.  

---

## 🛠 Installation & Setup

### 🚀 Try It in the Browser!
No need to install anything! You can preview PawTrack instantly in your browser: **[Click here to run the app](https://appetize.io/app/b_ymuv4olqbpmqmgeu4qiooz2dn4)**   

The app will open in an emulator. Use the on-screen buttons to navigate through the Welcome and Login Screens.

---

## 🎬 **[Click here to watch our official video](https://youtu.be/sShe-rrTRvE?si=3ha1o87FQK80g3EU)**

---

## 🖼 UI Screenshots

| Home Page | Add Pet | Profile Page |
|-----------|---------|---------------|
| ![Home](https://github.com/FabioKoshy/PawTrack/blob/stabledemo/screenshots/Home%20Page.png) | ![Add Pet](https://github.com/FabioKoshy/PawTrack/blob/stabledemo/screenshots/Add%20Pet%20Details%20page.png) | ![Profile](https://github.com/FabioKoshy/PawTrack/blob/stabledemo/screenshots/Manage%20Pet%20Profile.png) |

| Heart Rate  | Battery Settings | Theme Toggle |
|-------------------|------------------|--------------|
| ![Heart Rate](https://github.com/FabioKoshy/PawTrack/blob/stabledemo/screenshots/Heart%20rate.png) | ![Battery](https://github.com/FabioKoshy/PawTrack/blob/stabledemo/screenshots/Battery%20Settings.png) | ![Theme](https://github.com/FabioKoshy/PawTrack/blob/stabledemo/screenshots/Settings%20page%20for%20themes.png) |

| Heart Rate Threshold | Location & Geofence |
|----------------------|---------------------|
| ![Threshold](https://github.com/FabioKoshy/PawTrack/blob/stabledemo/screenshots/Heart%20rate%20Threshold.png) | ![Location](https://github.com/FabioKoshy/PawTrack/blob/stabledemo/screenshots/location%20tracking%20and%20geofence.png) | 

| Hardware | Pet Wearing it |
|----------|----------------|
| ![Hardware](https://github.com/FabioKoshy/PawTrack/blob/stabledemo/screenshots/Hardware%20Components.png) | ![Harness attached to pet](https://github.com/FabioKoshy/PawTrack/blob/stabledemo/screenshots/Harness%20with%20device%20attached.png) |

---

### 🔧 Prerequisites
Make sure you have the following installed:

- ✅ Flutter SDK (`>=3.27.0`)
- ✅ Dart SDK (`>=3.0.0 <4.0.0`)
- ✅ Android Studio or VS Code (with Flutter & Dart plugins)
- ✅ A configured Firebase project

---

### ⚙️ Setup Steps

#### 1️⃣ Clone the Repository
```bash
git clone <repository-url>
cd pawtrack
```

#### 2️⃣ Install Dependencies
```bash
flutter pub get
```

#### 3️⃣ Set Up Environment Variables

PawTrack uses a `.env` file to securely load Firebase configuration data.

- **Request the `.env` file** from a team member (via secure means like email or encrypted storage).
- Place it in the root of the project directory.
- Example structure:

```
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_APP_ID=your_app_id
FIREBASE_API_KEY=your_api_key
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_STORAGE_BUCKET=your_bucket_url
```

⚠️ *Do NOT commit `.env` to GitHub. It's already listed in `.gitignore`.*

#### 4️⃣ Run the App
```bash
flutter run
```

- On first launch, you'll be greeted with the **Welcome Page**.
- After login or sign-up, the **Home Page** will guide you through pet management.

---

## 📁 Project Structure

```
pawtrack/
│
├── android/               # Android-specific files
├── ios/                   # iOS-specific files
├── lib/                   
│   ├── auth/              # Firebase auth logic
│   ├── components/        # Reusable UI widgets
│   ├── pages/             # Screens (Home, Welcome, Profile, etc.)
│   ├── services/          # Firebase and app logic
│   ├── theme/             # Light/Dark mode settings
│   ├── utils/             # Helpers and constants
│   └── main.dart          # Entry point
├── assets/                
│   ├── images/            # App icons and logos
│   └── .env               # Environment variables (ignored by Git)
├── pubspec.yaml           # Dependencies
└── README.md              # Project documentation
```

---

## 🔐 Firebase Configuration

- Firebase integration is **manually handled** via environment variables.
- **Do not include** the following sensitive files:
  - `google-services.json`
  - `GoogleService-Info.plist`
  - `firebase_options.dart`
  - `firebase.json`

🛠 For Firebase changes, contact the project admin for an updated `.env` file.

---

## 🧪 Troubleshooting

💥 **Build Fails?**  
- Make sure `.env` exists and is correctly populated.

🔐 **Authentication Not Working?**  
- Double-check Firebase setup and that the `firebase_auth` version is compatible.

🎨 **Theme Not Switching?**  
- Ensure `ThemeProvider` is implemented and wired correctly with `Provider`.

---

## 🌱 Future Enhancements

🚧 The following features are planned for future development:

- 📍 **Live GPS Mapping**
- 🩺 **Pet Health Logbook** (vet visits, vaccinations)
- 🔔 **Push Notifications** for alerts (e.g., escaped pet, health warning)
- 🧠 **Behavior Analytics**

---

## 🤝 Contributing

We welcome contributions! To get started:

1. **Fork** the repository  
2. **Create a branch**:
```bash
git checkout -b feature/my-feature
```
3. **Commit** your changes:
```bash
git commit -m "Describe the feature"
```
4. **Push** and open a Pull Request:
```bash
git push origin feature/my-feature
```

✅ Please describe your changes clearly in the PR!

---

## 📝 License
This project is licensed under the **MIT License**. See the `LICENSE` file for details.

---

## 📬 Contact
Have questions or suggestions? Reach out via **GitHub Issues**, or email the project maintainer.

🚀 **Track smarter. Care better. With PawTrack.** 🐾
