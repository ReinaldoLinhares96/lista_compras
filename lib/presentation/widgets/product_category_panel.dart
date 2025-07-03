// ignore_for_file: unused_import, unused_local_variable

import 'package:flutter/material.dart';
import '../../data/models/produto_model.dart';
// import '../../data/repositories/produto_repository.dart'; // Removido, pois o callback já faz isso
import '../../data/models/unidade_medida_model.dart'; // Para descrições

// Define um typedef para os callbacks de ação nos produtos
typedef ProductActionCallback = void Function(ProdutoModel product);

class ProductCategoryPanel extends StatefulWidget {
  final String categoryName;
  final List<ProdutoModel> productsInCategory;
  final Map<String, String> unidadesDescricao;
  final Map<String, String> unidadesSimbolo; // NOVO: Propriedade para símbolos
  final ProductActionCallback onEditProduct;
  final ProductActionCallback onDeleteProduct;
  final ProductActionCallback onUpdateStock;
  final bool isExpanded; // Controla o estado de expansão
  final ValueChanged<bool>
  onExpansionChanged; // Notifica o pai sobre a expansão

  const ProductCategoryPanel({
    super.key,
    required this.categoryName,
    required this.productsInCategory,
    required this.unidadesDescricao,
    required this.unidadesSimbolo, // NOVO: Requisito
    required this.onEditProduct,
    required this.onDeleteProduct,
    required this.onUpdateStock,
    required this.isExpanded,
    required this.onExpansionChanged,
  });

  @override
  State<ProductCategoryPanel> createState() => _ProductCategoryPanelState();
}

class _ProductCategoryPanelState extends State<ProductCategoryPanel> {
  @override
  Widget build(BuildContext context) {
    return ExpansionPanelList(
      expansionCallback: (panelIndex, isExpanded) {
        widget.onExpansionChanged(isExpanded); // Notifica o pai
      },
      children: [
        ExpansionPanel(
          headerBuilder: (context, isExpanded) {
            return ListTile(
              title: Text(
                widget.categoryName,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            );
          },
          body: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.productsInCategory.length,
            itemBuilder: (context, productIndex) {
              final produto = widget.productsInCategory[productIndex];
              // final unidadeDescricao = widget.unidadesDescricao[produto.unidadeMedidaId] ?? 'N/A'; // Não mais usado diretamente
              final unidadeSimbolo =
                  widget.unidadesSimbolo[produto.unidadeMedidaId] ??
                  'N/A'; // Usando o símbolo
              final double quantidadeParaComprar =
                  produto.quantidadeIdealMes - produto.quantidadeEmEstoque;

              Color? itemBackgroundColor;
              if (quantidadeParaComprar > 0) {
                itemBackgroundColor = Colors.red[50];
              } else {
                itemBackgroundColor = Colors.green[50];
              }

              return Card(
                color: itemBackgroundColor,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text(
                    produto.nome,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ideal p/ Mês: ${produto.quantidadeIdealMes.toStringAsFixed(1)} $unidadeSimbolo',
                      ),
                      Text(
                        'Em Estoque: ${produto.quantidadeEmEstoque.toStringAsFixed(1)} $unidadeSimbolo',
                      ),
                      quantidadeParaComprar > 0
                          ? Text(
                              'Precisa Comprar: ${quantidadeParaComprar.toStringAsFixed(1)} $unidadeSimbolo',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : Text(
                              'Estoque Completo',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                      if (quantidadeParaComprar > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning,
                                color: Colors.red[700],
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Recomenda-se comprar!',
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.inventory, color: Colors.blue),
                        onPressed: () =>
                            widget.onUpdateStock(produto), // Chama o callback
                        tooltip: 'Atualizar Estoque',
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () =>
                            widget.onEditProduct(produto), // Chama o callback
                        tooltip: 'Editar Produto',
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_forever,
                          color: Colors.red,
                        ),
                        onPressed: () async {
                          final bool? confirm = await showDialog(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Confirmar Exclusão'),
                              content: Text(
                                'Tem certeza que deseja remover ${produto.nome}?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(true),
                                  child: const Text('Remover'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            widget.onDeleteProduct(produto); // Chama o callback
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${produto.nome} removido!'),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          isExpanded: widget.isExpanded,
        ),
      ],
    );
  }
}
