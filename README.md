# Expensia - AI-Powered Personal Finance Tracker

## Flutter Frontend Application

### Project Structure

```
expensia_app/
├── lib/
│   ├── main.dart                      # App entry point
│   ├── app.dart                       # MaterialApp configuration
│   │
│   ├── core/                          # Core utilities and configuration
│   │   ├── config/
│   │   │   ├── app_config.dart        # API URLs and app configuration
│   │   │   └── theme.dart             # App theme (light/dark)
│   │   ├── constants/
│   │   │   ├── api_constants.dart     # API-related constants
│   │   │   └── app_constants.dart     # App-wide constants
│   │   └── utils/
│   │       ├── date_formatter.dart    # Date formatting utilities
│   │       ├── currency_formatter.dart # Currency formatting
│   │       └── validators.dart        # Form validation
│   │
│   ├── data/                          # Data layer
│   │   ├── models/                    # Data models
│   │   │   ├── user.dart
│   │   │   ├── expense.dart
│   │   │   ├── income.dart
│   │   │   ├── budget.dart
│   │   │   ├── goal.dart
│   │   │   └── notification.dart
│   │   ├── repositories/              # Data repositories
│   │   │   ├── auth_repository.dart
│   │   │   ├── expense_repository.dart
│   │   │   ├── budget_repository.dart
│   │   │   └── goal_repository.dart
│   │   └── services/                  # Services
│   │       ├── api_service.dart       # HTTP client (Dio)
│   │       ├── storage_service.dart   # Local storage
│   │       └── voice_service.dart     # Audio recording
│   │
│   ├── presentation/                  # Presentation layer
│   │   ├── providers/                 # State management (Provider)
│   │   │   ├── auth_provider.dart
│   │   │   ├── expense_provider.dart
│   │   │   ├── budget_provider.dart
│   │   │   ├── goal_provider.dart
│   │   │   └── theme_provider.dart
│   │   ├── screens/                   # UI screens
│   │   │   ├── auth/
│   │   │   │   ├── login_screen.dart
│   │   │   │   └── register_screen.dart
│   │   │   ├── home/
│   │   │   │   └── home_screen.dart
│   │   │   ├── expenses/
│   │   │   │   ├── expense_list_screen.dart
│   │   │   │   ├── add_expense_screen.dart
│   │   │   │   └── voice_expense_screen.dart
│   │   │   ├── budgets/
│   │   │   │   ├── budget_list_screen.dart
│   │   │   │   └── add_budget_screen.dart
│   │   │   ├── goals/
│   │   │   │   ├── goals_screen.dart
│   │   │   │   └── add_goal_screen.dart
│   │   │   └── reports/
│   │   │       └── reports_screen.dart
│   │   └── widgets/                   # Reusable widgets
│   │       ├── common/
│   │       │   ├── custom_button.dart
│   │       │   ├── custom_text_field.dart
│   │       │   └── loading_indicator.dart
│   │       ├── expense/
│   │       │   └── expense_card.dart
│   │       ├── budget/
│   │       │   └── budget_progress.dart
│   │       └── charts/
│   │           ├── expense_chart.dart
│   │           └── category_pie_chart.dart
│   │
│   └── routes/
│       └── app_router.dart            # Navigation routing
│
├── assets/                            # Static assets
│   ├── images/
│   ├── icons/
│   └── fonts/
│
├── test/                              # Tests
│   ├── widget_test/
│   └── unit_test/
│
├── pubspec.yaml                       # Dependencies
└── README.md                          # This file
```

### Setup Instructions

1. **Install Flutter**
   - Follow instructions at: https://flutter.dev/docs/get-started/install

2. **Install Dependencies**
   ```bash
   cd expensia_app
   flutter pub get
   ```

3. **Configure API Endpoints**
   - Edit `lib/core/config/app_config.dart`
   - Update `baseUrl` and `aiServiceUrl` with your backend URLs

4. **Run the App**
   ```bash
   # Development mode
   flutter run

   # Release mode
   flutter run --release
   ```

### Key Dependencies

- **provider**: State management
- **dio**: HTTP client for API calls
- **shared_preferences**: Local storage
- **fl_chart**: Charts and data visualization
- **record**: Audio recording for voice expenses
- **permission_handler**: Handle device permissions
- **intl**: Internationalization and formatting

### Features

✅ **Implemented:**
- Complete project structure
- Authentication (Login/Register)
- State management with Provider
- API service with Dio
- Local storage service
- Data models and repositories
- Theme support (Light/Dark)
- Form validation
- Routing system

🚧 **To Be Implemented:**
- Expense list and detail screens
- Voice expense recording
- Budget management screens
- Goals tracking screens
- Reports and analytics
- Charts implementation (fl_chart)
- Notifications
- Settings screen

### API Integration

The app communicates with two backend services:

1. **Spring Boot Backend** (`http://localhost:8080/api`)
   - Authentication
   - CRUD operations for expenses, budgets, goals
   - Reports and analytics

2. **FastAPI AI Service** (`http://localhost:8000/api`)
   - Speech-to-text
   - Expense categorization
   - Forecasting
   - Recommendations

### State Management

Using **Provider** pattern:
- `AuthProvider`: User authentication state
- `ExpenseProvider`: Expense management
- `BudgetProvider`: Budget tracking
- `GoalProvider`: Savings goals
- `ThemeProvider`: App theme

### Development Guidelines

1. **Code Style**
   - Follow Flutter/Dart style guide
   - Use meaningful variable names
   - Add comments for complex logic

2. **State Management**
   - Use Provider for global state
   - Use StatefulWidget for local state
   - Call `notifyListeners()` after state changes

3. **Error Handling**
   - Always use try-catch for async operations
   - Show user-friendly error messages
   - Log errors for debugging

4. **Testing**
   - Write unit tests for business logic
   - Write widget tests for UI components
   - Test API integration

### Next Steps

1. Implement expense list screen with real data
2. Add voice recording functionality
3. Create budget management screens
4. Implement charts using fl_chart
5. Add reports and analytics
6. Implement notifications
7. Add settings screen
8. Write tests
9. Optimize performance
10. Deploy to app stores

### Team Member: Developer 5 (Flutter Frontend Lead)

**Your Responsibilities:**
- Complete all UI screens
- Implement voice recording
- Add charts and visualizations
- Integrate with backend APIs
- Test on real devices
- Polish UI/UX

**Weekly Tasks:**
- Week 1-2: Setup, auth screens, home ✅
- Week 3-4: Expense, budget screens
- Week 5-6: Goals, reports, voice
- Week 7-10: Polish, testing, charts

### Contact

For questions or issues, contact the team lead or check the main project documentation.
