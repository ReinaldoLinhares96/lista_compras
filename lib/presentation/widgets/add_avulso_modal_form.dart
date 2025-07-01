// lib/presentation/widgets/add_avulso_modal_form.dart

// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Se for usar Firestore diretamente aqui
import '../../data/models/item_compra_model.dart';
import '../../data/models/compra_model.dart';
import '../../data/repositories/item_compra_repository.dart';
import '../../data/repositories/compra_repository.dart';

// Este é o novo StatefulWidget para o conteúdo do seu modal "Adicionar Item Avulso"
class AddAvulsoModalForm extends StatefulWidget {
  final CompraModel? compraAtiva; // Passar a compra ativa para adicionar o item
  final Function(String message) showSnackbar; // Callback para exibir Snackbar

  const AddAvulsoModalForm({
    super.key,
    this.compraAtiva,
    required this.showSnackbar,
  });

  @override
  State<AddAvulsoModalForm> createState() => _AddAvulsoModalFormState();
}

class _AddAvulsoModalFormState extends State<AddAvulsoModalForm> {
  late TextEditingController _nomeController;
  late TextEditingController _quantidadeController;
  late TextEditingController _precoController;

  final ItemCompraRepository _itemCompraRepository = ItemCompraRepository();
  final CompraRepository _compraRepository = CompraRepository();

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController();
    _quantidadeController = TextEditingController();
    _precoController = TextEditingController();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _quantidadeController.dispose();
    _precoController.dispose();
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
              'Adicionar Item Avulso',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(labelText: 'Nome do Item'),
            ),
            TextField(
              controller: _quantidadeController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Quantidade'),
            ),
            TextField(
              controller: _precoController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Preço Unitário (R\$)',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final String nome = _nomeController.text;
                final double? quantidade = double.tryParse(
                  _quantidadeController.text.replaceAll(',', '.'),
                );
                final double? precoUnitario = double.tryParse(
                  _precoController.text.replaceAll(',', '.'),
                );

                if (widget.compraAtiva == null) {
                  widget.showSnackbar(
                    'Nenhuma compra ativa. Inicie uma compra primeiro.',
                  );
                  return;
                }

                if (nome.isEmpty ||
                    quantidade == null ||
                    quantidade <= 0 ||
                    precoUnitario == null ||
                    precoUnitario <= 0) {
                  widget.showSnackbar('Preencha todos os campos corretamente.');
                  return;
                }

                final newItem = ItemCompraModel(
                  compraId: widget.compraAtiva!.id,
                  nomeProduto: nome,
                  quantidadeComprada: quantidade,
                  precoUnitario: precoUnitario,
                  ehAvulso: true,
                );
                await _itemCompraRepository.addItemCompra(newItem);

                final currentTotal =
                    widget.compraAtiva!.valorTotalCalculado + newItem.subtotal;
                await _compraRepository.updateCompra(
                  widget.compraAtiva!.copyWith(
                    valorTotalCalculado: currentTotal,
                  ),
                );

                if (mounted) Navigator.pop(context);
              },
              child: const Text('Adicionar Avulso'),
            ),
          ],
        ),
      ),
    );
  }
}
