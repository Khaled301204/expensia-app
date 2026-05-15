import 'package:flutter/material.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/register_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/expenses/expense_list_screen.dart';
import '../presentation/screens/expenses/add_expense_screen.dart';
import '../presentation/screens/expenses/voice_expense_screen.dart';
import '../presentation/screens/budgets/budget_list_screen.dart';
import '../presentation/screens/budgets/add_budget_screen.dart';
import '../presentation/screens/goals/goals_screen.dart';
import '../presentation/screens/goals/add_goal_screen.dart';
import '../presentation/screens/reports/reports_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String expenseList = '/expenses';
  static const String addExpense = '/expenses/add';
  static const String voiceExpense = '/expenses/voice';
  static const String budgetList = '/budgets';
  static const String addBudget = '/budgets/add';
  static const String goals = '/goals';
  static const String addGoal = '/goals/add';
  static const String reports = '/reports';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      
      case expenseList:
        return MaterialPageRoute(builder: (_) => const ExpenseListScreen());
      
      case addExpense:
        return MaterialPageRoute(builder: (_) => const AddExpenseScreen());
      
      case voiceExpense:
        return MaterialPageRoute(builder: (_) => const VoiceExpenseScreen());
      
      case budgetList:
        return MaterialPageRoute(builder: (_) => const BudgetListScreen());
      
      case addBudget:
        return MaterialPageRoute(builder: (_) => const AddBudgetScreen());
      
      case goals:
        return MaterialPageRoute(builder: (_) => const GoalsScreen());
      
      case addGoal:
        return MaterialPageRoute(builder: (_) => const AddGoalScreen());
      
      case reports:
        return MaterialPageRoute(builder: (_) => const ReportsScreen());
      
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
