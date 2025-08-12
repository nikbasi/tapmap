import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:water_fountain_finder/providers/fountain_provider.dart';
import 'package:water_fountain_finder/models/fountain.dart';
import 'package:water_fountain_finder/utils/constants.dart';
import 'package:water_fountain_finder/widgets/fountain_list_item.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _selectedTags = [];
  FountainType? _selectedType;
  WaterQuality? _selectedWaterQuality;
  Accessibility? _selectedAccessibility;
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final fountainProvider = Provider.of<FountainProvider>(context, listen: false);
    fountainProvider.searchFountains(query);
  }

  void _applyFilters() {
    final fountainProvider = Provider.of<FountainProvider>(context, listen: false);
    final filters = <String, dynamic>{};

    if (_selectedType != null) {
      filters['type'] = _selectedType!.name;
    }
    if (_selectedWaterQuality != null) {
      filters['waterQuality'] = _selectedWaterQuality!.name;
    }
    if (_selectedAccessibility != null) {
      filters['accessibility'] = _selectedAccessibility!.name;
    }
    if (_selectedTags.isNotEmpty) {
      filters['tags'] = _selectedTags;
    }

    fountainProvider.applyFilters(filters);
  }

  void _clearFilters() {
    setState(() {
      _selectedTags.clear();
      _selectedType = null;
      _selectedWaterQuality = null;
      _selectedAccessibility = null;
    });

    final fountainProvider = Provider.of<FountainProvider>(context, listen: false);
    fountainProvider.clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.search),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search fountains...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                  icon: const Icon(Icons.clear),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusL),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),

          // Filter toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showFilters = !_showFilters;
                    });
                  },
                  icon: Icon(
                    _showFilters ? Icons.expand_less : Icons.expand_more,
                  ),
                  label: Text(_showFilters ? 'Hide Filters' : 'Show Filters'),
                ),
                const Spacer(),
                if (_showFilters)
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear All'),
                  ),
              ],
            ),
          ),

          // Filters
          if (_showFilters) _buildFilters(),

          // Results
          Expanded(
            child: Consumer<FountainProvider>(
              builder: (context, fountainProvider, child) {
                if (fountainProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (fountainProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: AppSizes.paddingM),
                        Text(
                          fountainProvider.error!,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSizes.paddingM),
                        ElevatedButton(
                          onPressed: () => fountainProvider.refresh(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final fountains = fountainProvider.searchQuery.isNotEmpty
                    ? fountainProvider.filteredFountains
                    : fountainProvider.fountains;

                if (fountains.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: AppSizes.paddingM),
                        Text(
                          fountainProvider.searchQuery.isNotEmpty
                              ? 'No fountains found for "${fountainProvider.searchQuery}"'
                              : 'No fountains available',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => fountainProvider.refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSizes.paddingM),
                    itemCount: fountains.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSizes.paddingM),
                        child: FountainListItem(
                          fountain: fountains[index],
                          onTap: () {
                            // TODO: Navigate to fountain details
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
      padding: const EdgeInsets.all(AppSizes.paddingM),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type filter
          _buildFilterSection(
            title: 'Type',
            children: FountainType.values.map((type) {
              return FilterChip(
                label: Text(type.displayName),
                selected: _selectedType == type,
                onSelected: (selected) {
                  setState(() {
                    _selectedType = selected ? type : null;
                  });
                  _applyFilters();
                },
              );
            }).toList(),
          ),

          const SizedBox(height: AppSizes.paddingM),

          // Water quality filter
          _buildFilterSection(
            title: 'Water Quality',
            children: WaterQuality.values.map((quality) {
              return FilterChip(
                label: Text(quality.displayName),
                selected: _selectedWaterQuality == quality,
                onSelected: (selected) {
                  setState(() {
                    _selectedWaterQuality = selected ? quality : null;
                  });
                  _applyFilters();
                },
              );
            }).toList(),
          ),

          const SizedBox(height: AppSizes.paddingM),

          // Accessibility filter
          _buildFilterSection(
            title: 'Accessibility',
            children: Accessibility.values.map((accessibility) {
              return FilterChip(
                label: Text(accessibility.displayName),
                selected: _selectedAccessibility == accessibility,
                onSelected: (selected) {
                  setState(() {
                    _selectedAccessibility = selected ? accessibility : null;
                  });
                  _applyFilters();
                },
              );
            }).toList(),
          ),

          const SizedBox(height: AppSizes.paddingM),

          // Tags filter
          _buildFilterSection(
            title: 'Tags',
            children: [
              '24h',
              'wheelchair_accessible',
              'cold_water',
              'hot_water',
              'filtered',
              'bottle_fill',
            ].map((tag) {
              return FilterChip(
                label: Text(tag.replaceAll('_', ' ')),
                selected: _selectedTags.contains(tag),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTags.add(tag);
                    } else {
                      _selectedTags.remove(tag);
                    }
                  });
                  _applyFilters();
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: AppSizes.paddingS),
        Wrap(
          spacing: AppSizes.paddingS,
          runSpacing: AppSizes.paddingS,
          children: children,
        ),
      ],
    );
  }
}
