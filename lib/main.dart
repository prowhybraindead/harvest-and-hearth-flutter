import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/user.dart';
import 'providers/app_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/recipes_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/add_food_modal.dart';

/// Built once — avoids rebuilding [ColorScheme] / [ThemeData] on every [AppProvider] tick.
final ThemeData kAppLightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF2E7D32),
    brightness: Brightness.light,
    secondary: const Color(0xFFFF9800),
  ),
  scaffoldBackgroundColor: const Color(0xFFF8FAF9),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFF8FAF9),
    surfaceTintColor: Colors.transparent,
    elevation: 0,
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFE0E7E2)),
    ),
    color: Colors.white,
  ),
);

final ThemeData kAppDarkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF176A21),
    brightness: Brightness.dark,
    secondary: const Color(0xFFFFB74D),
  ),
  scaffoldBackgroundColor: const Color(0xFF050C07),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF050C07),
    surfaceTintColor: Colors.transparent,
    elevation: 0,
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFF1A3320)),
    ),
    color: const Color(0xFF0D1F11),
  ),
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env is optional in CI / first-run dev setups
  }

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty) {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
      // PKCE is the secure default for mobile OAuth flows
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider()..init(),
      child: const HarvestAndHearthApp(),
    ),
  );
}

/// Only theme + routing inputs — avoids rebuilding [MaterialApp] when inventory/recipes change.
@immutable
class _AppUiState {
  const _AppUiState({
    required this.isDark,
    required this.isInitialized,
    required this.isLoadingUser,
    required this.user,
  });

  final bool isDark;
  final bool isInitialized;
  final bool isLoadingUser;
  final AppUser? user;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _AppUiState &&
          runtimeType == other.runtimeType &&
          isDark == other.isDark &&
          isInitialized == other.isInitialized &&
          isLoadingUser == other.isLoadingUser &&
          user == other.user;

  @override
  int get hashCode => Object.hash(isDark, isInitialized, isLoadingUser, user);
}

class HarvestAndHearthApp extends StatelessWidget {
  const HarvestAndHearthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<AppProvider, _AppUiState>(
      selector: (_, p) => _AppUiState(
        isDark: p.isDark,
        isInitialized: p.isInitialized,
        isLoadingUser: p.isLoadingUser,
        user: p.user,
      ),
      builder: (context, state, _) {
        return MaterialApp(
          title: 'Harvest & Hearth',
          debugShowCheckedModeBanner: false,
          themeMode: state.isDark ? ThemeMode.dark : ThemeMode.light,
          theme: kAppLightTheme,
          darkTheme: kAppDarkTheme,
          home: !state.isInitialized || state.isLoadingUser
              ? const _SplashScreen()
              : (state.user == null
                  ? const AuthScreen()
                  : const MainShell()),
        );
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.eco_rounded,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Harvest & Hearth',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const List<Widget> _screens = [
    DashboardScreen(),
    InventoryScreen(),
    RecipesScreen(),
    ProfileScreen(),
  ];

  void _showAddFoodModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const AddFoodModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild shell chrome only when language changes (not on every inventory/recipe tick).
    final lang = context.select<AppProvider, String>((p) => p.language);
    final t = context.read<AppProvider>().t;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton(
              onPressed: _showAddFoodModal,
              tooltip: t('add_food'),
              child: const Icon(Icons.add_rounded),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        key: ValueKey<String>(lang),
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: t('nav_home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.kitchen_outlined),
            selectedIcon: const Icon(Icons.kitchen),
            label: t('nav_inventory'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.restaurant_menu_outlined),
            selectedIcon: const Icon(Icons.restaurant_menu),
            label: t('nav_recipes'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: t('nav_profile'),
          ),
        ],
      ),
    );
  }
}
