import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'login.dart';
import 'home/home_screen.dart';
import 'buy/buy_screen.dart';
import 'sell/sell_screen.dart';
import 'profile/profile_screen.dart';
import 'services/fcm_service.dart';
import 'services/firebase_service.dart';
import 'theme/app_theme.dart';
import 'widgets/pressable_glow.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FcmService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, isDark, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'StudXchange',
          theme: buildAppTheme(isDark: isDark),
          themeAnimationDuration: const Duration(milliseconds: 300),
          themeAnimationCurve: Curves.easeInOut,
          initialRoute: '/login',
          routes: {
            '/login': (context) => const LoginPage(),
            '/main': (context) => const MainNavigationPage(),
          },
        );
      },
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage>
    {
  int _currentIndex = 0;

  // User data from Firebase Auth
  String _userName = 'Student';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();

    // Read auth state once during init to avoid setState during build scopes.
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userName = user.displayName ?? user.email?.split('@')[0] ?? 'Student';
      _userEmail = user.email ?? '';
    }
    _bootstrapMarketplace();
  }

  Future<void> _bootstrapMarketplace() async {
    try {
      await FirebaseService.ensureMarketplaceItemsCount(total: 37);
    } catch (_) {}
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    // Initialize screens with user data (Firebase handles data)
    final screens = [
      HomeScreen(userName: _userName, userEmail: _userEmail),
      BuyScreen(),
      SellScreen(),
      ProfileScreen(userName: _userName, userEmail: _userEmail),
    ];

    return Scaffold(
      backgroundColor: colors.background,
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colors.card,
          boxShadow: [
            BoxShadow(
              color: colors.shadow,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
                _buildNavItem(1, Icons.search_outlined, Icons.search, 'Buy'),
                _buildNavItem(
                  2,
                  Icons.add_circle_outline,
                  Icons.add_circle,
                  'Sell',
                ),
                _buildNavItem(3, Icons.person_outline, Icons.person, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData outlinedIcon,
    IconData filledIcon,
    String label,
  ) {
    final isSelected = _currentIndex == index;

    final radius = BorderRadius.circular(20);

    return PressableGlow(
      onTap: () => _onTabTapped(index),
      borderRadius: radius,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [
                    Color(0xFF0A84FF),
                    Color(0xFF1E3A8A),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: radius,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? filledIcon : outlinedIcon,
              color: isSelected ? Colors.white : context.appColors.secondaryText,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected ? Colors.white : context.appColors.secondaryText,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
