# Expensia — AI-Powered Personal Finance Tracker

A full-stack personal finance management application that combines a Flutter web frontend with a Spring Boot REST API and a FastAPI AI microservice. All AI features (categorization, voice transcription, recommendations, forecasting) run through the Spring Boot backend — the Flutter app never calls the AI service directly.

---

## Architecture

```
┌─────────────────────────────────┐
│     Flutter Web Frontend        │  ← This repository
│     (Material 3, Provider)      │
└────────────┬────────────────────┘
             │ HTTP / REST
             ▼
┌─────────────────────────────────┐
│   Spring Boot Backend           │
│   localhost:8080/api            │
│   (Auth, CRUD, Reports, AI relay│
└────────────┬────────────────────┘
             │
     ┌───────┴───────┐
     ▼               ▼
┌─────────┐   ┌──────────────────┐
│PostgreSQL│   │ FastAPI AI Service│
│         │   │ localhost:8000    │
└─────────┘   │ (NLP, STT, ML)   │
              └──────────────────┘
```

---

## Features

### Authentication
- Email / password login and registration
- JWT-based session stored in `SharedPreferences`
- Auto-login on app launch if token is valid
- Logout clears all stored state

### Dashboard (Home)
- Total balance, total income, total expenses summary cards
- Spending breakdown pie chart by category
- Recent transactions list
- Quick-action buttons (Add Expense, Add Income, Voice, Reports)
- Wallet balance display

### Expenses
- Full expense list with search, filter (category, payment method, date range), and sort (newest / oldest / highest / lowest)
- Active filter chips with individual remove buttons
- Add expense form with AI-assisted text parsing (`POST /expenses/parse-text`) — type a natural language description and fields are auto-filled
- Category is AI-assigned by the backend based on merchant and description
- Edit expense with category, date, merchant, description, payment method
- Delete with confirmation dialog
- **Recurring expenses**: toggle recurring on create, pick frequency (Daily / Weekly / Monthly / Yearly); edit form shows frequency picker + Pause/Resume switch
- Recurring badge on each tile showing frequency, "Paused" state, and next occurrence date
- Voice expense creation (see Voice section below)

### Voice Expense
- Record audio directly in the browser
- Two-step flow: preview transcribed fields (amount, merchant, description, category, confidence score) → confirm or cancel
- Editable preview before committing
- Mic permission handled gracefully

### Income
- Income list with total banner
- Add income: amount, source (dropdown), date, recurring toggle + frequency picker
- Edit income: all fields editable; recurring incomes show frequency dropdown + Pause/Resume switch
- Delete with confirmation
- Frequency chip on each tile dims when paused; shows "Next: MMM dd" when active

### Budgets
- Budget list with progress bars showing spent vs. limit per category
- Add and edit budget forms
- Visual progress indicator (color changes as budget approaches/exceeds limit)

### Savings Goals
- Goal cards showing target, current amount, and progress ring
- Add and edit goals (name, target amount, deadline)
- **Add Savings**: deposit amount toward a goal, wallet balance updates
- **Withdraw from Goal**: withdraw any amount up to the current saved amount, wallet balance updates
- Completed goals shown with a distinct completed state

### Wallet
- Current wallet balance
- Top-up and withdraw wallet balance
- Balance refreshes automatically after goal deposits/withdrawals

### Reports
Three-tab report screen:

**Overview tab**
- Monthly income vs. expense bar chart
- Summary totals

**Monthly tab**
- Detailed monthly breakdown
- Category-level spending

**AI Tips tab**
- Spending insights
- Saving recommendations
- Investment suggestions
- Goal plans
- Each section rendered as structured cards

**Export**
- Export to CSV or PDF via date range dialog
- Pick start and end date; Export button disabled until both dates selected and range is valid
- Downloads file directly in the browser

### AI Insights
- Full insights screen with AI-generated spending analysis
- Benchmarks: how your spending compares to similar profiles
- Forecast: projected spending trend
- All data sourced from `GET /reports/insights`

### Notifications
- Notification list from backend
- Read/unread state
- Empty state when no notifications

