import 'package:flutter/material.dart';
import '../services/database_service.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;
  String? _error;
  String? _filterAction;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs({String? actionFilter}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _logs = await DatabaseService.getAuditLogs(actionFilter: actionFilter);
    } catch (e) {
      _error = 'No se pudieron cargar los registros.\n$e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auditoría'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () async {
              final filter = await showDialog<String>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Filtrar por acción'),
                  content: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Parte de la acción',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) => Navigator.pop(ctx, value),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, ''),
                      child: const Text('Limpiar filtro'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, null),
                      child: const Text('Cancelar'),
                    ),
                  ],
                ),
              );
              if (filter != null) {
                _filterAction = filter.isEmpty ? null : filter;
                _loadLogs(actionFilter: _filterAction);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadLogs(actionFilter: _filterAction),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error, size: 48, color: Colors.red),
                      const SizedBox(height: 8),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _loadLogs(actionFilter: _filterAction),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _logs.isEmpty
                  ? const Center(child: Text('No hay registros de auditoría'))
                  : ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: ListTile(
                            title: Text(log['action'] as String),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${log['timestamp']} | ${log['user'] ?? ''}'),
                                if (log['details'] != null)
                                  Text(
                                    log['details'] as String,
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}