class PlannedMealEntry {
  const PlannedMealEntry({
    required this.id,
    required this.recipeId,
    required this.recipeName,
    required this.sourceName,
    required this.ingredients,
    required this.period,
    required this.dayKey,
    required this.mealSlot,
  });

  final String id;
  final String recipeId;
  final String recipeName;
  final String sourceName;
  final List<String> ingredients;
  final String period; // day | week
  final String dayKey; // day | mon..sun
  final String mealSlot; // breakfast|lunch|afternoon|dinner

  PlannedMealEntry copyWith({
    String? id,
    String? recipeId,
    String? recipeName,
    String? sourceName,
    List<String>? ingredients,
    String? period,
    String? dayKey,
    String? mealSlot,
  }) {
    return PlannedMealEntry(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      recipeName: recipeName ?? this.recipeName,
      sourceName: sourceName ?? this.sourceName,
      ingredients: ingredients ?? this.ingredients,
      period: period ?? this.period,
      dayKey: dayKey ?? this.dayKey,
      mealSlot: mealSlot ?? this.mealSlot,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'recipeId': recipeId,
        'recipeName': recipeName,
        'sourceName': sourceName,
        'ingredients': ingredients,
        'period': period,
        'dayKey': dayKey,
        'mealSlot': mealSlot,
      };

  factory PlannedMealEntry.fromJson(Map<String, dynamic> json) {
    return PlannedMealEntry(
      id: json['id'] as String,
      recipeId: json['recipeId'] as String,
      recipeName: json['recipeName'] as String,
      sourceName: json['sourceName'] as String? ?? '',
      ingredients: List<String>.from(json['ingredients'] as List? ?? const []),
      period: json['period'] as String? ?? 'day',
      dayKey: json['dayKey'] as String? ?? 'day',
      mealSlot: json['mealSlot'] as String? ?? 'breakfast',
    );
  }
}
