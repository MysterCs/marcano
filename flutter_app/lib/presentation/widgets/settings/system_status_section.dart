import 'package:flutter/material.dart';

import '../../../data/services/api_client.dart';
import 'settings_section.dart';

/// Seccion de estado del sistema: verifica el backend en vivo.
class SystemStatusSection extends StatelessWidget {
  const SystemStatusSection({required this.apiClient, super.key});

  final ApiClient apiClient;

  Future<Map<String, String>> _fetchStatus() async {
    print('DEBUG: Fetching status from /api/health');
    final response = await apiClient.getJson('/api/health') as Map<String, dynamic>;
    return {
      'Estado': response['status']?.toString() ?? 'desconocido',
      'Servicio': response['service']?.toString() ?? '-',
      'Servidor': apiClient.baseUrl,
    };
  }

  @override
  Widget build(BuildContext context) => SettingsSection(
        title: 'Estado del sistema',
        icon: Icons.monitor_heart_outlined,
        children: [
          FutureBuilder<Map<String, String>>(
            future: _fetchStatus(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: LinearProgressIndicator(),
                );
              }
              if (snapshot.hasError) {
                return Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sin conexion con el backend.\nServidor: ${apiClient.baseUrl}',
                      ),
                    ),
                  ],
                );
              }
              final values = snapshot.requireData;
              return Column(
                children: [
                  for (final entry in values.entries)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: entry.key == 'Estado'
                          ? const Icon(Icons.check_circle,
                              color: Color(0xFF4ADE80))
                          : const Icon(Icons.chevron_right),
                      title: Text(entry.key),
                      trailing:
                          Text(entry.value, textAlign: TextAlign.end),
                    ),
                ],
              );
            },
          ),
        ],
      );
}
