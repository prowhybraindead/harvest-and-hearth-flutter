class ShoppingPlanItem {
  const ShoppingPlanItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.requiredQty,
    required this.confirmedQty,
    required this.isPurchased,
    this.planMealRefs = const [],
  });

  final String id;
  final String name;
  final String unit;
  final double requiredQty;
  final double confirmedQty;
  final bool isPurchased;
  final List<String> planMealRefs;

  ShoppingPlanItem copyWith({
    String? id,
    String? name,
    String? unit,
    double? requiredQty,
    double? confirmedQty,
    bool? isPurchased,
    List<String>? planMealRefs,
  }) {
    return ShoppingPlanItem(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      requiredQty: requiredQty ?? this.requiredQty,
      confirmedQty: confirmedQty ?? this.confirmedQty,
      isPurchased: isPurchased ?? this.isPurchased,
      planMealRefs: planMealRefs ?? this.planMealRefs,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'unit': unit,
        'requiredQty': requiredQty,
        'confirmedQty': confirmedQty,
        'isPurchased': isPurchased,
        'planMealRefs': planMealRefs,
      };

  factory ShoppingPlanItem.fromJson(Map<String, dynamic> json) {
    return ShoppingPlanItem(
      id: json['id'] as String,
      name: json['name'] as String,
      unit: json['unit'] as String,
      requiredQty: (json['requiredQty'] as num).toDouble(),
      confirmedQty: (json['confirmedQty'] as num?)?.toDouble() ?? 0,
      isPurchased: json['isPurchased'] as bool? ?? false,
      planMealRefs: List<String>.from(json['planMealRefs'] as List? ?? const []),
    );
  }
}