### Profile
- View and edit display name and email
- Avatar with first-letter placeholder
- **Dark / Light theme toggle** — persists across sessions via `SharedPreferences`

---

## Screens & Routes

| Route | Screen |
|---|---|
| `/` or `/login` | Login |
| `/register` | Register |
| `/home` | Dashboard / Home |
| `/expenses` | Expense list with search & filter |
| `/expenses/add` | Add expense |
| `/expenses/edit` | Edit expense |
| `/expenses/voice` | Voice expense recorder |
| `/incomes` | Income list |
| `/incomes/add` | Add income |
| `/budgets` | Budget list |
| `/budgets/add` | Add budget |
| `/goals` | Savings goals |
| `/goals/add` | Add goal |
| `/reports` | Reports (3 tabs + export) |
| `/insights` | AI insights |
| `/notifications` | Notifications |
| `/wallet` | Wallet |
| `/profile` | Profile + theme toggle |

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI framework | Flutter 3.x (web target) |
| State management | Provider |
| HTTP client | Dio 5 |
| Local storage | SharedPreferences |
| Charts | fl_chart |
| Audio recording | record 7 |
| Fonts | Google Fonts (Inter) |
| Date/number formatting | intl |

---

## Project Structure

```
lib/
├── main.dart
├── app.dart                          # MaterialApp, MultiProvider setup
│
├── core/
│   ├── config/
│   │   ├── app_config.dart           # Base URL (dart-define), all endpoint constants
│   │   └── theme.dart                # AppTheme — dark OLED palette, light palette
│   ├── constants/
│   │   ├── api_constants.dart
│   │   └── app_constants.dart        # Payment methods, frequency labels, etc.
│   └── utils/
│       ├── currency_formatter.dart
│       ├── date_formatter.dart
│       ├── file_download.dart        # Conditional export: web vs. stub
│       ├── file_download_web.dart    # dart:html download for CSV/PDF
│       ├── file_download_stub.dart
│       └── validators.dart
│
├── data/
│   ├── models/
│   │   ├── user.dart
│   │   ├── expense.dart              # + isRecurring, frequency, nextOccurrence, recurringActive
│   │   ├── income.dart               # + isRecurring, frequency, nextOccurrence, recurringActive
│   │   ├── budget.dart
│   │   ├── goal.dart
│   │   ├── dashboard.dart
│   │   ├── wallet.dart
│   │   ├── category.dart
│   │   ├── insights.dart             # SpendingInsight, RecommendationsInsight, etc.
│   │   ├── monthly_report.dart
│   │   ├── notification.dart
│   │   └── voice_preview.dart        # Two-step voice expense preview model
│   ├── repositories/
│   │   ├── auth_repository.dart
│   │   ├── expense_repository.dart   # create/update support recurring fields
│   │   ├── income_repository.dart    # create/update support recurring fields
│   │   ├── budget_repository.dart
│   │   ├── goal_repository.dart      # addSavings + withdrawSavings
│   │   ├── category_repository.dart
│   │   ├── insights_repository.dart
│   │   ├── reports_repository.dart   # getRecommendations returns RecommendationsInsight?
│   │   ├── notification_repository.dart
│   │   └── wallet_repository.dart
│   └── services/
│       ├── api_service.dart          # Dio client, JWT interceptor, base URL from dart-define
│       ├── storage_service.dart      # SharedPreferences wrapper
│       └── voice_service.dart        # Audio recording via record package
│
├── presentation/
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── expense_provider.dart     # createExpense/updateExpense with recurring params
│   │   ├── income_provider.dart      # createIncome/updateIncome with recurring params
│   │   ├── budget_provider.dart
│   │   ├── goal_provider.dart        # addSavings + withdrawSavings
│   │   ├── dashboard_provider.dart
│   │   ├── wallet_provider.dart
│   │   ├── insights_provider.dart
│   │   ├── reports_provider.dart     # recommendations typed as RecommendationsInsight?
│   │   ├── notification_provider.dart
│   │   └── theme_provider.dart       # toggleTheme(), persists via SharedPreferences
│   └── screens/
│       ├── auth/
│       │   ├── login_screen.dart
│       │   └── register_screen.dart
│       ├── home/
│       │   └── home_screen.dart
│       ├── expenses/
│       │   ├── expense_list_screen.dart   # search, filter, sort, recurring badges
│       │   ├── add_expense_screen.dart    # AI text parse, recurring toggle
│       │   ├── edit_expense_screen.dart   # frequency + pause/resume for recurring
│       │   └── voice_expense_screen.dart  # record → preview → confirm
│       ├── incomes/
│       │   ├── income_list_screen.dart    # recurring badge, pause/next date
│       │   ├── add_income_screen.dart     # recurring toggle + frequency
│       │   └── edit_income_screen.dart    # frequency + pause/resume for recurring
│       ├── budgets/
│       │   ├── budget_list_screen.dart
│       │   ├── add_budget_screen.dart
│       │   └── edit_budget_screen.dart
│       ├── goals/
│       │   ├── goals_screen.dart          # Add Savings + Withdraw buttons
│       │   ├── add_goal_screen.dart
│       │   └── edit_goal_screen.dart
│       ├── reports/
│       │   └── reports_screen.dart        # 3 tabs, AI Tips, date-range CSV/PDF export
│       ├── insights/
│       │   └── insights_screen.dart
│       ├── notifications/
│       │   └── notifications_screen.dart
│       ├── wallet/
│       │   └── wallet_screen.dart
│       └── profile/
│           └── profile_screen.dart        # theme toggle
│
└── routes/
    └── app_router.dart
```

