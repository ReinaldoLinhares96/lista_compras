// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Para FieldValue.serverTimestamp
import 'package:lista_compras/data/models/compra_model.dart';
import 'package:lista_compras/data/models/item_compra_model.dart';
import 'package:lista_compras/data/models/produto_model.dart';
import 'package:lista_compras/data/repositories/compra_repository.dart';
import 'package:lista_compras/data/repositories/item_compra_repository.dart';

class AddFrequentProductToCartModal extends StatefulWidget {
  final ProdutoModel product;
  final CompraModel? activePurchase; // Compra ativa atual
  final Function(String) showSnackbar; // Callback para exibir Snackbar
  final Map<String, String>
  unidadesDescricao; // Para exibir a descrição da unidade
  final CompraRepository compraRepository;
  final ItemCompraRepository itemCompraRepository;

  const AddFrequentProductToCartModal({
    super.key,
    required this.product,
    required this.activePurchase,
    required this.showSnackbar,
    required this.unidadesDescricao,
    required this.compraRepository,
    required this.itemCompraRepository,
  });

  @override
  State<AddFrequentProductToCartModal> createState() =>
      _AddFrequentProductToCartModalState();
}

class _AddFrequentProductToCartModalState
    extends State<AddFrequentProductToCartModal> {
  late TextEditingController _quantidadeController;
  late TextEditingController _precoController;
  late double _quantidadeNecessaria;
  bool _isQuantidadeSugerida = true;
  double _finalQuantity = 0.0;
  double _finalPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _quantidadeNecessaria =
        widget.product.quantidadeIdealMes - widget.product.quantidadeEmEstoque;
    _quantidadeNecessaria = _quantidadeNecessaria > 0
        ? _quantidadeNecessaria
        : 0.0;

    _quantidadeController = TextEditingController(
      text: _quantidadeNecessaria.toStringAsFixed(1).replaceAll('.', ','),
    );
    _precoController = TextEditingController();

    _finalQuantity =
        _quantidadeNecessaria; // Inicializa com a quantidade sugerida
  }

  @override
  void dispose() {
    _quantidadeController.dispose();
    _precoController.dispose();
    super.dispose();
  }

  Future<void> _addItemToCart() async {
    if (_finalQuantity <= 0 ||
        _precoController.text.isEmpty ||
        _finalPrice <= 0) {
      widget.showSnackbar('Preencha a quantidade e o preço corretamente.');
      return;
    }

    if (widget.activePurchase == null) {
      widget.showSnackbar('Nenhuma compra ativa. Inicie uma compra primeiro.');
      return;
    }

    try {
      final newItem = ItemCompraModel(
        compraId: widget.activePurchase!.id,
        produtoId: widget.product.id,
        nomeProduto: widget.product.nome,
        quantidadeComprada: _finalQuantity,
        precoUnitario: _finalPrice,
        ehAvulso: false,
      );
      await widget.itemCompraRepository.addItemCompra(newItem);

      final currentTotal =
          widget.activePurchase!.valorTotalCalculado + newItem.subtotal;
      await widget.compraRepository.updateCompra(
        widget.activePurchase!.copyWith(valorTotalCalculado: currentTotal),
      );

      if (mounted) {
        widget.showSnackbar('${widget.product.nome} adicionado ao carrinho!');
        Navigator.pop(context); // Fecha o modal
      }
    } catch (e) {
      if (mounted) {
        widget.showSnackbar('Erro ao adicionar item: $e');
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Adicionar ${widget.product.nome} ao Carrinho',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 15),
            Text(
              'Precisa comprar: ${_quantidadeNecessaria.toStringAsFixed(1)} ${widget.unidadesDescricao[widget.product.unidadeMedidaId] ?? 'N/A'}',
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Usar quantidade sugerida?'),
                Switch(
                  value: _isQuantidadeSugerida,
                  onChanged: (bool value) {
                    setState(() {
                      _isQuantidadeSugerida = value;
                      if (_isQuantidadeSugerida) {
                        _quantidadeController.text = _quantidadeNecessaria
                            .toStringAsFixed(1)
                            .replaceAll('.', ',');
                        _finalQuantity = _quantidadeNecessaria;
                      } else {
                        _quantidadeController.clear();
                        _finalQuantity = 0.0;
                      }
                    });
                  },
                ),
              ],
            ),
            if (!_isQuantidadeSugerida) ...[
              TextField(
                controller: _quantidadeController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Quantidade a Adicionar',
                ),
                onChanged: (text) {
                  final value = double.tryParse(text.replaceAll(',', '.'));
                  if (value != null && value >= 0) {
                    setState(() {
                      _finalQuantity = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 10),
              // Lógica para atualizar a quantidade ideal no modal (apenas informativo)
              Text(
                'Estoque atual: ${widget.product.quantidadeEmEstoque.toStringAsFixed(1)} ${widget.unidadesDescricao[widget.product.unidadeMedidaId] ?? 'N/A'}',
              ),
              Text(
                'Quantidade ideal: ${widget.product.quantidadeIdealMes.toStringAsFixed(1)} ${widget.unidadesDescricao[widget.product.unidadeMedidaId] ?? 'N/A'}',
              ),
              if (_finalQuantity + widget.product.quantidadeEmEstoque >
                  widget.product.quantidadeIdealMes)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Ao adicionar este item, seu estoque excederá o ideal em ${((_finalQuantity + widget.product.quantidadeEmEstoque) - widget.product.quantidadeIdealMes).toStringAsFixed(1)}.\nVocê poderá ajustar a quantidade ideal após a compra.',
                    style: const TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ),
            ],
            const SizedBox(height: 10),
            TextField(
              controller: _precoController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Preço Unitário (R\$)',
              ),
              onChanged: (text) {
                final value = double.tryParse(text.replaceAll(',', '.'));
                if (value != null && value >= 0) {
                  setState(() {
                    _finalPrice = value;
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addItemToCart,
                child: const Text('Adicionar ao Carrinho'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
