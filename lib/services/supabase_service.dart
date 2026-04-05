import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/food_item.dart';
import '../models/recipe.dart';

/// Singleton facade over the Supabase client.
/// All database and auth operations go through here.
class SupabaseService {
  SupabaseService._();
  static final instance = SupabaseService._();

  SupabaseClient get _db => Supabase.instance.client;

  // ── Auth ──────────────────────────────────────────────────────────────────
  User? get currentUser => _db.auth.currentUser;
  Stream<AuthState> get onAuthStateChange => _db.auth.onAuthStateChange;

  Future<void> signInWithEmail(String email, String password) =>
      _db.auth.signInWithPassword(email: email, password: password);

  Future<void> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    final res = await _db.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
      emailRedirectTo: 'io.supabase.harvestandhearth://login-callback/',
    );
    if (res.user != null) {
      await upsertProfile(res.user!.id, name: name, email: email);
    }
  }

  /// Opens a browser for Google OAuth via Supabase.
  /// The redirect lands on [redirectTo] which must match the Supabase
  /// dashboard allowlist AND the AndroidManifest intent-filter scheme.
  Future<void> signInWithGoogle(String redirectTo) =>
      _db.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectTo,
      );

  Future<void> signOut() => _db.auth.signOut();

  // ── Profile ───────────────────────────────────────────────────────────────
  Future<void> upsertProfile(
    String userId, {
    String? name,
    String? email,
  }) async {
    await _db.from('profiles').upsert({
      'id': userId,
      if (email != null) 'email': email,
      if (name != null) 'name': name,
    });
  }

  Future<Map<String, dynamic>?> getProfile(String userId) =>
      _db.from('profiles').select().eq('id', userId).maybeSingle();

  Future<void> updateProfileSettings(
    String userId,
    String language,
    bool isDark,
  ) async {
    await _db.from('profiles').upsert({
      'id': userId,
      'language': language,
      'is_dark': isDark,
    });
  }

  // ── Food Items ────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getFoodItems(String userId) async {
    final res = await _db
        .from('food_items')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<void> insertFoodItem(String userId, FoodItem item) async {
    await _db.from('food_items').insert({
      'id': item.id,
      'user_id': userId,
      'name': item.name,
      'category': item.category.value,
      'storage': item.storage.value,
      'quantity': item.quantity,
      'unit': item.unit,
      'added_date': item.addedDate.toIso8601String(),
      'expiry_date': item.expiryDate?.toIso8601String(),
      'warning_days': item.warningDays,
    });
  }

  Future<void> insertFoodItems(String userId, List<FoodItem> items) async {
    await _db.from('food_items').insert(items
        .map((item) => {
              'id': item.id,
              'user_id': userId,
              'name': item.name,
              'category': item.category.value,
              'storage': item.storage.value,
              'quantity': item.quantity,
              'unit': item.unit,
              'added_date': item.addedDate.toIso8601String(),
              'expiry_date': item.expiryDate?.toIso8601String(),
              'warning_days': item.warningDays,
            })
        .toList());
  }

  Future<void> deleteFoodItem(String itemId) =>
      _db.from('food_items').delete().eq('id', itemId);

  Future<void> updateFoodItem(FoodItem item) async {
    await _db.from('food_items').update({
      'name': item.name,
      'category': item.category.value,
      'storage': item.storage.value,
      'quantity': item.quantity,
      'unit': item.unit,
      'added_date': item.addedDate.toIso8601String(),
      'expiry_date': item.expiryDate?.toIso8601String(),
      'warning_days': item.warningDays,
    }).eq('id', item.id);
  }

  // ── Saved Recipes ─────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getSavedRecipes(String userId) async {
    final res = await _db
        .from('saved_recipes')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<void> saveRecipe(String userId, Recipe recipe) async {
    await _db.from('saved_recipes').upsert(
      {
        'user_id': userId,
        'original_id': recipe.id,
        'recipe_data': recipe.toJson(),
      },
      onConflict: 'user_id,original_id',
    );
  }

  Future<void> unsaveRecipe(String userId, String originalId) => _db
      .from('saved_recipes')
      .delete()
      .eq('user_id', userId)
      .eq('original_id', originalId);
}