---

## API Endpoints Used

All requests go to `http://localhost:8080/api` (configurable via `--dart-define`).

| Method | Endpoint | Purpose |
|---|---|---|
| POST | `/auth/login` | Login, returns JWT |
| POST | `/auth/register` | Register new user |
| GET | `/dashboard/summary` | Home dashboard data |
| GET | `/expenses` | List expenses (paginated, date filter) |
| POST | `/expenses` | Create expense (recurring fields optional) |
| PUT | `/expenses/{id}` | Update expense |
| DELETE | `/expenses/{id}` | Delete expense |
| POST | `/expenses/voice/preview` | Transcribe audio → preview fields |
| POST | `/expenses/voice/confirm` | Confirm and create voice expense |
| POST | `/expenses/parse-text` | AI text → expense fields |
| GET | `/incomes` | List incomes |
| POST | `/incomes` | Create income (recurring fields optional) |
| PUT | `/incomes/{id}` | Update income |
| DELETE | `/incomes/{id}` | Delete income |
| GET | `/budgets` | List budgets |
| POST | `/budgets` | Create budget |
| PUT | `/budgets/{id}` | Update budget |
| DELETE | `/budgets/{id}` | Delete budget |
| GET | `/goals` | List goals |
| POST | `/goals` | Create goal |
| PUT | `/goals/{id}` | Update goal |
| DELETE | `/goals/{id}` | Delete goal |
| POST | `/goals/{id}/savings` | Add savings to goal |
| POST | `/goals/{id}/withdraw` | Withdraw from goal |
| GET | `/wallet` | Get wallet balance |
| POST | `/wallet/topup` | Top up wallet |
| POST | `/wallet/withdraw` | Withdraw from wallet |
| GET | `/reports/monthly` | Monthly income/expense report |
| GET | `/reports/insights` | AI spending insights |
| GET | `/reports/recommendations` | AI tips (spending, saving, investment, goal plans) |
| GET | `/reports/forecast` | Spending forecast |
| GET | `/reports/benchmarks` | Peer comparison benchmarks |
| GET | `/reports/export/csv` | Export CSV (`?startDate=&endDate=`) |
| GET | `/reports/export/pdf` | Export PDF (`?startDate=&endDate=`) |
| GET | `/categories` | List expense categories |
| GET | `/notifications` | List notifications |
| GET | `/user/me` | Current user profile |
| PUT | `/user/me` | Update profile |

---

## Recurring Transactions

The backend runs a daily scheduler (1 AM) that auto-creates copies of active recurring templates.

