// ignore_for_file: unused_import, duplicate_ignore

import 'package:flutter/material.dart';
import 'package:lista_compras/data/models/compra_model.dart';
import 'package:lista_compras/data/models/item_compra_model.dart';
import 'package:lista_compras/data/models/produto_model.dart';
import 'package:lista_compras/data/repositories/compra_repository.dart';
import 'package:lista_compras/data/repositories/item_compra_repository.dart';

class AddFrequentProductToCartModal extends StatefulWidget {
  final ProdutoModel product;
  final CompraModel? activePurchase;
  final Function(String) showSnackbar;
  final CompraRepository compraRepository;
  final ItemCompraRepository itemCompraRepository;

  const AddFrequentProductToCartModal({
    super.key,
    required this.product,
    required this.activePurchase,
    required this.showSnackbar,
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
  late int _quantidadeNecessaria;
  bool _isQuantidadeSugerida = true;
  int? _finalQuantity; // Pode ser nulo
  double? _finalPrice; // Pode ser nulo

  @override
  void initState() {
    super.initState();
    _quantidadeNecessaria =
        widget.product.quantidadeIdealMes - widget.product.quantidadeEmEstoque;
    _quantidadeNecessaria = _quantidadeNecessaria > 0
        ? _quantidadeNecessaria
        : 0;

    _quantidadeController = TextEditingController(
      text: _quantidadeNecessaria.toString(),
    );
    _precoController = TextEditingController();

    _finalQuantity =
        _quantidadeNecessaria; // Inicializa _finalQuantity com a quantidade sugerida

    _precoController.addListener(() {
      final value = double.tryParse(_precoController.text.replaceAll(',', '.'));
      setState(() {
        _finalPrice = value;
      });
    });

    _quantidadeController.addListener(() {
      if (!_isQuantidadeSugerida) {
        final value = int.tryParse(_quantidadeController.text.toString());
        setState(() {
          _finalQuantity = value;
        });
      }
    });
  }

  @override
  void dispose() {
    _quantidadeController.dispose();
    _precoController.dispose();
    super.dispose();
  }

  Future<void> _addItemToCart() async {
    // CORREÇÃO: Validação estrita para valores maiores que zero
    if (_finalQuantity == null ||
        _finalQuantity! <= 0 ||
        _finalPrice == null ||
        _finalPrice! <= 0) {
      widget.showSnackbar(
        'Preencha a quantidade e o preço corretamente com valores maiores que zero.',
      );
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
        quantidadeComprada: _finalQuantity!,
        precoUnitario: _finalPrice!,
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
        Navigator.pop(context);
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
            Text('Precisa comprar: ${_quantidadeNecessaria.toString()}'),
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
                            .toString();
                        _finalQuantity = _quantidadeNecessaria;
                      } else {
                        _quantidadeController.clear();
                        _finalQuantity =
                            null; // Definir como null se não for sugerida e o campo estiver vazio
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
                  decimal: false,
                ),
                decoration: const InputDecoration(
                  labelText: 'Quantidade a Adicionar',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Estoque atual: ${widget.product.quantidadeEmEstoque.toString()}',
              ),
              Text(
                'Quantidade ideal: ${widget.product.quantidadeIdealMes.toString()}',
              ),
              // CORREÇÃO: Verificação de nulidade antes da soma
              if (_finalQuantity != null &&
                  (_finalQuantity! + widget.product.quantidadeEmEstoque >
                      widget.product.quantidadeIdealMes))
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Ao adicionar este item, seu estoque excederá o ideal em ${((_finalQuantity! + widget.product.quantidadeEmEstoque) - widget.product.quantidadeIdealMes).toString()}.\nVocê poderá ajustar a quantidade ideal após a compra.',
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
