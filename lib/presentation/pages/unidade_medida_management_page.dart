import 'package:flutter/material.dart';
import 'package:lista_compras/data/models/unidade_medida_model.dart';
import 'package:lista_compras/data/repositories/unidade_medida_repository.dart';
import 'package:lista_compras/presentation/widgets/edit_unidade_medida_modal.dart'; // Importe o modal de edição

class UnidadeMedidaManagementPage extends StatefulWidget {
  const UnidadeMedidaManagementPage({super.key});

  @override
  State<UnidadeMedidaManagementPage> createState() =>
      _UnidadeMedidaManagementPageState();
}

class _UnidadeMedidaManagementPageState
    extends State<UnidadeMedidaManagementPage> {
  final UnidadeMedidaRepository _repository = UnidadeMedidaRepository();

  void _showEditUnidadeModal(UnidadeMedidaModel unidade) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return EditUnidadeMedidaModal(unidade: unidade);
      },
    );
  }

  Future<void> _confirmDeleteUnidade(UnidadeMedidaModel unidade) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Tem certeza que deseja remover a unidade "${unidade.descricao} (${unidade.simbolo})"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _repository.deleteUnidade(unidade.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Unidade "${unidade.descricao}" removida com sucesso!',
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao remover unidade: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unidades de Medida'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade100,
      ),
      body: StreamBuilder<List<UnidadeMedidaModel>>(
        stream: _repository.getUnidadesMedida(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar unidades: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Nenhuma unidade de medida cadastrada.'),
            );
          }

          final unidades = snapshot.data!;
          return ListView.builder(
            itemCount: unidades.length,
            itemBuilder: (context, index) {
              final unidade = unidades[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text(unidade.descricao),
                  subtitle: Text('Símbolo: ${unidade.simbolo}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditUnidadeModal(unidade),
                        tooltip: 'Editar Unidade',
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_forever,
                          color: Colors.red,
                        ),
                        onPressed: () => _confirmDeleteUnidade(unidade),
                        tooltip: 'Remover Unidade',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
