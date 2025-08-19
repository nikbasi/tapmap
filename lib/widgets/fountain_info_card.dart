import 'package:flutter/material.dart';
import 'package:water_fountain_finder/models/local_fountain.dart';
import 'package:water_fountain_finder/utils/constants.dart';

class FountainInfoCard extends StatelessWidget {
  final LocalFountain fountain;
  final VoidCallback onClose;

  const FountainInfoCard({
    super.key,
    required this.fountain,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with close button
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSizes.radiusL),
                topRight: Radius.circular(AppSizes.radiusL),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getFountainIcon(fountain.type),
                  color: _getFountainColor(fountain.type),
                  size: 24,
                ),
                const SizedBox(width: AppSizes.paddingS),
                Expanded(
                  child: Text(
                    fountain.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(
                    Icons.close,
                    size: 20,
                    color: Colors.grey,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                if (fountain.description.isNotEmpty) ...[
                  Text(
                    fountain.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.paddingM),
                ],

                // Fountain details
                Row(
                  children: [
                    _buildDetailChip(
                      icon: Icons.category,
                      label: fountain.typeDisplayName,
                      color: _getFountainColor(fountain.type),
                    ),
                    const SizedBox(width: AppSizes.paddingS),
                    _buildDetailChip(
                      icon: Icons.water_drop,
                      label: fountain.waterQualityDisplayName,
                      color: _getWaterQualityColor(fountain.waterQuality),
                    ),
                  ],
                ),

                const SizedBox(height: AppSizes.paddingS),

                Row(
                  children: [
                    _buildDetailChip(
                      icon: Icons.accessibility,
                      label: fountain.accessibilityDisplayName,
                      color: _getAccessibilityColor(fountain.accessibility),
                    ),
                    const SizedBox(width: AppSizes.paddingS),
                    _buildDetailChip(
                      icon: Icons.info,
                      label: fountain.statusDisplayName,
                      color: _getStatusColor(fountain.status),
                    ),
                  ],
                ),

                // Tags
                if (fountain.tags.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.paddingM),
                  Wrap(
                    spacing: AppSizes.paddingS,
                    runSpacing: AppSizes.paddingS,
                    children: fountain.tags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.paddingS,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSizes.radiusS),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],



                // Action buttons
                const SizedBox(height: AppSizes.paddingM),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Navigate to fountain details
                        },
                        icon: const Icon(Icons.info_outline, size: 18),
                        label: const Text('Details'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          side: BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingS),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Navigate to fountain
                        },
                        icon: const Icon(Icons.directions, size: 18),
                        label: const Text('Directions'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingS,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFountainIcon(LocalFountainType type) {
    switch (type) {
      case LocalFountainType.fountain:
        return Icons.water_drop;
      case LocalFountainType.tap:
        return Icons.tap_and_play;
      case LocalFountainType.refillStation:
        return Icons.local_drink;
    }
  }

  Color _getFountainColor(LocalFountainType type) {
    switch (type) {
      case LocalFountainType.fountain:
        return AppColors.fountainBlue;
      case LocalFountainType.tap:
        return AppColors.tapBlue;
      case LocalFountainType.refillStation:
        return AppColors.waterBlue;
    }
  }

  Color _getWaterQualityColor(LocalWaterQuality quality) {
    switch (quality) {
      case LocalWaterQuality.potable:
        return AppColors.success;
      case LocalWaterQuality.nonPotable:
        return AppColors.warning;
      case LocalWaterQuality.unknown:
        return AppColors.info;
    }
  }

  Color _getAccessibilityColor(LocalAccessibility accessibility) {
    switch (accessibility) {
      case LocalAccessibility.public:
        return AppColors.success;
      case LocalAccessibility.restricted:
        return AppColors.warning;
      case LocalAccessibility.private:
        return AppColors.error;
    }
  }

  Color _getStatusColor(LocalFountainStatus status) {
    switch (status) {
      case LocalFountainStatus.active:
        return AppColors.success;
      case LocalFountainStatus.inactive:
        return AppColors.error;
      case LocalFountainStatus.maintenance:
        return AppColors.warning;
    }
  }
}
