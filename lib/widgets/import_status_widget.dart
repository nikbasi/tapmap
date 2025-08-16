import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/import_utils.dart';

class ImportStatusWidget extends StatelessWidget {
  const ImportStatusWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_download, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Italian Fountains Import',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                StreamBuilder<QuerySnapshot>(
                  stream: ImportUtils.getItalianFountainsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final count = snapshot.data!.docs.length;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$count fountains',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, dynamic>>(
              future: ImportUtils.getImportStatistics(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Text(
                    'Error loading statistics: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  );
                }
                
                final stats = snapshot.data!;
                if (stats.containsKey('error')) {
                  return Text(
                    'Error: ${stats['error']}',
                    style: const TextStyle(color: Colors.red),
                  );
                }
                
                return Column(
                  children: [
                    _buildStatRow('Total Fountains', '${stats['totalFountains']}'),
                    const SizedBox(height: 8),
                    _buildTypeDistribution(stats['typeDistribution']),
                    const SizedBox(height: 8),
                    _buildRegionDistribution(stats['regionDistribution']),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            const Divider(),
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'These fountains were imported from OpenStreetMap data covering all of Italy. '
                    'They include traditional fountains, water taps, and refill stations.',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }
  
  Widget _buildTypeDistribution(Map<String, dynamic> typeCounts) {
    if (typeCounts.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'By Type:',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        ...typeCounts.entries.map((entry) {
          final type = entry.key.replaceAll('_', ' ').toUpperCase();
          final count = entry.value;
          return Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 2),
            child: Text('$type: $count'),
          );
        }),
      ],
    );
  }
  
  Widget _buildRegionDistribution(Map<String, dynamic> regionCounts) {
    if (regionCounts.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'By Region:',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        ...regionCounts.entries.map((entry) {
          final region = entry.key;
          final count = entry.value;
          return Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 2),
            child: Text('$region: $count'),
          );
        }),
      ],
    );
  }
}


