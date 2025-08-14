import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:water_fountain_finder/utils/constants.dart';

class DatabaseViewer extends StatefulWidget {
  const DatabaseViewer({super.key});

  @override
  State<DatabaseViewer> createState() => _DatabaseViewerState();
}

class _DatabaseViewerState extends State<DatabaseViewer> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  Map<String, List<Map<String, dynamic>>> _collections = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDatabaseData();
  }

  Future<void> _loadDatabaseData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load users collection
      final usersSnapshot = await _firestore.collection('users').limit(10).get();
      final users = usersSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Load fountains collection
      final fountainsSnapshot = await _firestore.collection('fountains').limit(10).get();
      final fountains = fountainsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      setState(() {
        _collections = {
          'users': users,
          'fountains': fountains,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load database: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Viewer'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadDatabaseData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: AppSizes.paddingM),
                      Text(
                        'Error',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingS),
                      Text(
                        _error!,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSizes.paddingL),
                      ElevatedButton(
                        onPressed: _loadDatabaseData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSizes.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Database Collections',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingL),
                      ..._collections.entries.map((entry) => _buildCollectionCard(entry.key, entry.value)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildCollectionCard(String collectionName, List<Map<String, dynamic>> documents) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingM),
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(
              collectionName == 'users' ? Icons.people : Icons.map,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSizes.paddingS),
            Text(
              collectionName.toUpperCase(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: AppSizes.paddingS),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${documents.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        children: documents.map((doc) => _buildDocumentTile(doc)).toList(),
      ),
    );
  }

  Widget _buildDocumentTile(Map<String, dynamic> document) {
    return ListTile(
      title: Text(
        document['id'] ?? 'No ID',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: document.entries
            .where((entry) => entry.key != 'id')
            .take(3)
            .map((entry) => Text(
                  '${entry.key}: ${_formatValue(entry.value)}',
                  style: const TextStyle(fontSize: 12),
                ))
            .toList(),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.visibility),
        onPressed: () => _showDocumentDetails(document),
      ),
    );
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'null';
    if (value is Timestamp) return value.toDate().toString();
    if (value is List) return '[${value.length} items]';
    if (value is Map) return '{${value.length} fields}';
    return value.toString();
  }

  void _showDocumentDetails(Map<String, dynamic> document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Document: ${document['id'] ?? 'No ID'}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: document.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      _formatValue(entry.value),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const Divider(),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

