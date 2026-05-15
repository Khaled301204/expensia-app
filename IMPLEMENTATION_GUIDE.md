# Expensia Flutter Implementation Guide

## ✅ What's Been Created

### Complete Project Structure
All folders and files according to the specification have been created with proper organization.

### Core Configuration (100% Complete)
- ✅ `app_config.dart` - API endpoints and configuration
- ✅ `theme.dart` - Light and dark theme
- ✅ `api_constants.dart` - HTTP constants
- ✅ `app_constants.dart` - App-wide constants

### Utilities (100% Complete)
- ✅ `date_formatter.dart` - Date formatting utilities
- ✅ `currency_formatter.dart` - Currency formatting (EGP)
- ✅ `validators.dart` - Form validation functions

### Data Models (100% Complete)
- ✅ `user.dart` - User model with JSON serialization
- ✅ `expense.dart` - Expense model
- ✅ `income.dart` - Income model
- ✅ `budget.dart` - Budget model with calculations
- ✅ `goal.dart` - Savings goal model with progress tracking
- ✅ `notification.dart` - Notification model

### Services (100% Complete)
- ✅ `api_service.dart` - Complete HTTP client with Dio
  - GET, POST, PUT, PATCH, DELETE methods
  - File upload support
  - JWT token management
  - Error handling
  - Interceptors for auth
- ✅ `storage_service.dart` - Local storage with SharedPreferences
  - Token management
  - User data persistence
  - Theme preferences
- ✅ `voice_service.dart` - Audio recording service
  - Permission handling
  - Start/stop recording
  - File management

### Repositories (100% Complete)
- ✅ `auth_repository.dart` - Authentication operations
- ✅ `expense_repository.dart` - Expense CRUD + voice expense
- ✅ `budget_repository.dart` - Budget management
- ✅ `goal_repository.dart` - Goals management

### State Management - Providers (100% Complete)
- ✅ `auth_provider.dart` - Authentication state
- ✅ `expense_provider.dart` - Expense management state
- ✅ `budget_provider.dart` - Budget state
- ✅ `goal_provider.dart` - Goals state
- ✅ `theme_provider.dart` - Theme switching

### Screens (Partially Complete)
- ✅ `login_screen.dart` - Full implementation
- ✅ `register_screen.dart` - Full implementation
- ✅ `home_screen.dart` - Dashboard with quick actions
- 🚧 `expense_list_screen.dart` - Placeholder
- 🚧 `add_expense_screen.dart` - Placeholder
- 🚧 `voice_expense_screen.dart` - Placeholder
- 🚧 `budget_list_screen.dart` - Placeholder
- 🚧 `add_budget_screen.dart` - Placeholder
- 🚧 `goals_screen.dart` - Placeholder
- 🚧 `add_goal_screen.dart` - Placeholder
- 🚧 `reports_screen.dart` - Placeholder

### Widgets (Partially Complete)
- ✅ `custom_button.dart` - Reusable button component
- ✅ `custom_text_field.dart` - Reusable text field
- ✅ `loading_indicator.dart` - Loading widget
- ✅ `expense_card.dart` - Expense list item
- ✅ `budget_progress.dart` - Budget progress indicator
- 🚧 `expense_chart.dart` - Placeholder for charts
- 🚧 `category_pie_chart.dart` - Placeholder for pie chart

### Routing (100% Complete)
- ✅ `app_router.dart` - Complete navigation system

### Configuration Files (100% Complete)
- ✅ `pubspec.yaml` - All dependencies configured
- ✅ `main.dart` - App entry point with providers
- ✅ `app.dart` - MaterialApp configuration

---

## 🚀 How to Run

### 1. Prerequisites
```bash
# Check Flutter installation
flutter doctor

# Should show Flutter SDK installed
```

### 2. Install Dependencies
```bash
cd expensia_app
flutter pub get
```

### 3. Update API Configuration
Edit `lib/core/config/app_config.dart`:
```dart
static const String baseUrl = 'http://YOUR_IP:8080/api';
static const String aiServiceUrl = 'http://YOUR_IP:8000/api';
```

