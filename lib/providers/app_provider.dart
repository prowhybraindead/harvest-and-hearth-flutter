import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/food_item.dart';
import '../models/recipe.dart';
import '../models/user.dart';
import '../constants/translations.dart';
import '../services/supabase_service.dart';

const _uuid = Uuid();

// Credentials for the built-in demo account.
// Create this user once in the Supabase dashboard → Authentication → Users.
const _kTestEmail = 'test@harvestandhearth.app';
const _kTestPassword = 'testPassword123!';

/// Custom URL scheme registered in AndroidManifest.xml for OAuth callbacks.
const _kOAuthRedirect = 'io.supabase.harvestandhearth://login-callback/';

class AppProvider extends ChangeNotifier {
  // ── State ──────────────────────────────────────────────────────────────────
  AppUser? _user;
  List<FoodItem> _inventory = [];
  List<Recipe> _savedRecipes = [];
  List<Recipe> _recipeCache = [];
  String _language = 'VIE';
  bool _isDark = false;
  bool _isInitialized = false;
  bool _hasSession = false;
  StreamSubscription<AuthState>? _authSub;

  // ── Getters ────────────────────────────────────────────────────────────────
  AppUser? get user => _user;
  /// True khi có session Supabase nhưng _user chưa load xong (dùng để giữ splash).
  bool get isLoadingUser => _hasSession && _user == null;
  List<FoodItem> get inventory => List.unmodifiable(_inventory);
  List<Recipe> get savedRecipes => List.unmodifiable(_savedRecipes);
  List<Recipe> get recipeCache => List.unmodifiable(_recipeCache);
  String get language => _language;
  bool get isDark => _isDark;
  bool get isInitialized => _isInitialized;

  String t(String key) => Translations.get(key, _language);

