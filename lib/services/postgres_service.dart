import 'dart:async';
import 'package:postgres/postgres.dart';
import 'package:flutter/foundation.dart';
import 'package:water_fountain_finder/config/database_config.dart';

class PostgresService {
  static PostgresService? _instance;
  static PostgresService get instance => _instance ??= PostgresService._();
  
  PostgresService._() {
    // Auto-configure with environment variables
    configure();
  }

  PostgreSQLConnection? _connection;
  bool _isConnected = false;
  
  // Configuration
  String _host = 'localhost';
  int _port = 5432;
  String _database = 'tapmap';
  String _username = 'postgres';
  String _password = '';
  
  bool get isConnected => _isConnected;
  
  // Configure the service
  void configure({
    String? host,
    int? port,
    String? database,
    String? username,
    String? password,
  }) {
    final config = DatabaseConfig.config;
    
    _host = host ?? config['host'];
    _port = port ?? config['port'];
    _database = database ?? config['database'];
    _username = username ?? config['username'];
    _password = password ?? config['password'];
    
    debugPrint('PostgresService configured: host=$_host, port=$_port, database=$_database, user=$_username');
  }
  
  // Connect to PostgreSQL
  Future<bool> connect() async {
    try {
      await _connectToPostgres();
      return true;
    } catch (e) {
      debugPrint('Failed to connect: $e');
      return false;
    }
  }
  
  // Connect to PostgreSQL
  Future<void> _connectToPostgres() async {
    try {
      debugPrint('Connecting to PostgreSQL at $_host:$_port');
      debugPrint('Database: $_database, User: $_username, Password: ${_password.isNotEmpty ? "***" : "empty"}');
      
      _connection = PostgreSQLConnection(
        _host,
        _port,
        _database,
        username: _username,
        password: _password,
        useSSL: false, // Disable SSL for local tunnel
      );
      
      debugPrint('PostgreSQLConnection created, attempting to open...');
      await _connection!.open();
      _isConnected = true;
      debugPrint('PostgreSQL connection established successfully');
      
    } catch (e) {
      debugPrint('Failed to connect to PostgreSQL: $e');
      debugPrint('Error type: ${e.runtimeType}');
      if (e is Exception) {
        debugPrint('Exception details: $e');
      }
      rethrow;
    }
  }
  
  // Disconnect
  Future<void> disconnect() async {
    try {
      if (_connection != null) {
        await _connection!.close();
        _connection = null;
      }
      
      _isConnected = false;
      debugPrint('Disconnected from PostgreSQL');
    } catch (e) {
      debugPrint('Error during disconnect: $e');
    }
  }
  
  // Execute a query and return results
  Future<List<Map<String, dynamic>>> query(String sql) async {
    if (!_isConnected || _connection == null) {
      throw Exception('Not connected to database');
    }
    
    try {
      final results = await _connection!.query(sql);
      return results.map((row) => row.toColumnMap()).toList();
    } catch (e) {
      debugPrint('Query failed: $e');
      rethrow;
    }
  }
  
  // Execute a query and return a single result
  Future<Map<String, dynamic>?> querySingle(String sql) async {
    final results = await query(sql);
    return results.isNotEmpty ? results.first : null;
  }
  
  // Execute a query and return count
  Future<int> queryCount(String sql) async {
    final results = await query(sql);
    if (results.isNotEmpty && results.first.values.isNotEmpty) {
      return results.first.values.first as int;
    }
    return 0;
  }
  
  // Execute a transaction
  Future<T> transaction<T>(Future<T> Function(PostgreSQLExecutionContext) action) async {
    if (!_isConnected || _connection == null) {
      throw Exception('Not connected to database');
    }
    
    try {
      return await _connection!.transaction(action);
    } catch (e) {
      debugPrint('Transaction failed: $e');
      rethrow;
    }
  }
  
  // Health check
  Future<bool> healthCheck() async {
    try {
      if (!_isConnected || _connection == null) return false;
      
      final result = await query('SELECT 1');
      return result.isNotEmpty;
    } catch (e) {
      debugPrint('Health check failed: $e');
      return false;
    }
  }
  
  // Get database statistics
  Future<Map<String, dynamic>> getDatabaseStats() async {
    try {
      final fountainCount = await queryCount('SELECT COUNT(*) FROM fountains');
      final activeCount = await queryCount('SELECT COUNT(*) FROM fountains WHERE status = \'active\'');
      final withGeohashCount = await queryCount('SELECT COUNT(*) FROM fountains WHERE geohash IS NOT NULL');
      
      return {
        'total_fountains': fountainCount,
        'active_fountains': activeCount,
        'with_geohash': withGeohashCount,
        'connection_status': _isConnected ? 'connected' : 'disconnected',
      };
    } catch (e) {
      debugPrint('Failed to get database stats: $e');
      return {
        'error': e.toString(),
        'connection_status': _isConnected ? 'connected' : 'disconnected',
      };
    }
  }
}
