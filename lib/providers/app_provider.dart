import 'dart:async';

import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../core/simulated_clock.dart';
import '../models/chat_message.dart';
import '../models/food_item.dart';
import '../models/recipe.dart';
import '../models/user.dart';
import '../constants/translations.dart';
import '../services/backend_api_service.dart';
import '../services/expiry_reminder_service.dart';
import '../services/groq_chat_service.dart';
import '../services/home_widget_service.dart';

const _uuid = Uuid();

class AppProvider extends ChangeNotifier {
  // ── State ──────────────────────────────────────────────────────────────────
  AppUser? _user;
  List<FoodItem> _inventory = [];
  List<Recipe> _savedRecipes = [];
  List<Recipe> _recipeCache = [];
  String _language = 'VIE';
  bool _isDark = false;
  bool _isInitialized = false;
  bool _isLoadingUser = false;
  String? _boundUserId;
  bool _expiryRemindersEnabled = true;
  List<Map<String, dynamic>> _notificationLogs = [];
  bool _isLoadingNotifications = false;

  // ── Chat State ─────────────────────────────────────────────────────────────
  List<ChatMessage> _chatMessages = [];
  bool _isAiTyping = false;
  String? _chatError;
  String? _lastFailedUserMessage;

  // ── Getters ────────────────────────────────────────────────────────────────
  AppUser? get user => _user;

  /// True while loading profile/inventory after Clerk sign-in.
  bool get isLoadingUser => _isLoadingUser;
  List<FoodItem> get inventory => List.unmodifiable(_inventory);
  List<Recipe> get savedRecipes => List.unmodifiable(_savedRecipes);
  List<Recipe> get recipeCache => List.unmodifiable(_recipeCache);
  String get language => _language;
  bool get isDark => _isDark;
  bool get isInitialized => _isInitialized;
  bool get expiryRemindersEnabled => _expiryRemindersEnabled;
  List<Map<String, dynamic>> get notificationLogs =>
      List.unmodifiable(_notificationLogs);
  bool get isLoadingNotifications => _isLoadingNotifications;

  // Chat getters
  List<ChatMessage> get chatMessages => List.unmodifiable(_chatMessages);
  bool get isAiTyping => _isAiTyping;
  String? get chatError => _chatError;
    bool get canRetryLastChat =>
      _lastFailedUserMessage != null && _lastFailedUserMessage!.isNotEmpty;
  List<String> get chatQuickPrompts =>
      GroqChatService.instance.getQuickPrompts(_language, _inventory);

  String t(String key) => Translations.get(key, _language);

  // ── Init ───────────────────────────────────────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _language = prefs.getString('language') ?? 'VIE';
    _isDark = prefs.getBool('isDark') ?? false;
    _expiryRemindersEnabled =
        prefs.getBool(ExpiryReminderService.prefsKeyEnabled) ?? true;
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setExpiryRemindersEnabled(bool value) async {
    _expiryRemindersEnabled = value;
    notifyListeners();
    await ExpiryReminderService.instance.setRemindersEnabled(value);
    if (value) {
      await ExpiryReminderService.instance
          .requestPostNotificationsPermissionIfNeeded();
    }
    await _syncExpiryRemindersAndWidget();
  }

  void _scheduleAlerts() {
    unawaited(_syncExpiryRemindersAndWidget());
  }

  /// After changing [SimulatedClock] offset (time simulator).
  void applySimulatedTime() {
    notifyListeners();
    _scheduleAlerts();
  }

  Future<void> _syncExpiryRemindersAndWidget() async {
    await ExpiryReminderService.instance
        .syncInventory(
          _inventory,
          language: _language,
          userId: _user?.id,
        );
    await HomeWidgetService.instance.update(_inventory, _language);
  }

  /// Call after Clerk sign-in so API calls can use [sessionToken].
  Future<void> bindClerkSession(
    ClerkAuthState authState,
    clerk.User clerkUser,
  ) async {
    if (_boundUserId == clerkUser.id && _user != null) return;

    BackendApiService.instance.attach(authState);
    _boundUserId = clerkUser.id;
    _isLoadingUser = true;
    notifyListeners();

    try {
      if (BackendApiService.instance.isConfigured) {
        await _loadUserData(clerkUser);
      } else {
        _user = _appUserFromClerk(clerkUser);
      }
    } catch (e, st) {
      debugPrint('bindClerkSession: $e\n$st');
      _user = _appUserFromClerk(clerkUser);
    } finally {
      _isLoadingUser = false;
      notifyListeners();
    }
  }

  /// Clears local session state (e.g. after sign-out).
  void clearSession() {
    _user = null;
    _inventory = [];
    _savedRecipes = [];
    _recipeCache = [];
    _boundUserId = null;
    _isLoadingUser = false;
    _chatMessages = [];
    _isAiTyping = false;
    _chatError = null;
    _lastFailedUserMessage = null;
    _notificationLogs = [];
    _isLoadingNotifications = false;
    GroqChatService.instance.clearHistory();
    SimulatedClock.reset();
    BackendApiService.instance.detach();
    unawaited(_clearAlerts());
    notifyListeners();
  }