  // ── Init ───────────────────────────────────────────────────────────────────
  Future<void> init() async {
    // Restore UI preferences from local cache first (instant, no network)
    final prefs = await SharedPreferences.getInstance();
    _language = prefs.getString('language') ?? 'VIE';
    _isDark = prefs.getBool('isDark') ?? false;

    // Kiểm tra session từ local cache (không tốn network)
    final supaUser = SupabaseService.instance.currentUser;
    _hasSession = supaUser != null;

    // Hiện ngay màn hình login hoặc giữ splash (isLoadingUser) — không chờ DB
    _isInitialized = true;
    notifyListeners();

    // Load dữ liệu người dùng ngầm — splash tự biến mất khi xong
    if (supaUser != null) {
      await _loadUserData(supaUser);
      notifyListeners();
    }

    // Listen for sign-in (including OAuth callback) and sign-out
    _authSub =
        SupabaseService.instance.onAuthStateChange.listen((state) async {
      if (state.event == AuthChangeEvent.signedIn &&
          state.session != null &&
          _user == null) {
        await _loadUserData(state.session!.user);
        notifyListeners();
      } else if (state.event == AuthChangeEvent.signedOut) {
        _user = null;
        _inventory = [];
        _savedRecipes = [];
        _recipeCache = [];
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserData(User supaUser) async {
    // Run independent DB calls in parallel to reduce loading time
    final results = await Future.wait([
      SupabaseService.instance.getProfile(supaUser.id),
      SupabaseService.instance.getFoodItems(supaUser.id),
      SupabaseService.instance.getSavedRecipes(supaUser.id),
    ]);

    final profile = results[0] as Map<String, dynamic>?;
    final itemRows = results[1] as List<Map<String, dynamic>>;
    final recipeRows = results[2] as List<Map<String, dynamic>>;

    final displayName = profile?['name'] as String? ??
        supaUser.userMetadata?['full_name'] as String? ??
        supaUser.userMetadata?['name'] as String? ??
        supaUser.email?.split('@').first ??
        'User';

    // Upsert profile for new Google/OAuth users who have no profile row yet
    if (profile == null) {
      await SupabaseService.instance.upsertProfile(
        supaUser.id,
        name: displayName,
        email: supaUser.email,
      );
    } else {
      // Sync language / dark-mode from existing profile, then cache locally
      _language = profile['language'] as String? ?? _language;
      _isDark = profile['is_dark'] as bool? ?? _isDark;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', _language);
      await prefs.setBool('isDark', _isDark);
    }

    _user = AppUser(
      id: supaUser.id,
      email: supaUser.email ?? '',
      name: displayName,
      avatarUrl: supaUser.userMetadata?['avatar_url'] as String?,
    );

    // Load inventory — seed default data for brand-new users in one batch
    if (itemRows.isEmpty) {
      _inventory = _defaultInventory();
      await SupabaseService.instance.insertFoodItems(supaUser.id, _inventory);
    } else {
      _inventory = itemRows.map(FoodItem.fromSupabase).toList();
    }

    _savedRecipes = recipeRows
        .map((row) =>
            Recipe.fromJson(row['recipe_data'] as Map<String, dynamic>))
        .toList();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  // ── Auth ───────────────────────────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    try {
      await SupabaseService.instance.signInWithEmail(email, password);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> register(String email, String password, String name) async {
    try {
      await SupabaseService.instance.signUpWithEmail(email, password, name);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Opens the device browser for Google OAuth via Supabase.
  /// The result is handled by the auth-state stream in [init].
  Future<void> loginWithGoogle() =>
      SupabaseService.instance.signInWithGoogle(_kOAuthRedirect);

  Future<void> loginWithTestAccount() => login(_kTestEmail, _kTestPassword);

  Future<void> logout() => SupabaseService.instance.signOut();

  // ── Inventory ──────────────────────────────────────────────────────────────
  Future<void> addFood(FoodItem item) async {
    _inventory.insert(0, item);
    notifyListeners();
    if (_user != null) {
      await SupabaseService.instance.insertFoodItem(_user!.id, item);
    }
  }

  Future<void> removeFood(String id) async {
    _inventory.removeWhere((e) => e.id == id);
    notifyListeners();
    await SupabaseService.instance.deleteFoodItem(id);
  }

  Future<void> updateFood(String id, FoodItem updated) async {
    final index = _inventory.indexWhere((e) => e.id == id);
    if (index >= 0) {
      _inventory[index] = updated;
      notifyListeners();
      await SupabaseService.instance.updateFoodItem(updated);
    }
  }

  List<FoodItem> get fridgeItems =>
      _inventory.where((e) => e.storage == StorageType.fridge).toList();

  List<FoodItem> get freezerItems =>
      _inventory.where((e) => e.storage == StorageType.freezer).toList();

  List<FoodItem> get expiredItems =>
      _inventory.where((e) => e.isExpired).toList();

  List<FoodItem> get expiringSoonItems =>
      _inventory.where((e) => e.isExpiringSoon && !e.isExpired).toList();

  // ── Recipes ────────────────────────────────────────────────────────────────
  Future<void> saveRecipe(Recipe recipe) async {
    final exists = _savedRecipes.any((r) => r.id == recipe.id);
    if (!exists) {
      _savedRecipes.add(recipe.copyWith(isSaved: true));
      notifyListeners();
      if (_user != null) {
        await SupabaseService.instance.saveRecipe(_user!.id, recipe);
      }
    }
  }

  Future<void> unsaveRecipe(String id) async {
    _savedRecipes.removeWhere((r) => r.id == id);
    notifyListeners();
    if (_user != null) {
      await SupabaseService.instance.unsaveRecipe(_user!.id, id);
    }
  }

  bool isRecipeSaved(String id) => _savedRecipes.any((r) => r.id == id);

  void setRecipeCache(List<Recipe> recipes) {
    _recipeCache = recipes;
    notifyListeners();
  }

  // ── Settings ───────────────────────────────────────────────────────────────
  Future<void> setLanguage(String lang) async {
    _language = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    if (_user != null) {
      await SupabaseService.instance
          .updateProfileSettings(_user!.id, lang, _isDark);
    }
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', _isDark);
    if (_user != null) {
      await SupabaseService.instance
          .updateProfileSettings(_user!.id, _language, _isDark);
    }
  }

  // ── Default data ───────────────────────────────────────────────────────────
  List<FoodItem> _defaultInventory() {
    final now = DateTime.now();
    return [
      FoodItem(
        id: _uuid.v4(),
        name: 'Sữa tươi',
        category: FoodCategory.dairy,
        storage: StorageType.fridge,
        quantity: 1,
        unit: 'hộp',
        addedDate: now,
        expiryDate: now.add(const Duration(days: 5)),
        warningDays: 3,
      ),
      FoodItem(
        id: _uuid.v4(),
        name: 'Thịt bò',
        category: FoodCategory.meat,
        storage: StorageType.freezer,
        quantity: 500,
        unit: 'g',
        addedDate: now,
        expiryDate: now.add(const Duration(days: 30)),
        warningDays: 5,
      ),
      FoodItem(
        id: _uuid.v4(),
        name: 'Cà rốt',
        category: FoodCategory.vegetables,
        storage: StorageType.fridge,
        quantity: 3,
        unit: 'củ',
        addedDate: now,
        expiryDate: now.add(const Duration(days: 7)),
        warningDays: 2,
      ),
    ];
  }
}
