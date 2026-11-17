# Free Fire ID Manager

A professional **Free Fire ID Sale Management** Android application built with Flutter.

## Features

- 🎮 **FF ID Management** — Add, edit, delete IDs with images
- 👥 **Seller & Buyer Management** — Full profiles with balance tracking
- 💰 **Sales System** — Complete sale workflow with profit calculation
- 💳 **Money Transactions** — Partial payments, payment history
- 📊 **DEO Management** — DEO accounts with payment proofs
- 📱 **WhatsApp Integration** — Auto-generated payment messages
- 📈 **Reports** — PDF & Excel export with date filters
- 🔒 **SQLite Database** — All data saved locally, persists after restart
- 🌙 **Dark Gaming Theme** — Premium neon green/blue UI

## Screenshots

> Coming soon

## Download APK

👉 Go to [**Releases**](../../releases) and download the latest `app-release.apk`

## Build from Source

### Prerequisites
- Flutter 3.24+
- Android SDK
- Java 17

### Steps
```bash
git clone https://github.com/YOUR_USERNAME/ff_id_manager.git
cd ff_id_manager
flutter pub get
flutter build apk --release
```

APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

## Auto-Build with GitHub Actions

This project uses GitHub Actions to automatically build the APK on every push.

1. Push code to `main` branch
2. Go to **Actions** tab → watch the build
3. Download APK from **Artifacts** or **Releases**

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Framework | Flutter 3.x (Dart) |
| Database | SQLite (sqflite) |
| State Management | Provider |
| Charts | fl_chart |
| PDF Export | pdf + printing |
| Excel Export | excel |
| Images | image_picker |
| Theme | Google Fonts (Orbitron, Rajdhani) |

## Database Schema

- `ff_ids` — Free Fire ID records
- `sellers` — Seller profiles
- `buyers` — Buyer profiles  
- `sales` — Sale transactions
- `transactions` — Money transactions
- `deo_accounts` — DEO accounts
- `deo_payments` — DEO payment history
- `id_images` — ID screenshots

## License

MIT License — Free to use and modify.
