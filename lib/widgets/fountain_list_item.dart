import 'package:flutter/material.dart';
import 'package:water_fountain_finder/models/fountain.dart';
import 'package:water_fountain_finder/utils/constants.dart';

class FountainListItem extends StatelessWidget {
  final Fountain fountain;
  final VoidCallback onTap;

  const FountainListItem({
    super.key,
    required this.fountain,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          child: Row(
            children: [
              // Fountain icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _getFountainColor(fountain.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
                child: Icon(
                  _getFountainIcon(fountain.type),
                  color: _getFountainColor(fountain.type),
                  size: 30,
                ),
              ),

              const SizedBox(width: AppSizes.paddingM),

              // Fountain details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      fountain.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Description
                    if (fountain.description.isNotEmpty) ...[
                      Text(
                        fountain.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                    ],

                    // Fountain info chips
                    Row(
                      children: [
                        _buildInfoChip(
                          icon: Icons.category,
                          label: fountain.typeDisplayName,
                          color: _getFountainColor(fountain.type),
                        ),
                        const SizedBox(width: 6),
                        _buildInfoChip(
                          icon: Icons.water_drop,
                          label: fountain.waterQualityDisplayName,
                          color: _getWaterQualityColor(fountain.waterQuality),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Additional info
                    Row(
                      children: [
                        Icon(
                          Icons.accessibility,
                          size: 14,
                          color: _getAccessibilityColor(fountain.accessibility),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          fountain.accessibilityDisplayName,
                          style: TextStyle(
                            fontSize: 12,
                            color: _getAccessibilityColor(fountain.accessibility),
                          ),
                        ),
                        const Spacer(),
                        if (fountain.rating != null) ...[
                          Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.amber.shade600,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            fountain.rating!.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow icon
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
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
            size: 12,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFountainIcon(FountainType type) {
    switch (type) {
      case FountainType.fountain:
        return Icons.water_drop;
      case FountainType.tap:
        return Icons.tap_and_play;
      case FountainType.refillStation:
        return Icons.local_drink;
    }
  }

  Color _getFountainColor(FountainType type) {
    switch (type) {
      case FountainType.fountain:
        return AppColors.fountainBlue;
      case FountainType.tap:
        return AppColors.tapBlue;
      case FountainType.refillStation:
        return AppColors.waterBlue;
    }
  }

  Color _getWaterQualityColor(WaterQuality quality) {
    switch (quality) {
      case WaterQuality.potable:
        return AppColors.success;
      case WaterQuality.nonPotable:
        return AppColors.warning;
      case WaterQuality.unknown:
        return AppColors.info;
    }
  }

  Color _getAccessibilityColor(Accessibility accessibility) {
    switch (accessibility) {
      case Accessibility.public:
        return AppColors.success;
      case Accessibility.restricted:
        return AppColors.warning;
      case Accessibility.private:
        return AppColors.error;
    }
  }
}
