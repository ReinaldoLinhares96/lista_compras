// lib/presentation/widgets/add_edit_product_modal_form.dart

// ignore_for_file: unused_import, unused_field, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/produto_model.dart';
import '../../data/repositories/produto_repository.dart';
import '../../data/models/unidade_medida_model.dart';
import '../../data/repositories/unidade_medida_repository.dart';
import '../../data/models/categoria_model.dart';
import '../../data/repositories/categoria_repository.dart';

// Este é o novo StatefulWidget para o conteúdo do seu modal
class AddEditProductModalForm extends StatefulWidget {
  final ProdutoModel? produto;
  final Map<String, String> unidadesDescricao; // Passar do widget pai
  final Map<String, String> categoriasDescricao; // Passar do widget pai
  final Map<String, CategoriaModel> categoriasMap; // Passar do widget pai

  const AddEditProductModalForm({
    super.key,
    this.produto,
    required this.unidadesDescricao,
    required this.categoriasDescricao,
    required this.categoriasMap,
  });

  @override
  State<AddEditProductModalForm> createState() =>
      _AddEditProductModalFormState();
}

class _AddEditProductModalFormState extends State<AddEditProductModalForm> {
  // Declare os controladores como campos do estado do MODAL
  late TextEditingController _nomeController;
  late TextEditingController _quantidadeIdealController;
  // Outras variáveis de estado para o modal
  late double _quantidadeIdealMes;
  String? _selectedUnidadeId;
  String? _selectedCategoriaId;
  late bool
  _isQuantidadeSugerida; // Adicionado para o contexto do outro modal se aplicar aqui

  // Repositórios, se necessário (ou passados via Provider/GetIt)
  final ProdutoRepository _produtoRepository = ProdutoRepository();
  final UnidadeMedidaRepository _unidadeMedidaRepository =
      UnidadeMedidaRepository();
  final CategoriaRepository _categoriaRepository = CategoriaRepository();

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.produto?.nome ?? '');
    _quantidadeIdealMes = widget.produto?.quantidadeIdealMes ?? 1.0;
    _selectedUnidadeId = widget.produto?.unidadeMedidaId;
    _selectedCategoriaId = widget.produto?.categoriaId;

    _quantidadeIdealController = TextEditingController(
      text: _quantidadeIdealMes.toStringAsFixed(1).replaceAll('.', ','),
    );

    // Listener para o campo de quantidade ideal, agora com setState local do modal
    _quantidadeIdealController.addListener(_updateSliderFromText);

    _isQuantidadeSugerida = true; // Valor inicial, ajuste conforme necessário
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _quantidadeIdealController.dispose();
    super.dispose();
  }

  void _updateSliderFromText() {
    final value = double.tryParse(
      _quantidadeIdealController.text.replaceAll(',', '.'),
    );
    if (value != null) {
      setState(() {
        // Agora é o setState do _AddEditProductModalFormState
        _quantidadeIdealMes = value.clamp(0.1, 100.0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.produto == null
                  ? 'Adicionar Novo Produto'
                  : 'Editar Produto',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(labelText: 'Nome do Produto'),
            ),
            const SizedBox(height: 10),
            // NOVIDADE: Combinação de Slider e TextFormField
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
                  // setState do _AddEditProductModalFormState
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
                return DropdownButtonFormField<String>(
                  value: _selectedUnidadeId,
                  hint: const Text('Selecione a Unidade de Medida'),
                  items: unidades.map((unidade) {
                    return DropdownMenuItem(
                      value: unidade.id,
                      child: Text(unidade.descricao),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      // setState do _AddEditProductModalFormState
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
                return DropdownButtonFormField<String>(
                  value: _selectedCategoriaId,
                  hint: const Text('Selecione a Categoria'),
                  items: categorias.map((categoria) {
                    return DropdownMenuItem(
                      value: categoria.id,
                      child: Text(categoria.descricao),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      // setState do _AddEditProductModalFormState
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
                  id: widget.produto?.id, // Use widget.produto
                  nome: _nomeController.text,
                  quantidadeIdealMes: _quantidadeIdealMes,
                  unidadeMedidaId: _selectedUnidadeId!,
                  categoriaId: _selectedCategoriaId!,
                  quantidadeEmEstoque:
                      widget.produto?.quantidadeEmEstoque ??
                      0.0, // Use widget.produto
                  isActive:
                      widget.produto?.isActive ?? true, // Use widget.produto
                  isRemoved:
                      widget.produto?.isRemoved ?? false, // Use widget.produto
                  createdAt: widget.produto?.createdAt, // Use widget.produto
                  updatedAt: DateTime.now(),
                );

                if (widget.produto == null) {
                  // Use widget.produto
                  await _produtoRepository.addProduto(newProduto);
                } else {
                  await _produtoRepository.updateProduto(newProduto);
                }
                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: Text(
                widget.produto == null
                    ? 'Salvar Produto'
                    : 'Atualizar Produto', // Use widget.produto
              ),
            ),
          ],
        ),
      ),
    );
  }
}
