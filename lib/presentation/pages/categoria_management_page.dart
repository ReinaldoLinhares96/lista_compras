import 'package:flutter/material.dart';
import 'package:lista_compras/data/models/categoria_model.dart';
import 'package:lista_compras/data/repositories/categoria_repository.dart';
import 'package:lista_compras/presentation/widgets/edit_categoria_modal.dart'; // Importe o modal de edição

class CategoriaManagementPage extends StatefulWidget {
  const CategoriaManagementPage({super.key});

  @override
  State<CategoriaManagementPage> createState() =>
      _CategoriaManagementPageState();
}

class _CategoriaManagementPageState extends State<CategoriaManagementPage> {
  final CategoriaRepository _repository = CategoriaRepository();

  void _showEditCategoriaModal(CategoriaModel categoria) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return EditCategoriaModal(categoria: categoria);
      },
    );
  }

  Future<void> _confirmDeleteCategoria(CategoriaModel categoria) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Tem certeza que deseja remover a categoria "${categoria.descricao}"?',
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
        await _repository.deleteCategoria(categoria.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Categoria "${categoria.descricao}" removida com sucesso!',
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao remover categoria: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorias'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade100,
      ),
      body: StreamBuilder<List<CategoriaModel>>(
        stream: _repository.getCategorias(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar categorias: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhuma categoria cadastrada.'));
          }

          final categorias = snapshot.data!;
          return ListView.builder(
            itemCount: categorias.length,
            itemBuilder: (context, index) {
              final categoria = categorias[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text(categoria.descricao),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditCategoriaModal(categoria),
                        tooltip: 'Editar Categoria',
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_forever,
                          color: Colors.red,
                        ),
                        onPressed: () => _confirmDeleteCategoria(categoria),
                        tooltip: 'Remover Categoria',
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
