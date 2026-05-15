# 🚀 Expensia Flutter - Quick Start Guide

## ⚡ Get Running in 5 Minutes

### Step 1: Install Flutter (if not installed)
```bash
# Check if Flutter is installed
flutter --version

# If not installed, download from:
# https://flutter.dev/docs/get-started/install
```

### Step 2: Clone and Setup
```bash
# Navigate to project
cd expensia_app

# Get dependencies
flutter pub get
```

### Step 3: Configure Backend URLs
Open `lib/core/config/app_config.dart` and update:

```dart
// For local development (replace with your IP)
static const String baseUrl = 'http://192.168.1.100:8080/api';
static const String aiServiceUrl = 'http://192.168.1.100:8000/api';
```

**How to find your IP:**
- Windows: `ipconfig` (look for IPv4)
- Mac/Linux: `ifconfig` (look for inet)

### Step 4: Run the App
```bash
# Connect your device or start emulator
flutter devices

# Run the app
flutter run
```

---

## 📱 What You'll See

### 1. Login Screen
- Email and password fields
- Register link at bottom
- Try registering a new account

### 2. Home Screen (Dashboard)
- Welcome message
- Total expenses card
- Quick action buttons:
  - Add Expense
  - Voice Expense
  - Budgets
  - Goals
  - Reports
  - All Expenses

### 3. Current Status
✅ **Working:**
- Login/Register
- Authentication
- Home dashboard
- Navigation between screens

🚧 **To Be Implemented:**
- Expense list with real data
- Add expense form
- Voice recording
- Budget management
- Goals tracking
- Reports and charts

---

## 🧪 Test the App

### Test Authentication
1. Click "Register"
2. Fill in:
   - Name: Test User
   - Email: test@example.com
   - Password: password123
3. Click "Register"
4. Should navigate to home screen

### Test Navigation
1. Click each quick action button
2. Should navigate to placeholder screens
3. Use back button to return

---

## 🔧 Common Setup Issues

### Issue: "Flutter not found"
```bash
# Add Flutter to PATH
export PATH="$PATH:`pwd`/flutter/bin"
```

### Issue: "No devices found"
```bash
# Start Android emulator
flutter emulators
flutter emulators --launch <emulator_id>

# Or connect physical device with USB debugging enabled
```

### Issue: "Gradle build failed"
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

### Issue: "Cannot connect to backend"
- Make sure Spring Boot backend is running on port 8080
- Make sure FastAPI is running on port 8000
- Check firewall settings
- Use correct IP address (not localhost)

---

## 📝 Next Steps for Development

### Priority 1: Expense List Screen
File: `lib/presentation/screens/expenses/expense_list_screen.dart`

Replace placeholder with:
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/expense/expense_card.dart';
import '../../widgets/common/loading_indicator.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().loadExpenses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const LoadingIndicator(message: 'Loading expenses...');
          }

          if (provider.expenses.isEmpty) {
            return const Center(
              child: Text('No expenses yet. Add your first expense!'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadExpenses(),
            child: ListView.builder(
              itemCount: provider.expenses.length,
              itemBuilder: (context, index) {
                return ExpenseCard(
                  expense: provider.expenses[index],
                  onTap: () {
                    // TODO: Navigate to expense details
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/expenses/add');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

### Priority 2: Add Expense Screen
File: `lib/presentation/screens/expenses/add_expense_screen.dart`

Implement form with:
- Amount field (number)
- Category dropdown
- Date picker
- Description field
- Submit button

### Priority 3: Voice Expense
File: `lib/presentation/screens/expenses/voice_expense_screen.dart`

Implement:
- Microphone permission request
- Record button with animation
- Stop recording
- Upload to backend
- Show transcription

---

## 📚 Useful Commands

```bash
# Run app
flutter run

# Run with hot reload
flutter run --hot

# Build APK
flutter build apk

# Build for iOS
flutter build ios

# Run tests
flutter test

# Check for issues
flutter doctor

# Clean build
flutter clean

# Update dependencies
flutter pub upgrade

# Format code
flutter format lib/

# Analyze code
flutter analyze
```

---

## 🎯 Development Workflow

1. **Make changes** to code
2. **Save file** (hot reload happens automatically)
3. **Test** on device/emulator
4. **Commit** to git
5. **Repeat**

### Hot Reload Tips
- Press `r` in terminal for hot reload
- Press `R` for hot restart
- Press `q` to quit

---

## 📞 Need Help?

1. Check `README.md` for detailed documentation
2. Check `IMPLEMENTATION_GUIDE.md` for implementation details
3. Check Flutter documentation: https://flutter.dev/docs
4. Ask team members

---

## ✅ Verification Checklist

Before starting development, verify:
- [ ] Flutter installed and working
- [ ] Dependencies installed (`flutter pub get`)
- [ ] Backend URLs configured
- [ ] App runs successfully
- [ ] Can register and login
- [ ] Can navigate between screens
- [ ] No errors in console

---

## 🎉 You're Ready!

The Flutter project structure is complete and ready for development. Start implementing the screens one by one, test frequently, and refer to the implementation guide for detailed instructions.

**Happy Coding! 🚀**
