# 💰 FinTrack — Personal Budget Tracking & Expense Analytics Dashboard


---

## 📱 About

FinTrack is a mobile-first Flutter application that helps users track income and expenses, categorize transactions, and visualize spending patterns through an interactive analytics dashboard.

---

## 🎯 Features

- 🔐 **User Authentication** — Register, Login, Email Verification, Forgot Password
- ➕ **Add Transactions** — Income & Expense with categories
- 📊 **Dashboard** — Real-time KPI cards (Income, Expense, Savings)
- 🥧 **Pie Chart** — Expense breakdown by category
- 📈 **Bar Chart** — Income vs Expense comparison
- 📋 **Reports** — Full transaction history with monthly filter
- 🗑️ **Delete Transactions** — Swipe or tap to delete
- ☁️ **Firebase Firestore** — Real-time cloud database
- 📧 **Email Verification** — Secure account creation

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter 3.13.9 |
| Authentication | Firebase Auth |
| Database | Firebase Firestore |
| Charts | fl_chart 0.55.0 |
| State Management | setState + StreamBuilder |
| Deployment | Google Play Store |

---

## 📁 Project Structure
||lib/
|├── main.dart              # All screens and widgets
|└── firebase_config.dart   # Firebase configuration
---

## 🚀 Getting Started

### Prerequisites
- Flutter 3.13.9
- Firebase account
- Android Studio (for APK build)

### Installation

```bash
# Clone the repo
git clone https://github.com/Sunflowers8/fintrack.git
cd fintrack

# Install dependencies
flutter pub get

# Run on Chrome
flutter run -d chrome

# Build Android APK
flutter build apk --release
```

---

## 💰 Budget

| Item | Cost |
|---|---|
| Development | $40000 |
| Firebase Spark Plan | $0 |
| Google Play Registration | $25 |
| **Total** | **$40025** |

---

## 👩‍💻 Developer

**Developed by:** Sunflowers8  
**Institution:** Presidential Graduate School (PGS), Nepal  
**Course:** CAP 490 — Capstone Project  

---

## 📸 Screenshots

> Dashboard, Add Transaction, Reports screens — coming soon

---

## 📄 License

This project is for academic purposes only.
EOF
