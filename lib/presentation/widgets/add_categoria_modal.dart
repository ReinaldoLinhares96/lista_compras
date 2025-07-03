// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:lista_compras/data/models/categoria_model.dart';
import 'package:lista_compras/data/repositories/categoria_repository.dart';

class AddCategoriaModal extends StatefulWidget {
  const AddCategoriaModal({super.key});

  @override
  State<AddCategoriaModal> createState() => _AddCategoriaModalState();
}

class _AddCategoriaModalState extends State<AddCategoriaModal> {
  final TextEditingController _descricaoController = TextEditingController();

  final CategoriaRepository _repository = CategoriaRepository();

  @override
  void dispose() {
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _addCategoria() async {
    if (_descricaoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha a descrição.')),
      );
      return;
    }

    try {
      // Validação de duplicidade por descrição (case-insensitive)
      final existingCategory = await _repository.getCategoriaByDescricao(
        _descricaoController.text.toLowerCase(),
      );

      if (existingCategory != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Já existe uma categoria com essa descrição.'),
          ),
        );
        return;
      }

      final newCategoria = CategoriaModel(descricao: _descricaoController.text);

      // Não precisamos mais chamar initializeDefaultCategorias, pois as categorias serão criadas pelo usuário
      await _repository.addCategoria(newCategoria);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Categoria "${newCategoria.descricao}" adicionada!'),
          ),
        );
        Navigator.pop(context); // Fecha o modal
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao adicionar categoria: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 60,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Adicionar Nova Categoria',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _descricaoController,
              decoration: const InputDecoration(
                labelText: 'Descrição da Categoria (ex: "Congelados")',
                hintText: 'Ex: Laticínios, Bebidas',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addCategoria,
              child: const Text('Salvar Categoria'),
            ),
          ],
        ),
      ),
    );
  }
}
