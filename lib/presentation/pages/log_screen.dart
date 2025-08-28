import 'package:flutter/material.dart';
import 'package:lista_compras/data/models/log_model.dart';
import 'package:lista_compras/data/repositories/log_repository.dart';
import 'package:provider/provider.dart';

class LogScreen extends StatelessWidget {
  const LogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<LogRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () async => repo.clearLogs(),
            tooltip: 'Limpar logs',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async => repo.addLog('Log de teste', level: 'debug'),
            tooltip: 'Adicionar log de teste',
          ),
        ],
      ),
      body: StreamBuilder<List<LogModel>>(
        stream: repo.watchAll(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final logs = snapshot.data ?? const <LogModel>[];
          if (logs.isEmpty) {
            return const Center(child: Text('Nenhum log ainda.'));
          }

          return ListView.separated(
            itemCount: logs.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final log = logs[index];
              return ListTile(
                title: Text(log.message),
                subtitle: Text(
                  '${log.level.toUpperCase()} • ${log.timestamp.toLocal()}',
                ),
              );
            },
          );
        },
      ),
    );
  }
}