### 4. Run the App
```bash
# Run on connected device/emulator
flutter run

# Run on specific device
flutter devices
flutter run -d <device_id>

# Run in release mode
flutter run --release
```

---

## 📝 What Needs to Be Implemented

### Priority 1: Core Expense Features (Week 3-4)

#### 1. Expense List Screen
File: `lib/presentation/screens/expenses/expense_list_screen.dart`

**Tasks:**
- Display list of expenses using `ExpenseProvider`
- Add pull-to-refresh
- Implement filtering by date/category
- Add delete functionality
- Navigate to add expense screen

**Example Code:**
```dart
Consumer<ExpenseProvider>(
  builder: (context, provider, child) {
    if (provider.isLoading) {
      return LoadingIndicator();
    }
    return ListView.builder(
      itemCount: provider.expenses.length,
      itemBuilder: (context, index) {
        return ExpenseCard(
          expense: provider.expenses[index],
          onTap: () => _showExpenseDetails(provider.expenses[index]),
        );
      },
    );
  },
)
```

#### 2. Add Expense Screen
File: `lib/presentation/screens/expenses/add_expense_screen.dart`

**Tasks:**
- Create form with amount, category, date, description
- Add category dropdown
- Add payment method selection
- Implement form validation
- Call `expenseProvider.createExpense()`

**Form Fields:**
- Amount (number input)
- Category (dropdown)
- Date (date picker)
- Description (text area)
- Merchant (optional)
- Payment method (dropdown)

#### 3. Voice Expense Screen
File: `lib/presentation/screens/expenses/voice_expense_screen.dart`

**Tasks:**
- Request microphone permission
- Show recording UI with animation
- Start/stop recording using `VoiceService`
- Upload audio file to backend
- Show transcription result
- Display parsed expense data

**UI Elements:**
- Microphone button (tap to record)
- Recording indicator
- Stop button
- Transcription display
- Confirm/Edit parsed data

### Priority 2: Budget Management (Week 3-4)

#### 4. Budget List Screen
File: `lib/presentation/screens/budgets/budget_list_screen.dart`

**Tasks:**
- Display budgets using `BudgetProvider`
- Show progress bars for each budget
- Highlight over-budget items
- Add delete functionality

#### 5. Add Budget Screen
File: `lib/presentation/screens/budgets/add_budget_screen.dart`

**Tasks:**
- Category selection
- Limit amount input
- Date range picker (start/end)
- Alert threshold slider
- Save budget

### Priority 3: Goals & Reports (Week 5-6)

#### 6. Goals Screen
File: `lib/presentation/screens/goals/goals_screen.dart`

**Tasks:**
- Display goals with progress
- Show days remaining
- Add savings button
- Delete goal functionality

#### 7. Add Goal Screen
File: `lib/presentation/screens/goals/add_goal_screen.dart`

**Tasks:**
- Goal name input
- Target amount
- Deadline picker
- Save goal

#### 8. Reports Screen
File: `lib/presentation/screens/reports/reports_screen.dart`

**Tasks:**
- Monthly/yearly summary
- Category breakdown
- Expense trends chart
- Export functionality

### Priority 4: Charts Implementation (Week 5-6)

#### 9. Expense Chart
File: `lib/presentation/widgets/charts/expense_chart.dart`

**Use fl_chart package:**
```dart
import 'package:fl_chart/fl_chart.dart';

LineChart(
  LineChartData(
    // Configure chart data
  ),
)
```

#### 10. Category Pie Chart
File: `lib/presentation/widgets/charts/category_pie_chart.dart`

```dart
PieChart(
  PieChartData(
    sections: _createSections(),
  ),
)
```

---

## 🔧 Common Implementation Patterns

