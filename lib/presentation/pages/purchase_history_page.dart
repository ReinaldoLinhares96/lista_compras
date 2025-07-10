// ignore_for_file: no_leading_underscores_for_local_identifiers, unused_import, unused_field, prefer_final_fields, unnecessary_brace_in_string_interps

import 'package:flutter/material.dart';
import 'package:lista_compras/data/models/compra_model.dart';
import 'package:lista_compras/data/models/item_compra_model.dart';
import 'package:lista_compras/data/models/produto_model.dart';
import 'package:lista_compras/data/models/categoria_model.dart';
import 'package:lista_compras/data/repositories/compra_repository.dart';
import 'package:lista_compras/data/repositories/item_compra_repository.dart';
import 'package:lista_compras/data/repositories/compra_status_repository.dart';
import 'package:lista_compras/data/repositories/categoria_repository.dart';
import 'package:lista_compras/data/repositories/produto_repository.dart'; // Removido, se não usado

import 'package:lista_compras/presentation/widgets/purchase_history_filter_modal.dart';
import 'package:intl/intl.dart';

class PurchaseHistoryPage extends StatefulWidget {
  const PurchaseHistoryPage({super.key});

  @override
  State<PurchaseHistoryPage> createState() => _PurchaseHistoryPageState();
}

class _PurchaseHistoryPageState extends State<PurchaseHistoryPage> {
  final CompraRepository _compraRepository = CompraRepository();
  final CompraStatusRepository _compraStatusRepository =
      CompraStatusRepository();
  final ItemCompraRepository _itemCompraRepository = ItemCompraRepository();
  final CategoriaRepository _categoriaRepository = CategoriaRepository();
  final ProdutoRepository _produtoRepository = ProdutoRepository();

  Map<String, String> _compraStatusDescricao = {};
  Map<String, String> _categoriasDescricao = {};

  List<ProdutoModel> _allProdutos = [];

  PurchaseFilterData _currentFilters = PurchaseFilterData();

  @override
  void initState() {
    super.initState();
    _loadAuxiliaryData();
  }