**Frontend behavior:**
- On **create**: send `isRecurring: true`, `frequency: "MONTHLY"`, `recurringActive: true`
- On **edit**: change `frequency` or toggle `recurringActive: false` to pause
- Generated copies look like normal transactions (`isRecurring: false`) — they are not templates
- Each recurring tile shows: frequency label, pause icon when paused, "Next: MMM dd" when active

Supported frequencies: `DAILY`, `WEEKLY`, `MONTHLY`, `YEARLY`

---

## Running Locally (Development)

### Prerequisites
- Flutter 3.x with web support enabled: `flutter config --enable-web`
- Spring Boot backend running on port 8080
- (Optional) FastAPI AI service running on port 8000

### Steps

```bash
# 1. Install dependencies
flutter pub get

# 2. Run on web (Chrome)
flutter run -d chrome

# 3. Run with a custom backend URL
flutter run -d chrome --dart-define=API_BASE_URL=http://192.168.1.100:8080/api
```

---

## Docker

### Build the image

```bash
docker build -t expensia-frontend .

# With a custom backend URL
docker build \
  --build-arg API_BASE_URL=http://your-backend-host:8080/api \
  -t expensia-frontend .
```

### Run the container

```bash
docker run -d -p 80:80 --name expensia-frontend expensia-frontend
```

The app is then available at `http://localhost`.

### Docker Compose (recommended)

```yaml
services:
  frontend:
    build:
      context: .
      args:
        API_BASE_URL: http://backend:8080/api
    ports:
      - "80:80"
    depends_on:
      - backend

  backend:
    image: expensia-backend:latest
    ports:
      - "8080:8080"
```

### Teammate setup after pulling

```bash
git pull
docker stop expensia-frontend
docker rm expensia-frontend
docker build -t expensia-frontend .
docker run -d -p 80:80 --name expensia-frontend expensia-frontend
```

---

## Environment Configuration

The API base URL is baked in at **compile time** via `--dart-define`:

```dart
// lib/core/config/app_config.dart
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080/api',
);
```

This means you must rebuild the image (or re-run `flutter run`) when the backend URL changes. There is no runtime config file.

---

## Theme

The app ships with a dark OLED-first theme (`AppTheme`) and a full light theme. The user can toggle between them from the Profile screen. The preference persists across sessions.

| Token | Dark value |
|---|---|
| Background | `#090909` |
| Card | `#111111` |
| Elevated | `#1A1A1A` |
| Primary (blue) | `#4C8BF5` |
| Secondary (green) | `#10B981` |
| Error (red) | `#EF4444` |

---

## Troubleshooting

**Login returns 403 for a teammate but works for you**
Their browser has a stored expired JWT. Fix: open DevTools → Application → Storage → Clear site data, then log in again. Or use an Incognito window.

The permanent backend fix is to catch `ExpiredJwtException` in `JwtAuthenticationFilter` and call `filterChain.doFilter()` instead of returning 403, so that the `/auth/login` endpoint remains accessible even when an expired token is present in the `Authorization` header.

**Voice recording not working**
The browser must be served over HTTPS (or `localhost`) for microphone access. Check that `navigator.mediaDevices` is available in DevTools console.

**Export downloads an empty file**
Confirm the backend accepts `startDate` and `endDate` query params on `/reports/export/csv` and `/reports/export/pdf`. Both dates are sent in `yyyy-MM-dd` format.

---

## Dependencies

| Package | Version | Purpose |
|---|---|---|
| provider | ^6.1.1 | State management |
| dio | ^5.4.0 | HTTP client |
| shared_preferences | ^2.2.2 | JWT + theme persistence |
| fl_chart | ^0.66.0 | Bar and pie charts |
| record | ^7.0.0 | Audio recording |
| permission_handler | ^11.1.0 | Mic permission |
| google_fonts | ^6.1.0 | Inter font family |
| intl | ^0.18.1 | Date and number formatting |
| flutter_svg | ^2.0.9 | SVG assets |
| path_provider | ^2.1.2 | File paths |
