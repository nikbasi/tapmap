import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:water_fountain_finder/providers/postgres_fountain_provider.dart';

class DatabaseStatusWidget extends StatelessWidget {
  const DatabaseStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PostgresFountainProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(8.0),
          margin: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: provider.isConnected ? Colors.green : Colors.red,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                provider.isConnected ? Icons.check_circle : Icons.error,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                provider.isConnected ? 'DB Connected' : 'DB Disconnected',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (provider.isLoading)
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}


