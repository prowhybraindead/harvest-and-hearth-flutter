import 'package:flutter/material.dart';
import '../models/food_item.dart';

enum CategoryTier1 { produce, protein, pantry, beverage, snack, other }

class CategoryInfo {
  final FoodCategory category;
  final CategoryTier1 tier1;
  final IconData icon;
  final Color color;
  final String translationKey;

  const CategoryInfo({
    required this.category,
    required this.tier1,
    required this.icon,
    required this.color,
    required this.translationKey,
  });
}

class AppCategories {
  AppCategories._();

  static const List<CategoryInfo> all = [
    CategoryInfo(
      category: FoodCategory.vegetables,
      tier1: CategoryTier1.produce,
      icon: Icons.eco_rounded,
      color: Color(0xFF4CAF50),
      translationKey: 'cat_vegetables',
    ),
    CategoryInfo(
      category: FoodCategory.fruits,
      tier1: CategoryTier1.produce,
      icon: Icons.apple_rounded,
      color: Color(0xFFFF5722),
      translationKey: 'cat_fruits',
    ),
    CategoryInfo(
      category: FoodCategory.meat,
      tier1: CategoryTier1.protein,
      icon: Icons.set_meal_rounded,
      color: Color(0xFFF44336),
      translationKey: 'cat_meat',
    ),
    CategoryInfo(
      category: FoodCategory.dairy,
      tier1: CategoryTier1.protein,
      icon: Icons.local_drink_rounded,
      color: Color(0xFF2196F3),
      translationKey: 'cat_dairy',
    ),
    CategoryInfo(
      category: FoodCategory.seafood,
      tier1: CategoryTier1.protein,
      icon: Icons.water_rounded,
      color: Color(0xFF00BCD4),
      translationKey: 'cat_seafood',
    ),
    CategoryInfo(
      category: FoodCategory.drinks,
      tier1: CategoryTier1.beverage,
      icon: Icons.local_cafe_rounded,
      color: Color(0xFF9C27B0),
      translationKey: 'cat_drinks',
    ),
    CategoryInfo(
      category: FoodCategory.snacks,
      tier1: CategoryTier1.pantry,
      icon: Icons.cookie_rounded,
      color: Color(0xFFFF9800),
      translationKey: 'cat_snacks',
    ),
    CategoryInfo(
      category: FoodCategory.other,
      tier1: CategoryTier1.pantry,
      icon: Icons.category_rounded,
      color: Color(0xFF607D8B),
      translationKey: 'cat_other',
    ),
  ];

  static CategoryInfo forCategory(FoodCategory category) {
    return all.firstWhere(
      (c) => c.category == category,
      orElse: () => all.last,
    );
  }

  static List<CategoryInfo> byTier1(CategoryTier1 tier1) {
    return all.where((c) => c.tier1 == tier1).toList(growable: false);
  }

  static CategoryTier1 tier1Of(FoodCategory category) {
    return forCategory(category).tier1;
  }

  static String tier1TranslationKey(CategoryTier1 tier1) {
    switch (tier1) {
      case CategoryTier1.produce:
        return 'cat_t1_produce';
      case CategoryTier1.protein:
        return 'cat_t1_protein';
      case CategoryTier1.pantry:
        return 'cat_t1_pantry';
      case CategoryTier1.beverage:
        return 'cat_t1_beverage';
      case CategoryTier1.snack:
        return 'cat_t1_snack';
      case CategoryTier1.other:
        return 'cat_t1_other';
    }
  }
}