### 1. Loading Data in Screen
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<ExpenseProvider>().loadExpenses();
  });
}
```

### 2. Showing Errors
```dart
if (provider.error != null) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(provider.error!)),
  );
  provider.clearError();
}
```

### 3. Form Submission
```dart
Future<void> _submit() async {
  if (_formKey.currentState!.validate()) {
    final success = await provider.createExpense(...);
    if (success && mounted) {
      Navigator.pop(context);
    }
  }
}
```

### 4. Date Picker
```dart
final date = await showDatePicker(
  context: context,
  initialDate: DateTime.now(),
  firstDate: DateTime(2020),
  lastDate: DateTime(2030),
);
```

### 5. Dropdown
```dart
DropdownButtonFormField<String>(
  value: _selectedCategory,
  items: AppConstants.expenseCategories.map((category) {
    return DropdownMenuItem(
      value: category,
      child: Text(category),
    );
  }).toList(),
  onChanged: (value) {
    setState(() => _selectedCategory = value);
  },
)
```

---

## 🧪 Testing

### Unit Tests
```dart
// test/unit_test/currency_formatter_test.dart
test('formats currency correctly', () {
  expect(
    CurrencyFormatter.format(1000.50),
    'EGP 1,000.50',
  );
});
```

### Widget Tests
```dart
// test/widget_test/login_screen_test.dart
testWidgets('shows error on invalid email', (tester) async {
  await tester.pumpWidget(MyApp());
  await tester.enterText(find.byType(TextField).first, 'invalid');
  await tester.tap(find.text('Login'));
  await tester.pump();
  expect(find.text('Please enter a valid email'), findsOneWidget);
});
```

---

## 📱 Platform-Specific Setup

### Android Permissions
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
```

### iOS Permissions
Add to `ios/Runner/Info.plist`:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>We need access to record voice expenses</string>
```

---

## 🎨 UI/UX Guidelines

1. **Consistent Spacing**: Use multiples of 8 (8, 16, 24, 32)
2. **Color Usage**: Use theme colors from `AppTheme`
3. **Loading States**: Always show loading indicators
4. **Error Handling**: Show user-friendly error messages
5. **Empty States**: Show helpful messages when no data
6. **Confirmation Dialogs**: Ask before deleting data

---

## 🐛 Common Issues & Solutions

### Issue: "Dio error - Connection refused"
**Solution:** Update API URLs in `app_config.dart` with your machine's IP address

### Issue: "Provider not found"
**Solution:** Ensure provider is added in `main.dart` MultiProvider

### Issue: "Permission denied for microphone"
**Solution:** Add permissions to AndroidManifest.xml and Info.plist

### Issue: "Hot reload not working"
**Solution:** Use `flutter run` with `--hot` flag or restart app

---

## 📚 Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Provider Package](https://pub.dev/packages/provider)
- [Dio Package](https://pub.dev/packages/dio)
- [FL Chart Package](https://pub.dev/packages/fl_chart)
- [Material Design](https://material.io/design)

---

## ✅ Checklist for Developer 5

### Week 3-4: Core Features
- [ ] Implement expense list screen
- [ ] Implement add expense screen
- [ ] Implement voice expense recording
- [ ] Implement budget list screen
- [ ] Implement add budget screen
- [ ] Test all CRUD operations

### Week 5-6: Advanced Features
- [ ] Implement goals screens
- [ ] Implement reports screen
- [ ] Add expense chart (line chart)
- [ ] Add category pie chart
- [ ] Add filtering and search
- [ ] Implement notifications

### Week 7-8: Polish & Testing
- [ ] Add loading states everywhere
- [ ] Improve error handling
- [ ] Add empty states
- [ ] Write unit tests
- [ ] Write widget tests
- [ ] Test on real devices
- [ ] Fix UI bugs

### Week 9-10: Final
- [ ] Performance optimization
- [ ] Add animations
- [ ] Dark mode testing
- [ ] Create app icon
- [ ] Build release APK
- [ ] Prepare demo

---

## 🎯 Success Criteria

- ✅ All screens functional
- ✅ Voice expense works end-to-end
- ✅ Charts display correctly
- ✅ No crashes or errors
- ✅ Smooth user experience
- ✅ Works on both Android and iOS
- ✅ Dark mode supported
- ✅ Tests passing

---

Good luck with the implementation! 🚀
