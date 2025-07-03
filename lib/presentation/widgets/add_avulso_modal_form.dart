// lib/presentation/widgets/add_avulso_modal_form.dart

// ignore_for_file: unused_import, use_build_context_synchronously, duplicate_ignore

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/item_compra_model.dart';
import '../../data/models/compra_model.dart';
import '../../data/repositories/item_compra_repository.dart';
import '../../data/repositories/compra_repository.dart';

class AddAvulsoModalForm extends StatefulWidget {
  final CompraModel? compraAtiva;
  final Function(String message) showSnackbar;
  final ItemCompraRepository itemCompraRepository;
  final CompraRepository compraRepository;

  const AddAvulsoModalForm({
    super.key,
    this.compraAtiva,
    required this.showSnackbar,
    required this.itemCompraRepository,
    required this.compraRepository,
  });

  @override
  State<AddAvulsoModalForm> createState() => _AddAvulsoModalFormState();
}

class _AddAvulsoModalFormState extends State<AddAvulsoModalForm> {
  late TextEditingController _nomeController;
  late TextEditingController _quantidadeController;
  late TextEditingController _precoController;

  double? _finalQuantity;
  double? _finalPrice;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController();
    _quantidadeController = TextEditingController();
    _precoController = TextEditingController();

    _quantidadeController.addListener(() {
      final value = double.tryParse(
        _quantidadeController.text.replaceAll(',', '.'),
      );
      setState(() {
        _finalQuantity = value;
      });
    });

    _precoController.addListener(() {
      final value = double.tryParse(_precoController.text.replaceAll(',', '.'));
      setState(() {
        _finalPrice = value;
      });
    });
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

                if (widget.compraAtiva == null) {
                  widget.showSnackbar(
                    'Nenhuma compra ativa. Inicie uma compra primeiro.',
                  );
                  return;
                }

                // CORREÇÃO: Validação estrita para valores maiores que zero
                if (nome.isEmpty ||
                    _finalQuantity == null ||
                    _finalQuantity! <= 0 || // Deve ser maior que zero
                    _finalPrice == null ||
                    _finalPrice! <= 0) {
                  // Deve ser maior que zero
                  widget.showSnackbar(
                    'Preencha todos os campos corretamente com valores maiores que zero.',
                  );
                  return;
                }

                final newItem = ItemCompraModel(
                  compraId: widget.compraAtiva!.id,
                  nomeProduto: nome,
                  quantidadeComprada: _finalQuantity!,
                  precoUnitario: _finalPrice!,
                  ehAvulso: true,
                );
                await widget.itemCompraRepository.addItemCompra(newItem);

                final currentTotal =
                    widget.compraAtiva!.valorTotalCalculado + newItem.subtotal;
                await widget.compraRepository.updateCompra(
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
