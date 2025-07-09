// ignore_for_file: unused_import, use_build_context_synchronously, unused_local_variable

import 'package:flutter/material.dart';
import '../../data/models/produto_model.dart';
import '../../data/repositories/produto_repository.dart';
import '../../data/models/unidade_medida_model.dart';
import '../../data/repositories/unidade_medida_repository.dart';
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
  final UnidadeMedidaRepository _unidadeMedidaRepository =
      UnidadeMedidaRepository();
  final CategoriaRepository _categoriaRepository = CategoriaRepository();

  late TextEditingController _nomeController;
  late double _quantidadeIdealMes;
  String? _selectedUnidadeId;
  String? _selectedCategoriaId;
  late TextEditingController
  _quantidadeIdealController; // Para o TextFormField ao lado do Slider

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.product?.nome ?? '');
    _quantidadeIdealMes = widget.product?.quantidadeIdealMes ?? 1.0;
    _selectedUnidadeId = widget.product?.unidadeMedidaId;
    _selectedCategoriaId = widget.product?.categoriaId;
    _quantidadeIdealController = TextEditingController(
      text: _quantidadeIdealMes.toStringAsFixed(1).replaceAll('.', ','),
    );

    // Adiciona o listener para sincronizar TextFormField com Slider
    _quantidadeIdealController.addListener(_updateSliderFromText);
  }

  void _updateSliderFromText() {
    final value = double.tryParse(
      _quantidadeIdealController.text.replaceAll(',', '.'),
    );
    if (value != null) {
      setState(() {
        _quantidadeIdealMes = value.clamp(0.1, 100.0);
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
                    'Quantidade Ideal Mês:',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _quantidadeIdealController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
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
            Slider(
              value: _quantidadeIdealMes,
              min: 0.1,
              max: 100.0,
              divisions: 999,
              onChanged: (newValue) {
                setState(() {
                  _quantidadeIdealMes = newValue;
                  _quantidadeIdealController.text = newValue
                      .toStringAsFixed(1)
                      .replaceAll('.', ',');
                });
              },
            ),
            StreamBuilder<List<UnidadeMedidaModel>>(
              stream: _unidadeMedidaRepository.getUnidadesMedida(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                final unidades = snapshot.data!;
                // VERIFICAR SE _selectedUnidadeId EXISTE NA LISTA DE UNIDADES
                final bool isSelectedUnidadeIdValid = unidades.any(
                  (u) => u.id == _selectedUnidadeId,
                );
                return DropdownButtonFormField<String>(
                  // Se o _selectedUnidadeId não for válido, defina-o como null
                  value: isSelectedUnidadeIdValid ? _selectedUnidadeId : null,
                  hint: const Text('Selecione a Unidade de Medida'),
                  items: unidades.map((unidade) {
                    return DropdownMenuItem(
                      value: unidade.id,
                      child: Text(unidade.descricao),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedUnidadeId = value;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 10),
            StreamBuilder<List<CategoriaModel>>(
              stream: _categoriaRepository.getCategorias(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                final categorias = snapshot.data!;
                // VERIFICAR SE _selectedCategoriaId EXISTE NA LISTA DE CATEGORIAS
                final bool isSelectedCategoriaIdValid = categorias.any(
                  (c) => c.id == _selectedCategoriaId,
                );
                return DropdownButtonFormField<String>(
                  // Se o _selectedCategoriaId não for válido, defina-o como null
                  value: isSelectedCategoriaIdValid
                      ? _selectedCategoriaId
                      : null, // CORREÇÃO AQUI
                  hint: const Text('Selecione a Categoria'),
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
                    _selectedUnidadeId == null ||
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
                  unidadeMedidaId: _selectedUnidadeId!,
                  categoriaId: _selectedCategoriaId!,
                  quantidadeEmEstoque:
                      widget.product?.quantidadeEmEstoque ?? 0.0,
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
                  Navigator.pop(context); // Fecha o modal
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
