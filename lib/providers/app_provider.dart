import 'dart:async';
import 'dart:convert';

import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../core/simulated_clock.dart';
import '../models/chat_message.dart';
import '../models/food_item.dart';
import '../models/planned_meal_entry.dart';
import '../models/recipe.dart';
import '../models/shopping_plan_item.dart';
import '../models/user.dart';
import '../constants/translations.dart';
import '../services/backend_api_service.dart';
import '../services/expiry_reminder_service.dart';
import '../services/groq_chat_service.dart';
import '../services/home_widget_service.dart';
import '../services/translate_service.dart';

const _uuid = Uuid();
const _chatCacheTtl = Duration(minutes: 20);
const _chatSimilarityThreshold = 0.72;

class _ChatCacheEntry {
  final String normalizedPrompt;
  final String inventoryFingerprint;
  final String language;
  final String response;
  final DateTime createdAt;

  const _ChatCacheEntry({
    required this.normalizedPrompt,
    required this.inventoryFingerprint,
    required this.language,
    required this.response,
    required this.createdAt,
  });
}

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
  Map<String, int> _defaultExpiryDaysByCategory = {};
  List<ShoppingPlanItem> _shoppingPlanItems = [];
  List<PlannedMealEntry> _plannedMeals = [];
  String _shoppingPlanPeriod = 'day';
  DateTime? _shoppingPlanSavedAt;

  // ── Chat State ─────────────────────────────────────────────────────────────
  List<ChatMessage> _chatMessages = [];
  bool _isAiTyping = false;
  String? _chatError;
  String? _lastFailedUserMessage;
  final List<_ChatCacheEntry> _chatCache = [];

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
  Map<String, int> get defaultExpiryDaysByCategory =>
      Map.unmodifiable(_defaultExpiryDaysByCategory);
  List<ShoppingPlanItem> get shoppingPlanItems =>
      List.unmodifiable(_shoppingPlanItems);
  List<PlannedMealEntry> get plannedMeals => List.unmodifiable(_plannedMeals);
  List<PlannedMealEntry> get plannedMealsForActivePeriod => _plannedMeals
      .where((e) => e.period == _shoppingPlanPeriod)
      .toList(growable: false);
  String get shoppingPlanPeriod => _shoppingPlanPeriod;
  DateTime? get shoppingPlanSavedAt => _shoppingPlanSavedAt;
  int get shoppingPurchasedCount =>
      _shoppingPlanItems.where((e) => e.isPurchased).length;
  int get shoppingTotalCount => _shoppingPlanItems.length;
  bool get isDemoMode =>
      (dotenv.maybeGet('DEMO_MODE') ?? 'false').toLowerCase() == 'true';

  // Chat getters
  List<ChatMessage> get chatMessages => List.unmodifiable(_chatMessages);
  bool get isAiTyping => _isAiTyping;
  String? get chatError => _chatError;
  bool get canRetryLastChat =>
      _lastFailedUserMessage != null && _lastFailedUserMessage!.isNotEmpty;
  bool get canRegenerate =>
      _chatMessages.any((m) => m.role == ChatRole.user) && !_isAiTyping;
  List<String> get chatQuickPrompts =>
      GroqChatService.instance.getQuickPrompts(_language, _inventory);
  List<String> get frequentIngredientNames {
    final counts = <String, int>{};
    for (final item in _inventory) {
      final key = item.name.trim().toLowerCase();
      if (key.isEmpty) continue;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(12).map((e) => e.key).toList();
  }

  String t(String key) => Translations.get(key, _language);

  // ── Init ───────────────────────────────────────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _language = prefs.getString('language') ?? 'VIE';
    _isDark = prefs.getBool('isDark') ?? false;
    _expiryRemindersEnabled =
        prefs.getBool(ExpiryReminderService.prefsKeyEnabled) ?? true;
    final rawDefaults = prefs.getString('default_expiry_days_by_category');
    if (rawDefaults != null && rawDefaults.trim().isNotEmpty) {
      try {
        final parsed = jsonDecode(rawDefaults) as Map<String, dynamic>;
        _defaultExpiryDaysByCategory = parsed.map(
          (k, v) => MapEntry(k, (v as num).toInt()),
        );
      } catch (_) {
        _defaultExpiryDaysByCategory = {};
      }
    }
    final rawPlan = prefs.getString('shopping_plan_items');
    if (rawPlan != null && rawPlan.trim().isNotEmpty) {
      try {
        final parsed = jsonDecode(rawPlan) as List<dynamic>;
        _shoppingPlanItems = parsed
            .map((e) => ShoppingPlanItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (_) {
        _shoppingPlanItems = [];
      }
    }
    final rawMeals = prefs.getString('shopping_planned_meals');
    if (rawMeals != null && rawMeals.trim().isNotEmpty) {
      try {
        final parsed = jsonDecode(rawMeals) as List<dynamic>;
        _plannedMeals = parsed
            .map((e) => PlannedMealEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (_) {
        _plannedMeals = [];
      }
    }
    _shoppingPlanPeriod = prefs.getString('shopping_plan_period') ?? 'day';
    final rawSavedAt = prefs.getString('shopping_plan_saved_at');
    if (rawSavedAt != null && rawSavedAt.trim().isNotEmpty) {
      try {
        _shoppingPlanSavedAt = DateTime.parse(rawSavedAt);
      } catch (_) {
        _shoppingPlanSavedAt = null;
      }
    }
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
    await ExpiryReminderService.instance.syncInventory(
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
    _shoppingPlanItems = [];
    _plannedMeals = [];
    _shoppingPlanPeriod = 'day';
    _shoppingPlanSavedAt = null;
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
    final itemRows =
        await BackendApiService.instance.getFoodItems(clerkUser.id);
    final recipeRows = await _safeApiCall<List<Map<String, dynamic>>>(
          'getSavedRecipes',
          () => BackendApiService.instance.getSavedRecipes(clerkUser.id),
        ) ??
        const <Map<String, dynamic>>[];
    final notificationRows = await _safeApiCall<List<Map<String, dynamic>>>(
          'getNotificationLogs',
          () => BackendApiService.instance.getNotificationLogs(limit: 500),
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
      _notificationLogs =
          await BackendApiService.instance.getNotificationLogs(limit: 500);
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

  List<FoodItem> get pantryItems =>
      _inventory.where((e) => e.storage == StorageType.pantry).toList();

  List<FoodItem> get expiredItems =>
      _inventory.where((e) => e.isExpired).toList();

  List<FoodItem> get expiringSoonItems =>
      _inventory.where((e) => e.isExpiringSoon && !e.isExpired).toList();

  int defaultExpiryDaysFor(FoodCategory category) {
    return _defaultExpiryDaysByCategory[category.value] ?? 7;
  }

  Future<void> setDefaultExpiryDaysFor(
    FoodCategory category,
    int days,
  ) async {
    final clamped = days.clamp(0, 365);
    _defaultExpiryDaysByCategory[category.value] = clamped;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'default_expiry_days_by_category',
      jsonEncode(_defaultExpiryDaysByCategory),
    );
  }

  Future<void> generateShoppingPlan({required bool weekly}) async {
    _shoppingPlanPeriod = weekly ? 'week' : 'day';
    final factor = weekly ? 7.0 : 1.0;

    final availableByCategory = <FoodCategory, double>{};
    for (final item in _inventory) {
      if (item.isExpired) continue;
      final normalizedQty = _normalizedQtyForPlan(item);
      availableByCategory[item.category] =
          (availableByCategory[item.category] ?? 0) + normalizedQty;
    }

    final targets = <FoodCategory, ({double qty, String itemName, String unit})>{
      FoodCategory.vegetables: (
        qty: 4 * factor,
        itemName: _language == 'ENG' ? 'Vegetables mix' : 'Rau củ tổng hợp',
        unit: _language == 'ENG' ? 'servings' : 'phần',
      ),
      FoodCategory.fruits: (
        qty: 2 * factor,
        itemName: _language == 'ENG' ? 'Fresh fruits' : 'Trái cây tươi',
        unit: _language == 'ENG' ? 'servings' : 'phần',
      ),
      FoodCategory.meat: (
        qty: 1.2 * factor,
        itemName: _language == 'ENG' ? 'Meat / poultry' : 'Thịt / gia cầm',
        unit: _language == 'ENG' ? 'kg' : 'kg',
      ),
      FoodCategory.seafood: (
        qty: 0.8 * factor,
        itemName: _language == 'ENG' ? 'Seafood' : 'Hải sản',
        unit: _language == 'ENG' ? 'kg' : 'kg',
      ),
      FoodCategory.dairy: (
        qty: 7 * factor,
        itemName: _language == 'ENG' ? 'Milk / eggs' : 'Sữa / trứng',
        unit: _language == 'ENG' ? 'units' : 'đơn vị',
      ),
      FoodCategory.drinks: (
        qty: 7 * factor,
        itemName: _language == 'ENG' ? 'Drinks' : 'Đồ uống',
        unit: _language == 'ENG' ? 'units' : 'đơn vị',
      ),
      FoodCategory.snacks: (
        qty: 3 * factor,
        itemName: _language == 'ENG' ? 'Healthy snacks' : 'Đồ ăn nhẹ',
        unit: _language == 'ENG' ? 'packs' : 'gói',
      ),
      FoodCategory.other: (
        qty: 3 * factor,
        itemName: _language == 'ENG' ? 'Pantry essentials' : 'Gia vị cơ bản',
        unit: _language == 'ENG' ? 'units' : 'đơn vị',
      ),
    };

    final next = <ShoppingPlanItem>[];
    for (final entry in targets.entries) {
      final available = availableByCategory[entry.key] ?? 0;
      final deficit = (entry.value.qty - available);
      if (deficit <= 0) continue;
      next.add(
        ShoppingPlanItem(
          id: _uuid.v4(),
          name: entry.value.itemName,
          unit: entry.value.unit,
          requiredQty: _roundQty(deficit),
          confirmedQty: _roundQty(deficit),
          isPurchased: false,
        ),
      );
    }

    _shoppingPlanItems = next;
    notifyListeners();
    await _persistShoppingPlan();
  }

  Future<void> addPlannedMeal({
    required Recipe recipe,
    required String mealSlot,
    required String dayKey,
  }) async {
    _plannedMeals.add(
      PlannedMealEntry(
        id: _uuid.v4(),
        recipeId: recipe.id,
        recipeName: recipe.name,
        sourceName: recipe.sourceName,
        ingredients: recipe.ingredientsNeeded,
        period: _shoppingPlanPeriod,
        dayKey: dayKey,
        mealSlot: mealSlot,
      ),
    );
    notifyListeners();
    await _persistShoppingPlan();
  }

  Future<void> removePlannedMeal(String id) async {
    _plannedMeals.removeWhere((e) => e.id == id);
    notifyListeners();
    await _persistShoppingPlan();
  }

  Future<void> clearPlannedMealsForActivePeriod() async {
    _plannedMeals.removeWhere((e) => e.period == _shoppingPlanPeriod);
    notifyListeners();
    await _persistShoppingPlan();
  }

  Future<void> saveShoppingDraft() async {
    await _generateShoppingListFromPlannedMeals();
    _shoppingPlanSavedAt = DateTime.now();
    notifyListeners();
    await _persistShoppingPlan();
  }

  Future<void> setShoppingConfirmedQty(String id, double qty) async {
    final index = _shoppingPlanItems.indexWhere((e) => e.id == id);
    if (index == -1) return;
    final safeQty = qty < 0 ? 0.0 : _roundQty(qty);
    _shoppingPlanItems[index] =
        _shoppingPlanItems[index].copyWith(confirmedQty: safeQty);
    notifyListeners();
    await _persistShoppingPlan();
  }

  Future<void> setShoppingPurchased(String id, bool purchased) async {
    final index = _shoppingPlanItems.indexWhere((e) => e.id == id);
    if (index == -1) return;
    _shoppingPlanItems[index] =
        _shoppingPlanItems[index].copyWith(isPurchased: purchased);
    notifyListeners();
    await _persistShoppingPlan();
  }

  Future<void> clearShoppingPlan() async {
    _shoppingPlanItems = [];
    _shoppingPlanSavedAt = null;
    notifyListeners();
    await _persistShoppingPlan();
  }

  Future<void> addPurchasedItemsToInventory() async {
    final purchased = _shoppingPlanItems
        .where((e) => e.isPurchased && e.confirmedQty > 0)
        .toList(growable: false);
    if (purchased.isEmpty) return;

    final now = SimulatedClock.now;
    final itemsToAdd = <FoodItem>[];
    for (final e in purchased) {
      final normalizedName = await _normalizeIngredientNameForDisplay(e.name);
      final classified = await _classifyPurchasedItemWithAi(normalizedName);
      final planRef = e.planMealRefs.isEmpty
          ? (_language == 'VIE' ? 'Từ shopping plan' : 'From shopping plan')
          : e.planMealRefs.take(2).join(' · ');
      itemsToAdd.add(
        FoodItem(
          id: _uuid.v4(),
          name: normalizedName,
          category: classified.$1,
          storage: classified.$2,
          quantity: e.confirmedQty,
          unit: e.unit,
          addedDate: now,
          expiryDate: null,
          warningDays: 3,
          fromShoppingPlan: true,
          shoppingPlanMealNames: e.planMealRefs,
          planSourceLabel: planRef,
        ),
      );
    }

    _inventory = [...itemsToAdd, ..._inventory];
    final purchasedIds = purchased.map((e) => e.id).toSet();
    _shoppingPlanItems =
        _shoppingPlanItems.where((e) => !purchasedIds.contains(e.id)).toList();
    notifyListeners();

    if (_user != null && BackendApiService.instance.isConfigured) {
      try {
        await BackendApiService.instance.insertFoodItems(_user!.id, itemsToAdd);
      } catch (e, st) {
        debugPrint('addPurchasedItemsToInventory: $e\n$st');
      }
    }

    await _persistShoppingPlan();
    _scheduleAlerts();
  }

  Future<int> importShoppingPlanFromChat(String chatContent) async {
    final lines = chatContent.split(RegExp(r'\r?\n'));
    final parsed = <ShoppingPlanItem>[];

    for (final raw in lines) {
      final line = raw.trim();
      if (!line.startsWith('-') && !line.startsWith('•')) continue;
      final clean = line.replaceFirst(RegExp(r'^[-•]\s*'), '').trim();
      if (clean.isEmpty) continue;

      final match = RegExp(
        r'(?:(\d+(?:[.,]\d+)?)\s*)?([a-zA-ZÀ-ỹđĐ%]+)?\s*(.+)$',
      ).firstMatch(clean);
      if (match == null) continue;

      final qtyRaw = (match.group(1) ?? '').replaceAll(',', '.');
      final qty = double.tryParse(qtyRaw) ?? 1.0;
      final unitCandidate = (match.group(2) ?? '').trim();
      final name = (match.group(3) ?? clean).trim();
      if (name.length < 2) continue;

      final unit = unitCandidate.isEmpty ? (_language == 'ENG' ? 'units' : 'đơn vị') : unitCandidate;
      parsed.add(
        ShoppingPlanItem(
          id: _uuid.v4(),
          name: name,
          unit: unit,
          requiredQty: _roundQty(qty),
          confirmedQty: _roundQty(qty),
          isPurchased: false,
        ),
      );
    }

    if (parsed.isEmpty) return 0;

    _shoppingPlanItems = [...parsed, ..._shoppingPlanItems];
    notifyListeners();
    await _persistShoppingPlan();
    return parsed.length;
  }

  double _normalizedQtyForPlan(FoodItem item) {
    final unit = item.unit.trim().toLowerCase();
    if (unit == 'kg' || unit == 'kilogram' || unit == 'kilograms') {
      return item.quantity;
    }
    if (unit == 'g' || unit == 'gram' || unit == 'grams') {
      return item.quantity / 1000;
    }
    if (unit == 'l' || unit == 'liter' || unit == 'liters') {
      return item.quantity;
    }
    if (unit == 'ml') {
      return item.quantity / 1000;
    }
    return item.quantity.clamp(0, 5).toDouble();
  }

  double _roundQty(double value) {
    return (value * 10).roundToDouble() / 10;
  }

  Future<void> _generateShoppingListFromPlannedMeals() async {
    final active = _plannedMeals
        .where((e) => e.period == _shoppingPlanPeriod)
        .toList(growable: false);
    if (active.isEmpty) {
      _shoppingPlanItems = [];
      return;
    }

    final totals = <String, double>{};
    final mealRefs = <String, Set<String>>{};
    for (final meal in active) {
      for (final ing in meal.ingredients) {
        final normalized = ing.trim();
        if (normalized.isEmpty) continue;
        totals[normalized] = (totals[normalized] ?? 0) + 1;
        mealRefs.putIfAbsent(normalized, () => <String>{}).add(meal.recipeName);
      }
    }

    _shoppingPlanItems = totals.entries
        .map(
          (e) => ShoppingPlanItem(
            id: _uuid.v4(),
            name: e.key,
            unit: _language == 'ENG' ? 'portion' : 'phần',
            requiredQty: _roundQty(e.value),
            confirmedQty: _roundQty(e.value),
            isPurchased: false,
            planMealRefs: (mealRefs[e.key] ?? const <String>{}).toList(),
          ),
        )
        .toList(growable: false);
  }

  Future<String> _normalizeIngredientNameForDisplay(String name) async {
    final raw = name.trim();
    if (raw.isEmpty) return raw;
    if (_language != 'VIE') return raw;
    if (_looksVietnamese(raw)) return raw;
    final translated = await TranslateService.instance.translate(raw, 'VIE');
    return translated.trim().isEmpty ? raw : translated.trim();
  }

  bool _looksVietnamese(String text) {
    return RegExp(
      r'[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđĐ]',
    ).hasMatch(text);
  }

  (FoodCategory, StorageType) _classifyPurchasedItem(String input) {
    final s = input.toLowerCase();

    bool hasAny(List<String> keys) => keys.any(s.contains);

    if (hasAny([
      'thịt',
      'bò',
      'heo',
      'gà',
      'duck',
      'beef',
      'pork',
      'chicken'
    ])) {
      return (FoodCategory.meat, StorageType.freezer);
    }
    if (hasAny(['cá', 'tôm', 'mực', 'hải sản', 'fish', 'shrimp', 'seafood'])) {
      return (FoodCategory.seafood, StorageType.freezer);
    }
    if (hasAny(['sữa', 'phô mai', 'yaourt', 'yogurt', 'egg', 'trứng'])) {
      return (FoodCategory.dairy, StorageType.fridge);
    }
    if (hasAny(['rau', 'xà lách', 'cải', 'cà chua', 'vegetable'])) {
      return (FoodCategory.vegetables, StorageType.fridge);
    }
    if (hasAny(['táo', 'chuối', 'cam', 'fruit', 'trái cây'])) {
      return (FoodCategory.fruits, StorageType.fridge);
    }
    if (hasAny(['nước', 'soda', 'juice', 'drink'])) {
      return (FoodCategory.drinks, StorageType.fridge);
    }
    if (hasAny(['snack', 'bánh', 'kẹo', 'hạt'])) {
      return (FoodCategory.snacks, StorageType.pantry);
    }
    return (FoodCategory.other, StorageType.pantry);
  }

  Future<(FoodCategory, StorageType)> _classifyPurchasedItemWithAi(
    String input,
  ) async {
    final ai = await GroqChatService.instance
        .classifyPurchasedIngredient(input, _language);
    if (ai != null) {
      final category = FoodCategoryX.fromString(ai.category);
      final storage = StorageTypeX.fromString(ai.storage);
      return (category, storage);
    }
    return _classifyPurchasedItem(input);
  }

  Future<void> _persistShoppingPlan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'shopping_plan_items',
      jsonEncode(_shoppingPlanItems.map((e) => e.toJson()).toList()),
    );
    await prefs.setString('shopping_plan_period', _shoppingPlanPeriod);
    await prefs.setString(
      'shopping_planned_meals',
      jsonEncode(_plannedMeals.map((e) => e.toJson()).toList()),
    );
    if (_shoppingPlanSavedAt != null) {
      await prefs.setString(
        'shopping_plan_saved_at',
        _shoppingPlanSavedAt!.toIso8601String(),
      );
    } else {
      await prefs.remove('shopping_plan_saved_at');
    }
  }

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
  Future<void> sendChatMessage(
    String message, {
    bool displayUserMessage = true,
    bool forceRefresh = false,
    bool preferAlternative = false,
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty || _isAiTyping) return;

    _chatError = null;
    _lastFailedUserMessage = null;
    if (displayUserMessage) {
      final userMsg = ChatMessage(
        id: const Uuid().v4(),
        role: ChatRole.user,
        content: trimmed,
        timestamp: DateTime.now(),
      );
      _chatMessages = [..._chatMessages, userMsg];
    }
    _isAiTyping = true;
    notifyListeners();

    try {
      final inputFingerprint = _inventoryFingerprint();
      final normalizedPrompt = _normalizePrompt(trimmed);

      if (!forceRefresh) {
        final cached = _findCachedResponse(
          normalizedPrompt: normalizedPrompt,
          inventoryFingerprint: inputFingerprint,
          language: _language,
        );
        if (cached != null) {
          _chatMessages = [
            ..._chatMessages,
            ChatMessage(
              id: const Uuid().v4(),
              role: ChatRole.assistant,
              content: cached,
              timestamp: DateTime.now(),
            ),
          ];
          return;
        }
      }

      final outbound =
          preferAlternative ? _alternativePrompt(trimmed, _language) : trimmed;
      final response = await GroqChatService.instance.sendMessage(
        outbound,
        _inventory,
        _language,
      );
      _chatMessages = [..._chatMessages, response];
      _rememberChatResponse(
        normalizedPrompt: normalizedPrompt,
        inventoryFingerprint: inputFingerprint,
        language: _language,
        response: response.content,
      );
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

  Future<void> regenerateLastChatResponse() async {
    if (_isAiTyping) return;
    final lastUser = _chatMessages.lastWhere(
      (m) => m.role == ChatRole.user,
      orElse: () => ChatMessage(
        id: '',
        role: ChatRole.user,
        content: '',
        timestamp: DateTime.now(),
      ),
    );
    if (lastUser.id.isEmpty || lastUser.content.trim().isEmpty) return;
    await sendChatMessage(
      lastUser.content,
      displayUserMessage: false,
      forceRefresh: true,
      preferAlternative: true,
    );
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
    _chatCache.clear();
    notifyListeners();
  }

  String _normalizePrompt(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\sà-ỹđ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _inventoryFingerprint() {
    final sorted = _inventory
        .map((e) =>
            '${e.name.toLowerCase()}|${e.quantity}|${e.unit}|${e.category.value}|${e.storage.value}')
        .toList()
      ..sort();
    return sorted.join(';');
  }

  String? _findCachedResponse({
    required String normalizedPrompt,
    required String inventoryFingerprint,
    required String language,
  }) {
    final now = DateTime.now();
    _chatCache.removeWhere((e) => now.difference(e.createdAt) > _chatCacheTtl);

    double best = 0;
    _ChatCacheEntry? bestMatch;
    for (final entry in _chatCache) {
      if (entry.language != language ||
          entry.inventoryFingerprint != inventoryFingerprint) {
        continue;
      }
      final score =
          _jaccardSimilarity(normalizedPrompt, entry.normalizedPrompt);
      if (score > best) {
        best = score;
        bestMatch = entry;
      }
    }
    if (bestMatch == null || best < _chatSimilarityThreshold) return null;
    return bestMatch.response;
  }

  void _rememberChatResponse({
    required String normalizedPrompt,
    required String inventoryFingerprint,
    required String language,
    required String response,
  }) {
    _chatCache.add(
      _ChatCacheEntry(
        normalizedPrompt: normalizedPrompt,
        inventoryFingerprint: inventoryFingerprint,
        language: language,
        response: response,
        createdAt: DateTime.now(),
      ),
    );
    if (_chatCache.length > 40) {
      _chatCache.removeRange(0, _chatCache.length - 40);
    }
  }

  double _jaccardSimilarity(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0;
    final sa = a.split(' ').where((e) => e.isNotEmpty).toSet();
    final sb = b.split(' ').where((e) => e.isNotEmpty).toSet();
    if (sa.isEmpty || sb.isEmpty) return 0;
    final intersection = sa.intersection(sb).length.toDouble();
    final union = sa.union(sb).length.toDouble();
    if (union == 0) return 0;
    return intersection / union;
  }

  String _alternativePrompt(String base, String language) {
    if (language == 'VIE') {
      return '$base\n\nHãy đưa ra phương án KHÁC với lần trước, ưu tiên món khác hẳn và cách làm ngắn gọn hơn.';
    }
    return '$base\n\nGive a DIFFERENT option than before with noticeably different dishes and shorter steps.';
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
