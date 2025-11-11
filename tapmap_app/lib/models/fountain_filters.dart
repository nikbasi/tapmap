class FountainFilters {
  final Set<String>? statuses; // e.g., {'active', 'inactive'}
  final Set<String>? waterQualities; // e.g., {'potable', 'non-potable'}
  final Set<String>? accessibilities; // e.g., {'wheelchair', 'public'}
  final Set<String>? types; // e.g., {'fountain', 'tap'}

  const FountainFilters({
    this.statuses,
    this.waterQualities,
    this.accessibilities,
    this.types,
  });

  /// Create empty filters (show all)
  factory FountainFilters.empty() {
    return const FountainFilters();
  }

  /// Check if any filters are active
  bool get hasActiveFilters {
    return (statuses != null && statuses!.isNotEmpty) ||
        (waterQualities != null && waterQualities!.isNotEmpty) ||
        (accessibilities != null && accessibilities!.isNotEmpty) ||
        (types != null && types!.isNotEmpty);
  }

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      if (statuses != null && statuses!.isNotEmpty) 'statuses': statuses!.toList(),
      if (waterQualities != null && waterQualities!.isNotEmpty)
        'water_qualities': waterQualities!.toList(),
      if (accessibilities != null && accessibilities!.isNotEmpty)
        'accessibilities': accessibilities!.toList(),
      if (types != null && types!.isNotEmpty) 'types': types!.toList(),
    };
  }

  /// Create a copy with updated values
  FountainFilters copyWith({
    Set<String>? statuses,
    Set<String>? waterQualities,
    Set<String>? accessibilities,
    Set<String>? types,
  }) {
    return FountainFilters(
      statuses: statuses ?? this.statuses,
      waterQualities: waterQualities ?? this.waterQualities,
      accessibilities: accessibilities ?? this.accessibilities,
      types: types ?? this.types,
    );
  }
}