  Future<void> _loadAuxiliaryData() async {
    _compraStatusRepository.getCompraStatus().listen((statuses) {
      setState(() {
        _compraStatusDescricao = {for (var s in statuses) s.id: s.descricao};
      });
    });
    _categoriaRepository.getCategorias().listen((categories) {
      setState(() {
        _categoriasDescricao = {for (var c in categories) c.id: c.descricao};
      });
    });
    _produtoRepository.getActiveProdutos().listen((produtos) {
      setState(() {
        _allProdutos = produtos;
      });
    });
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd \'de\' MMMM \'de\' yyyy', 'pt_BR').format(date);
  }

  void _showPurchaseDetailsModal(CompraModel compra) {
    String _itemSearchText = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Detalhes da Compra',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Data: ${_formatDate(compra.dataHoraFim ?? compra.dataHoraInicio)}',
                  ),
                  Text(
                    'Status: ${_compraStatusDescricao[compra.compraStatusId] ?? 'N/A'}',
                  ),
                  Text(
                    'Total: R\$ ${compra.valorTotalCalculado.toStringAsFixed(2).replaceAll('.', ',')}',
                  ),
                  const Divider(),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar produto na lista...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10.0,
                        horizontal: 10.0,
                      ),
                    ),
                    onChanged: (text) {
                      modalSetState(() {
                        _itemSearchText = text;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: FutureBuilder<List<ItemCompraModel>>(
                      // ATUALIZADO: Usar o novo método para itens da compra HISTÓRICA
                      future: _itemCompraRepository
                          .getItensFromHistoricalCompra(compra.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Erro ao carregar itens: ${snapshot.error}',
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text(
                              'Nenhum item encontrado para esta compra.',
                            ),
                          );
                        }

                        List<ItemCompraModel> items = snapshot.data!;

                        if (_itemSearchText.isNotEmpty) {
                          items = items
                              .where(
                                (item) => item.nomeProduto
                                    .toLowerCase()
                                    .contains(_itemSearchText.toLowerCase()),
                              )
                              .toList();
                        }

                        if (items.isEmpty && _itemSearchText.isNotEmpty) {
                          return const Center(
                            child: Text(
                              'Nenhum produto encontrado com este nome.',
                            ),
                          );
                        }

                        Map<String, List<ItemCompraModel>> itemsPorCategoria =
                            {};
                        for (var item in items) {
                          String categoriaDesc = 'Itens Avulsos';
                          if (item.produtoId != null) {
                            final ProdutoModel? prodOriginal = _allProdutos
                                .firstWhereOrNull(
                                  (p) => p.id == item.produtoId,
                                );
                            if (prodOriginal != null) {
                              categoriaDesc =
                                  _categoriasDescricao[prodOriginal
                                      .categoriaId] ??
                                  'Outros da Lista';
                            }
                          }
                          itemsPorCategoria
                              .putIfAbsent(categoriaDesc, () => [])
                              .add(item);
                        }
                        final sortedCategories = itemsPorCategoria.keys.toList()
                          ..sort();

                        if (items.isEmpty) {
                          return const Center(
                            child: Text(
                              'Nenhum item encontrado para esta compra.',
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: sortedCategories.length,
                          itemBuilder: (context, categoryIndex) {
                            final categoria = sortedCategories[categoryIndex];
                            final itemsDaCategoria =
                                itemsPorCategoria[categoria]!;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  child: Text(
                                    categoria,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: itemsDaCategoria.length,
                                  itemBuilder: (context, itemIndex) {
                                    final item = itemsDaCategoria[itemIndex];
                                    return Card(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 0,
                                        vertical: 4,
                                      ),
                                      child: ListTile(
                                        title: Text(item.nomeProduto),
                                        subtitle: Text(
                                          '${item.quantidadeComprada.toString()} x R\$ ${item.precoUnitario.toStringAsFixed(2).replaceAll('.', ',')}',
                                        ),
                                        trailing: Text(
                                          'R\$ ${item.subtotal.toStringAsFixed(2).replaceAll('.', ',')}',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openFilterModal() async {
    final result = await showModalBottomSheet<PurchaseFilterData?>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return PurchaseHistoryFilterModal(initialFilters: _currentFilters);
      },
    );

    if (result != null) {
      setState(() {
        _currentFilters = result;
      });
    } else if (result == null &&
        (_currentFilters.statusId != null ||
            _currentFilters.startDate != null ||
            _currentFilters.endDate != null ||
            _currentFilters.minTotal != null ||
            _currentFilters.maxTotal != null)) {
      setState(() {
        _currentFilters = PurchaseFilterData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Histórico de Compras',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade100,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _openFilterModal,
            tooltip: 'Filtrar Histórico',
          ),
        ],
      ),
      body: StreamBuilder<List<CompraModel>>(
        stream: _compraRepository.getFilteredCompras(
          statusId: _currentFilters.statusId,
          startDate: _currentFilters.startDate,
          endDate: _currentFilters.endDate,
          minTotal: _currentFilters.minTotal,
          maxTotal: _currentFilters.maxTotal,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar histórico: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma compra encontrada com os filtros aplicados.',
              ),
            );
          }

          final compras = snapshot.data!;
          return ListView.builder(
            itemCount: compras.length,
            itemBuilder: (context, index) {
              final compra = compras[index];
              final statusDesc =
                  _compraStatusDescricao[compra.compraStatusId] ?? 'N/A';
              final displayDate = _formatDate(
                compra.dataHoraFim ?? compra.dataHoraInicio,
              );

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                elevation: 2,
                child: ListTile(
                  title: Text('Compra em $displayDate'),
                  subtitle: Text.rich(
                    TextSpan(
                      text: 'Status: ',
                      children: [
                        TextSpan(
                          text: statusDesc,
                          style: TextStyle(
                            color: statusDesc == 'Finalizada'
                                ? Colors.lightGreen
                                : statusDesc == 'Cancelada'
                                ? Colors.red
                                : statusDesc == 'Ativa'
                                ? Colors.blue
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: Text(
                    'R\$ ${compra.valorTotalCalculado.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () => _showPurchaseDetailsModal(compra),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Extensão para firstWhereOrNull em iterables
extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