  Future<void> _clearAlerts() async {
    await ExpiryReminderService.instance.cancelAll();
    await HomeWidgetService.instance.clear();
  }

  AppUser _appUserFromClerk(clerk.User u) {
    final email = u.email ?? '';
    final name = u.name.trim().isNotEmpty
        ? u.name.trim()
        : (email.isNotEmpty ? email.split('@').first : 'User');
    return AppUser(
      id: u.id,
      email: email,
      name: name,
      avatarUrl: u.imageUrl ?? u.profileImageUrl,
    );
  }

  Future<void> _loadUserData(clerk.User clerkUser) async {
    final profile = await BackendApiService.instance.getProfile();
    final itemRows = await BackendApiService.instance.getFoodItems(clerkUser.id);
    final recipeRows = await _safeApiCall<List<Map<String, dynamic>>>(
          'getSavedRecipes',
          () => BackendApiService.instance.getSavedRecipes(clerkUser.id),
        ) ??
        const <Map<String, dynamic>>[];
    final notificationRows = await _safeApiCall<List<Map<String, dynamic>>>(
          'getNotificationLogs',
          () => BackendApiService.instance.getNotificationLogs(),
        ) ??
        const <Map<String, dynamic>>[];

    final nameFromProfile = profile['name'] as String?;
    final displayName =
        (nameFromProfile != null && nameFromProfile.trim().isNotEmpty)
            ? nameFromProfile.trim()
            : (clerkUser.name.trim().isNotEmpty
                ? clerkUser.name.trim()
                : (clerkUser.email?.split('@').first ?? 'User'));

    if (nameFromProfile == null || nameFromProfile.trim().isEmpty) {
      await BackendApiService.instance.upsertProfile(
        clerkUser.id,
        name: displayName,
        email: clerkUser.email,
      );
    } else {
      _language = profile['language'] as String? ?? _language;
      _isDark = profile['is_dark'] as bool? ?? _isDark;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', _language);
      await prefs.setBool('isDark', _isDark);
    }

    _user = AppUser(
      id: clerkUser.id,
      email: clerkUser.email ?? '',
      name: displayName,
      avatarUrl: clerkUser.imageUrl ?? clerkUser.profileImageUrl,
    );

    if (itemRows.isEmpty) {
      _inventory = _defaultInventory();
      await BackendApiService.instance.insertFoodItems(
        clerkUser.id,
        _inventory,
      );
    } else {
      _inventory = _parseFoodRows(itemRows);
    }

    _savedRecipes = _parseSavedRecipeRows(recipeRows);
    _notificationLogs = notificationRows;
    _scheduleAlerts();
  }

  Future<T?> _safeApiCall<T>(String label, Future<T> Function() action) async {
    try {
      return await action();
    } catch (e, st) {
      debugPrint('$label: $e\n$st');
      return null;
    }
  }

  List<FoodItem> _parseFoodRows(List<Map<String, dynamic>> rows) {
    final out = <FoodItem>[];
    for (final row in rows) {
      try {
        out.add(FoodItem.fromApiRow(row));
      } catch (e, st) {
        debugPrint('FoodItem.fromApiRow: $e\n$st');
      }
    }
    return out;
  }

  List<Recipe> _parseSavedRecipeRows(List<Map<String, dynamic>> rows) {
    final out = <Recipe>[];
    for (final row in rows) {
      final raw = row['recipe_data'];
      if (raw is! Map) continue;
      try {
        out.add(Recipe.fromJson(Map<String, dynamic>.from(raw)));
      } catch (e, st) {
        debugPrint('Recipe.fromJson(saved): $e\n$st');
      }
    }
    return out;
  }

  Future<void> refreshNotificationLogs() async {
    if (!BackendApiService.instance.isConfigured) return;
    _isLoadingNotifications = true;
    notifyListeners();
    try {
      _notificationLogs = await BackendApiService.instance.getNotificationLogs();
    } catch (e, st) {
      debugPrint('refreshNotificationLogs: $e\n$st');
    } finally {
      _isLoadingNotifications = false;
      notifyListeners();
    }
  }

  Future<void> markNotificationLogRead(String id, {bool isRead = true}) async {
    if (id.isEmpty || !BackendApiService.instance.isConfigured) return;
    final index = _notificationLogs.indexWhere((n) => n['id'] == id);
    if (index == -1) return;

    _notificationLogs[index] = {
      ..._notificationLogs[index],
      'isRead': isRead,
    };
    notifyListeners();

    try {
      await BackendApiService.instance.setNotificationLogRead(
        id,
        isRead: isRead,
      );
    } catch (e, st) {
      debugPrint('markNotificationLogRead: $e\n$st');
    }
  }

