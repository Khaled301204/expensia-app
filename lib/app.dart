import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/config/theme.dart';
import 'presentation/providers/theme_provider.dart';
import 'routes/app_router.dart';

// Global key used by ApiService to navigate to login on session expiry.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ExpensiaApp extends StatelessWidget {
  const ExpensiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Expensia',
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          initialRoute: AppRouter.splash,
          onGenerateRoute: AppRouter.generateRoute,
        );
      },
    );
  }
}
