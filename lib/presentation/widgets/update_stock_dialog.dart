// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:flutter/material.dart';
import '../../data/models/produto_model.dart';
import '../../data/repositories/produto_repository.dart';

class UpdateStockDialog extends StatelessWidget {
  final ProdutoModel product;
  final ProdutoRepository productRepository; // Recebe o repositório
  final Map<String, String>
  unidadesDescricao; // Para exibir a descrição da unidade
  final Map<String, String> unidadesSimbolo;

  const UpdateStockDialog({
    super.key,
    required this.product,
    required this.productRepository,
    required this.unidadesDescricao,
    required this.unidadesSimbolo,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController _stockController = TextEditingController(
      text: product.quantidadeEmEstoque.toStringAsFixed(1).replaceAll('.', ','),
    );

    return AlertDialog(
      title: Text('Atualizar Estoque de ${product.nome}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Ideal p/ Mês: ${product.quantidadeIdealMes.toStringAsFixed(1)} ${unidadesSimbolo[product.unidadeMedidaId] ?? 'N/A'}',
          ),
          TextField(
            controller: _stockController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Quantidade em Estoque Atual',
              hintText: 'Ex: 2,5',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            final String inputText = _stockController.text;
            final double? novaQuantidade = double.tryParse(
              inputText.replaceAll(',', '.'),
            );

            if (novaQuantidade == null || novaQuantidade < 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Por favor, insira uma quantidade válida.'),
                ),
              );
              return;
            }

            if (novaQuantidade > product.quantidadeIdealMes) {
              final bool? updateIdeal = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Estoque Excedente!'),
                  content: Text(
                    '${product.nome}: Novo estoque (${novaQuantidade.toStringAsFixed(1)}) excede o ideal mensal (${product.quantidadeIdealMes.toStringAsFixed(1)}). Deseja atualizar a Quantidade Ideal para o novo estoque?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Não'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Sim'),
                    ),
                  ],
                ),
              );

              if (updateIdeal == true) {
                await productRepository.updateProduto(
                  product.copyWith(
                    quantidadeEmEstoque: novaQuantidade,
                    quantidadeIdealMes: novaQuantidade,
                    updatedAt: DateTime.now(),
                  ),
                );
              } else {
                await productRepository.updateProduto(
                  product.copyWith(
                    quantidadeEmEstoque: novaQuantidade,
                    updatedAt: DateTime.now(),
                  ),
                );
              }
            } else {
              await productRepository.updateProduto(
                product.copyWith(
                  quantidadeEmEstoque: novaQuantidade,
                  updatedAt: DateTime.now(),
                ),
              );
            }

            if (context.mounted) {
              // Usa context.mounted para verificar se o widget ainda está na árvore
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Estoque de ${product.nome} atualizado!'),
                ),
              );
            }
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
