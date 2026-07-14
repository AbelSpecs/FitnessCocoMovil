import 'package:flutter/material.dart';
import 'package:pyrosfitmovil/core/models/student_info_model.dart';
import 'package:pyrosfitmovil/theme/app_theme.dart';

class ClientCard extends StatelessWidget {
  final StudentInfo client;
  final VoidCallback onTap;

  const ClientCard({
    super.key,
    required this.client,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String initial =
        client.name.isNotEmpty ? client.name[0].toUpperCase() : '?';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: context.pyrosStyles.gradientPrimary,
                  boxShadow: context.pyrosStyles.shadowGlow,
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      client.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Goal Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getGoalLabel(client.fitnessGoal),
                        style: theme.textTheme.labelSmall?.copyWith(
                          // color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGoalLabel(String goalKey) {
    final Map<String, String> labels = {
      'muscle': "Ganancia muscular",
      'fat-loss': "Perder grasa",
      'strength': "Ganar fuerza",
      'endurance': "Ganar resistencia",
    };
    return labels[goalKey] ??
        (goalKey.isNotEmpty ? goalKey.toUpperCase() : 'OBJETIVO NO DEFINIDO');
  }
}
