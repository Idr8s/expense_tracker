import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'hive_service.dart';       // ← Hive init

import 'auth_provider.dart';
import 'expense_provider.dart';
import 'budget_provider.dart';
import 'app_theme.dart';
import 'login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:                     Colors.transparent,
    statusBarIconBrightness:            Brightness.light,
    systemNavigationBarColor:           AppColors.bg,
    systemNavigationBarIconBrightness:  Brightness.light,
  ));


  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  
  await HiveService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'AI Expense Tracker',
        theme: ThemeData(
          useMaterial3: true,
          brightness:   Brightness.dark,
          scaffoldBackgroundColor: AppColors.bg,
          colorScheme: ColorScheme.dark(
            primary:   AppColors.primary,
            secondary: AppColors.gold,
            surface:   AppColors.surface,
            error:     AppColors.error,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation:       0,
            centerTitle:     false,
            iconTheme:       IconThemeData(color: AppColors.textPrimary),
            titleTextStyle:  TextStyle(
              color:         AppColors.textPrimary,
              fontSize:      20,
              fontWeight:    FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          cardTheme: CardThemeData(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
          ),
          snackBarTheme: SnackBarThemeData(
            backgroundColor: AppColors.elevated,
            contentTextStyle: const TextStyle(color: AppColors.textPrimary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            behavior: SnackBarBehavior.floating,
          ),
          datePickerTheme: DatePickerThemeData(
            backgroundColor:      AppColors.surface,
            headerBackgroundColor: AppColors.elevated,
            headerForegroundColor: AppColors.primary,
            dayForegroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected)
                  ? AppColors.bg
                  : AppColors.textPrimary,
            ),
            dayBackgroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected)
                  ? AppColors.primary
                  : Colors.transparent,
            ),
            todayForegroundColor:
                WidgetStateProperty.all(AppColors.primary),
            todayBackgroundColor:
                WidgetStateProperty.all(AppColors.primary.withOpacity(0.15)),
            yearForegroundColor:
                WidgetStateProperty.all(AppColors.textPrimary),
            dividerColor: AppColors.border,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          dropdownMenuTheme: DropdownMenuThemeData(
            textStyle: const TextStyle(color: AppColors.textPrimary),
            menuStyle: MenuStyle(
              backgroundColor:
                  WidgetStateProperty.all(AppColors.elevated),
            ),
          ),
        ),
        home: const LoginScreen(),
      ),
    ),
  );
}
