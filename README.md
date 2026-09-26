# CVNova 🚀

**CVNova** is a modern, offline-first resume builder and deterministic ATS resume checker built with Flutter.

No Docker, no complex servers, and no external dependencies required — CVNova runs completely self-contained directly on your device (Android, iOS, Web, Windows, macOS, Linux).

---

## ✨ Features

- **📄 Dynamic Resume Builder**: Create, edit, duplicate, and customize professional resumes with multiple themes, colors, and typography.
- **⚡ Instant Local Persistence**: Everything saves automatically on-device using local persistent storage.
- **🎯 Built-in ATS Resume Scorer**:
  - Upload any real-world PDF resume directly.
  - Extracts text natively on-device using `syncfusion_flutter_pdf`.
  - Analyzes formatting, section coverage, action verbs, quantified accomplishments, and keyword matching.
  - Computes actionable feedback: strengths, weaknesses, and improvement suggestions.
- **🎨 Modern Glassmorphic UI**: Beautiful dark/light mode, smooth animations, and responsive cards.
- **🔒 100% Private & Offline**: Resumes and analyses never leave your device.

---

## 📱 Running the App

### Requirements
- Flutter SDK `>=3.19.0`
- Any target device (Physical Android phone, Emulator, Chrome, or Windows Desktop)

### Launch on Connected Device
```bash
# Get dependencies
flutter pub get

# Run on your connected device (e.g. Realme RMX3851 or Chrome)
flutter run
```

### Run Tests
```bash
flutter test
```
