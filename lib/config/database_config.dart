import 'package:flutter_dotenv/flutter_dotenv.dart';

class DatabaseConfig {
  // PostgreSQL Database Configuration
  static const String dbHost = 'your-db-host.com'; // Update with your actual host
  static const int dbPort = 5432;
  static const String dbName = 'tapmap_db';
  static const String dbUsername = 'postgres';
  static const String dbPassword = 'your-password'; // Update with your actual password
  
  // SSH Tunnel Configuration (optional)
  static const String sshHost = 'your-ssh-host.com'; // Update with your SSH host if using tunnel
  static const int sshPort = 22;
  static const String sshUsername = 'your-ssh-username'; // Update with your SSH username
  static const String sshPassword = 'your-ssh-password'; // Update with your SSH password
  static const String sshPrivateKeyPath = ''; // Path to private key file if using key authentication
  static const int localPort = 5433; // Local port for SSH tunnel
  
  // Connection Pool Configuration
  static const int maxConnections = 10;
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration queryTimeout = Duration(seconds: 60);
  
  // Geohash Configuration
  static const int defaultGeohashPrecision = 5;
  static const int maxGeohashPrecision = 12;
  static const int minGeohashPrecision = 1;
  
  // Query Limits
  static const int defaultQueryLimit = 100;
  static const int maxQueryLimit = 1000;
  
  // Cache Configuration
  static const Duration cacheExpiration = Duration(minutes: 5);
  static const int maxCacheSize = 1000;
  
  // Retry Configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);
  
  // Debug Configuration
  static const bool enableQueryLogging = true;
  static const bool enablePerformanceLogging = true;
  
  // Environment-specific overrides
  static bool get isDevelopment => const bool.fromEnvironment('dart.vm.product') == false;
  static bool get isProduction => const bool.fromEnvironment('dart.vm.product') == true;
  
  // Get configuration based on environment
  static Map<String, dynamic> get config {
    if (isDevelopment) {
      return {
        'host': _getEnvVar('DB_HOST', 'localhost'), // SSH tunnel local port
        'port': int.tryParse(_getEnvVar('SSH_TUNNEL_LOCAL_PORT', '5433')) ?? 5433, // SSH tunnel local port
        'database': _getEnvVar('DB_NAME', 'tapmap_db'),
        'username': _getEnvVar('DB_USER', 'tapmap_user'),
        'password': _getEnvVar('DB_PASSWORD', ''), // Read from .env file
        'sshHost': _getEnvVar('ORACLE_CLOUD_HOST', ''),
        'sshPort': int.tryParse(_getEnvVar('SSH_TUNNEL_REMOTE_PORT', '22')) ?? 22,
        'sshUsername': _getEnvVar('ORACLE_CLOUD_USER', ''),
        'sshPassword': _getEnvVar('ORACLE_CLOUD_SSH_PASSWORD', ''),
        'localPort': int.tryParse(_getEnvVar('SSH_TUNNEL_LOCAL_PORT', '5433')) ?? 5433,
        'enableQueryLogging': true,
        'enablePerformanceLogging': true,
      };
    } else {
      return {
        'host': dbHost,
        'port': dbPort,
        'database': dbName,
        'username': dbUsername,
        'password': dbPassword,
        'sshHost': sshHost,
        'sshPort': sshPort,
        'sshUsername': sshUsername,
        'sshPassword': sshPassword,
        'localPort': localPort,
        'enableQueryLogging': false,
        'enablePerformanceLogging': false,
      };
    }
  }
  
  // Helper method to get environment variables from .env file
  static String _getEnvVar(String key, String defaultValue) {
    // Try to get from .env file first
    final envValue = dotenv.env[key];
    if (envValue != null && envValue.isNotEmpty) {
      return envValue;
    }
    
    // Fallback to default value
    return defaultValue;
  }
  
  // Validate configuration
  static bool get isValid {
    final config = DatabaseConfig.config;
    return config['host'].isNotEmpty &&
           config['database'].isNotEmpty &&
           config['username'].isNotEmpty &&
           config['password'].isNotEmpty; // Ensure password is not empty
  }
  
  // Get SSH configuration
  static bool get useSSHTunnel {
    final config = DatabaseConfig.config;
    return config['sshHost'].isNotEmpty && config['sshUsername'].isNotEmpty;
  }
  
  // Get connection string for direct connection (without SSH)
  static String get connectionString {
    final config = DatabaseConfig.config;
    return 'postgresql://${config['username']}:${config['password']}@${config['host']}:${config['port']}/${config['database']}';
  }
}
