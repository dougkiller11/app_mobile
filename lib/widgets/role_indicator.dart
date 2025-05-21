import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RoleIndicator extends StatelessWidget {
  const RoleIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.isAdmin(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final isAdmin = snapshot.data ?? false;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isAdmin ? Colors.orange.shade100 : Colors.blue.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isAdmin ? Icons.admin_panel_settings : Icons.person,
                  color: isAdmin ? Colors.orange : Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isAdmin ? 'Admin' : 'Client',
                  style: TextStyle(
                    color: isAdmin ? Colors.orange.shade900 : Colors.blue.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox();
      },
    );
  }
} 