import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/log_model.dart';
import '../../data/repositories/log_repository.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  @override
  Widget build(BuildContext context) {
    final logRepository = Provider.of<LogRepository>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs de Teste'),
        centerTitle: true,
        backgroundColor: Colors.grey.shade300,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () => logRepository.clearLogs(),
            tooltip: 'Limpar Logs',
          ),
        ],
      ),
      body: StreamBuilder<List<LogModel>>(
        stream: logRepository.getLogs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar logs: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum log disponível.'));
          }

          final logs = snapshot.data!;
          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return ListTile(
                title: Text(log.message),
                subtitle: Text(
                  '${log.level} - ${log.timestamp.toIso8601String()}',
                ),
                tileColor: log.level == 'ERROR'
                    ? Colors.red.shade100
                    : Colors.white,
              );
            },
          );
        },
      ),
    );
  }
}
