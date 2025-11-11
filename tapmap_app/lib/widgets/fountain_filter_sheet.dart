import 'package:flutter/material.dart';
import '../models/fountain_filters.dart';

class FountainFilterSheet extends StatefulWidget {
  final FountainFilters initialFilters;
  final Function(FountainFilters) onFiltersChanged;

  const FountainFilterSheet({
    super.key,
    required this.initialFilters,
    required this.onFiltersChanged,
  });

  @override
  State<FountainFilterSheet> createState() => _FountainFilterSheetState();
}

class _FountainFilterSheetState extends State<FountainFilterSheet> {
  late FountainFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
  }

  void _toggleStatus(String status) {
    setState(() {
      final statuses = Set<String>.from(_filters.statuses ?? {});
      if (statuses.contains(status)) {
        statuses.remove(status);
      } else {
        statuses.add(status);
      }
      _filters = _filters.copyWith(statuses: statuses.isEmpty ? null : statuses);
    });
  }

  void _toggleWaterQuality(String quality) {
    setState(() {
      final qualities = Set<String>.from(_filters.waterQualities ?? {});
      if (qualities.contains(quality)) {
        qualities.remove(quality);
      } else {
        qualities.add(quality);
      }
      _filters = _filters.copyWith(
        waterQualities: qualities.isEmpty ? null : qualities,
      );
    });
  }

  void _toggleAccessibility(String accessibility) {
    setState(() {
      final accessibilities = Set<String>.from(_filters.accessibilities ?? {});
      if (accessibilities.contains(accessibility)) {
        accessibilities.remove(accessibility);
      } else {
        accessibilities.add(accessibility);
      }
      _filters = _filters.copyWith(
        accessibilities: accessibilities.isEmpty ? null : accessibilities,
      );
    });
  }

  void _toggleType(String type) {
    setState(() {
      final types = Set<String>.from(_filters.types ?? {});
      if (types.contains(type)) {
        types.remove(type);
      } else {
        types.add(type);
      }
      _filters = _filters.copyWith(types: types.isEmpty ? null : types);
    });
  }

  void _clearFilters() {
    setState(() {
      _filters = FountainFilters.empty();
    });
  }

  void _applyFilters() {
    widget.onFiltersChanged(_filters);
    Navigator.pop(context);
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16),
            const SizedBox(width: 4),
          ],
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: Colors.blue.withValues(alpha: 0.2),
      checkmarkColor: Colors.blue,
    );
  }

  Widget _buildFilterSection({
    required String title,
    required List<String> options,
    required Set<String>? selected,
    required Function(String) onToggle,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: Colors.grey[700]),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected?.contains(option) ?? false;
            return _buildFilterChip(
              label: option,
              isSelected: isSelected,
              onTap: () => onToggle(option),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filter Fountains',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_filters.hasActiveFilters)
                      TextButton(
                        onPressed: _clearFilters,
                        child: const Text('Clear All'),
                      ),
                  ],
                ),
              ),
              const Divider(),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildFilterSection(
                      title: 'Status',
                      icon: Icons.check_circle,
                      options: ['active', 'inactive'],
                      selected: _filters.statuses,
                      onToggle: _toggleStatus,
                    ),
                    _buildFilterSection(
                      title: 'Water Quality',
                      icon: Icons.water_drop,
                      options: ['potable', 'non-potable', 'unknown'],
                      selected: _filters.waterQualities,
                      onToggle: _toggleWaterQuality,
                    ),
                    _buildFilterSection(
                      title: 'Accessibility',
                      icon: Icons.accessible,
                      options: ['wheelchair', 'public', 'restricted'],
                      selected: _filters.accessibilities,
                      onToggle: _toggleAccessibility,
                    ),
                    _buildFilterSection(
                      title: 'Type',
                      icon: Icons.category,
                      options: ['fountain', 'tap', 'well'],
                      selected: _filters.types,
                      onToggle: _toggleType,
                    ),
                  ],
                ),
              ),
              // Apply button
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _applyFilters,
                        child: Text(
                          _filters.hasActiveFilters
                              ? 'Apply Filters'
                              : 'Show All',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

