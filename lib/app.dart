import 'package:flutter/material.dart';
import 'package:hockeyline/providers/auth_provider.dart';
import 'package:hockeyline/providers/lines_provider.dart';
import 'package:hockeyline/providers/stats_provider.dart';
import 'package:hockeyline/providers/team_provider.dart';
import 'package:hockeyline/screens/home_shell_screen.dart';
import 'package:hockeyline/screens/login_screen.dart';
import 'package:hockeyline/services/storage_service.dart';
import 'package:hockeyline/theme/app_theme.dart';
import 'package:provider/provider.dart';

class HockeyLineApp extends StatelessWidget {
  const HockeyLineApp({super.key});

  static final StorageService _storageService = StorageService();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(_storageService),
        ),
        ChangeNotifierProvider<TeamProvider>(
          create: (_) => TeamProvider(_storageService),
        ),
        ChangeNotifierProvider<LinesProvider>(
          create: (_) => LinesProvider(_storageService),
        ),
        ChangeNotifierProvider<StatsProvider>(
          create: (_) => StatsProvider(_storageService),
        ),
      ],
      child: MaterialApp(
        title: 'HockeyLine',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        theme: buildHockeyDarkTheme(),
        darkTheme: buildHockeyDarkTheme(),
        home: const _RootScreen(),
      ),
    );
  }
}

class _RootScreen extends StatefulWidget {
  const _RootScreen();

  @override
  State<_RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<_RootScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().bootstrapInitialSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    if (!auth.isBootstrapDone) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (auth.isAuthorized) {
      return const HomeShellScreen();
    }
    return const LoginScreen();
  }
}