  // ── Auth (Clerk UI handles sign-in; only sign-out from app) ────────────────
  Future<void> logout(ClerkAuthState auth) async {
    clearSession();
    await auth.signOut();
  }

  // ── Inventory ──────────────────────────────────────────────────────────────
  Future<void> addFood(FoodItem item) async {
    _inventory.insert(0, item);
    notifyListeners();
    if (_user != null && BackendApiService.instance.isConfigured) {
      try {
        await BackendApiService.instance.insertFoodItem(_user!.id, item);
      } catch (e, st) {
        debugPrint('addFood: $e\n$st');
      }
    }
    _scheduleAlerts();
  }

  Future<void> removeFood(String id) async {
    _inventory.removeWhere((e) => e.id == id);
    notifyListeners();
    if (!BackendApiService.instance.isConfigured) return;
    try {
      await BackendApiService.instance.deleteFoodItem(id);
    } catch (e, st) {
      debugPrint('removeFood: $e\n$st');
    }
    _scheduleAlerts();
  }

  Future<void> updateFood(String id, FoodItem updated) async {
    final index = _inventory.indexWhere((e) => e.id == id);
    if (index >= 0) {
      _inventory[index] = updated;
      notifyListeners();
      if (BackendApiService.instance.isConfigured) {
        try {
          await BackendApiService.instance.updateFoodItem(updated);
        } catch (e, st) {
          debugPrint('updateFood: $e\n$st');
        }
      }
    }
    _scheduleAlerts();
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
      if (_user != null && BackendApiService.instance.isConfigured) {
        try {
          await BackendApiService.instance.saveRecipe(_user!.id, recipe);
        } catch (e, st) {
          debugPrint('saveRecipe: $e\n$st');
        }
      }
    }
  }

  Future<void> unsaveRecipe(String id) async {
    _savedRecipes.removeWhere((r) => r.id == id);
    notifyListeners();
    if (_user != null && BackendApiService.instance.isConfigured) {
      try {
        await BackendApiService.instance.unsaveRecipe(_user!.id, id);
      } catch (e, st) {
        debugPrint('unsaveRecipe: $e\n$st');
      }
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
    if (_user != null && BackendApiService.instance.isConfigured) {
      try {
        await BackendApiService.instance
            .updateProfileSettings(_user!.id, lang, _isDark);
      } catch (e, st) {
        debugPrint('setLanguage: $e\n$st');
      }
    }
    _scheduleAlerts();
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', _isDark);
    if (_user != null && BackendApiService.instance.isConfigured) {
      try {
        await BackendApiService.instance
            .updateProfileSettings(_user!.id, _language, _isDark);
      } catch (e, st) {
        debugPrint('toggleTheme: $e\n$st');
      }
    }
    _scheduleAlerts();
  }

  // ── AI Chat ────────────────────────────────────────────────────────────────
  Future<void> sendChatMessage(String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty || _isAiTyping) return;

    _chatError = null;
    _lastFailedUserMessage = null;
    // Add user message
    final userMsg = ChatMessage(
      id: const Uuid().v4(),
      role: ChatRole.user,
      content: trimmed,
      timestamp: DateTime.now(),
    );
    _chatMessages = [..._chatMessages, userMsg];
    _isAiTyping = true;
    notifyListeners();

    try {
      final response = await GroqChatService.instance.sendMessage(
        trimmed,
        _inventory,
        _language,
      );
      _chatMessages = [..._chatMessages, response];
    } catch (e) {
      _lastFailedUserMessage = trimmed;
      _chatError = _normalizeChatError(e);
      debugPrint('sendChatMessage: $e');
    } finally {
      _isAiTyping = false;
      notifyListeners();
    }
  }

  Future<void> retryLastChatMessage() async {
    final failed = _lastFailedUserMessage;
    if (failed == null || failed.isEmpty || _isAiTyping) return;

    _chatMessages = _chatMessages
        .where((m) => !(m.role == ChatRole.user && m.content == failed))
        .toList();
    notifyListeners();
    await sendChatMessage(failed);
  }

  String _normalizeChatError(Object error) {
    final raw = error.toString();
    final clean = raw.replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
    if (clean.toLowerCase().contains('timed out')) {
      return 'timeout';
    }
    if (clean.toLowerCase().contains('api key')) {
      return 'api_key_missing';
    }
    return clean;
  }

  void clearChat() {
    GroqChatService.instance.clearHistory();
    _chatMessages = [];
    _chatError = null;
    _lastFailedUserMessage = null;
    notifyListeners();
  }

  // ── Default data ───────────────────────────────────────────────────────────
  List<FoodItem> _defaultInventory() {
    final now = SimulatedClock.now;
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
