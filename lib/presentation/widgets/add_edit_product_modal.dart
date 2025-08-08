// ignore_for_file: unused_import, use_build_context_synchronously, unused_local_variable

import 'package:flutter/material.dart';
import '../../data/models/produto_model.dart';
import '../../data/repositories/produto_repository.dart';
import '../../data/models/categoria_model.dart';
import '../../data/repositories/categoria_repository.dart';

class AddEditProductModal extends StatefulWidget {
  final ProdutoModel?
  product; // Produto a ser editado (null para adicionar novo)

  const AddEditProductModal({super.key, this.product});

  @override
  State<AddEditProductModal> createState() => _AddEditProductModalState();
}

class _AddEditProductModalState extends State<AddEditProductModal> {
  final ProdutoRepository _produtoRepository = ProdutoRepository();
  final CategoriaRepository _categoriaRepository = CategoriaRepository();

  late TextEditingController _nomeController;
  late int _quantidadeIdealMes;
  String? _selectedCategoriaId;
  late TextEditingController _quantidadeIdealController;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.product?.nome ?? '');
    _quantidadeIdealMes = widget.product?.quantidadeIdealMes ?? 1;
    _selectedCategoriaId = widget.product?.categoriaId;
    _quantidadeIdealController = TextEditingController(
      text: _quantidadeIdealMes.toString(),
    );

    _quantidadeIdealController.addListener(_updateSliderFromText);
  }

  void _updateSliderFromText() {
    final value = int.tryParse(_quantidadeIdealController.text.toString());
    if (value != null) {
      setState(() {
        _quantidadeIdealMes = value;
      });
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _quantidadeIdealController.removeListener(_updateSliderFromText);
    _quantidadeIdealController.dispose();
    super.dispose();
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
              widget.product == null
                  ? 'Adicionar Novo Produto'
                  : 'Editar Produto',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(labelText: 'Nome do Produto'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Quantidade Ideal:',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _quantidadeIdealController,
                    keyboardType: const TextInputType.numberWithOptions(),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 8.0,
                      ),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            StreamBuilder<List<CategoriaModel>>(
              stream: _categoriaRepository.getCategorias(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                final categorias = snapshot.data!;
                final bool isSelectedCategoriaIdValid = categorias.any(
                  (c) => c.id == _selectedCategoriaId,
                );
                return DropdownButtonFormField<String>(
                  value: isSelectedCategoriaIdValid
                      ? _selectedCategoriaId
                      : null,
                  hint: categorias.isNotEmpty
                      ? const Text('Selecione a Categoria')
                      : const Text('Crie uma Categoria'),
                  items: categorias.map((categoria) {
                    return DropdownMenuItem(
                      value: categoria.id,
                      child: Text(categoria.descricao),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoriaId = value;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (_nomeController.text.isEmpty ||
                    _selectedCategoriaId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Preencha todos os campos!')),
                  );
                  return;
                }

                final newProduto = ProdutoModel(
                  id: widget.product?.id,
                  nome: _nomeController.text,
                  quantidadeIdealMes: _quantidadeIdealMes,
                  categoriaId: _selectedCategoriaId!,
                  quantidadeEmEstoque: widget.product?.quantidadeEmEstoque ?? 0,
                  isActive: widget.product?.isActive ?? true,
                  isRemoved: widget.product?.isRemoved ?? false,
                  createdAt: widget.product?.createdAt,
                  updatedAt: DateTime.now(),
                );

                if (widget.product == null) {
                  await _produtoRepository.addProduto(newProduto);
                } else {
                  await _produtoRepository.updateProduto(newProduto);
                }
                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: Text(
                widget.product == null ? 'Salvar Produto' : 'Atualizar Produto',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
