// active_shopping_page.dart
// Ignore as linhas que você já tem no arquivo original, o importante são as seções alteradas

// ignore_for_file: unused_import, no_leading_underscores_for_local_identifiers, use_build_context_synchronously, avoid_types_as_parameter_names, deprecated_member_use, prefer_final_fields, unused_field

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lista_compras/data/models/categoria_model.dart';
import 'package:lista_compras/presentation/widgets/add_frequent_product_to_cart_modal.dart';
import '../../data/models/compra_model.dart';
import '../../data/models/item_compra_model.dart';
import '../../data/models/produto_model.dart';
import '../../data/models/orcamento_model.dart';
import '../../data/repositories/compra_repository.dart';
import '../../data/repositories/item_compra_repository.dart';
import '../../data/repositories/produto_repository.dart';
import '../../data/repositories/orcamento_repository.dart';
import '../../data/repositories/unidade_medida_repository.dart'; // Para descrições
import '../../data/repositories/categoria_repository.dart'; // Para descrições
import '../../core/enums/compra_status_type.dart';
// Importe os novos widgets dos modais
import 'package:lista_compras/presentation/widgets/add_edit_product_modal_form.dart';
import 'package:lista_compras/presentation/widgets/add_avulso_modal_form.dart'; // Importe este

class ActiveShoppingPage extends StatefulWidget {
  const ActiveShoppingPage({super.key});

  @override
  State<ActiveShoppingPage> createState() => _ActiveShoppingPageState();
}

class _ActiveShoppingPageState extends State<ActiveShoppingPage> {
  final CompraRepository _compraRepository = CompraRepository();
  final ItemCompraRepository _itemCompraRepository = ItemCompraRepository();
  final ProdutoRepository _produtoRepository = ProdutoRepository();
  final OrcamentoRepository _orcamentoRepository = OrcamentoRepository();
  final UnidadeMedidaRepository _unidadeMedidaRepository =
      UnidadeMedidaRepository();
  final CategoriaRepository _categoriaRepository = CategoriaRepository();

  CompraModel? _compraAtiva;
  OrcamentoModel? _orcamentoAtual;
  List<ProdutoModel> _allProdutosFrequentes =
      []; // Todos os produtos da lista frequente
  List<ItemCompraModel> _itensNoCarrinho =
      []; // Itens que estão no carrinho virtual da compra ativa

  Map<String, String> _unidadesDescricao = {};
  Map<String, String> _unidadesSimbolo = {};
  Map<String, String> _categoriasDescricao = {};
  Map<String, CategoriaModel> _categoriasMap = {};

  // Para gerenciar o estado dos ExpansionPanelList
  bool _panelPrecisaComprarExpanded = true;
  bool _panelNoCarrinhoExpanded = true;

  @override
  void initState() {
    super.initState();
    _listenToAuxiliaryData();
    _listenToCompraAtiva();
    _listenToOrcamento();
    _listenToAllProdutosFrequentes(); // Escuta todos os produtos frequentes
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _listenToAuxiliaryData() {
    _unidadeMedidaRepository.getUnidadesMedida().listen((unidades) {
      setState(() {
        _unidadesDescricao = {for (var u in unidades) u.id: u.descricao};
        _unidadesSimbolo = {for (var u in unidades) u.id: u.simbolo};
      });
    });
    _categoriaRepository.getCategorias().listen((categorias) {
      setState(() {
        _categoriasDescricao = {for (var c in categorias) c.id: c.descricao};
      });
    });
    _categoriaRepository.getCategorias().listen((categorias) {
      setState(() {
        _categoriasMap = {for (var c in categorias) c.id: c};
      });
    });
  }

  void _listenToCompraAtiva() {
    _compraRepository.getCompraAtiva().listen((compra) {
      setState(() {
        _compraAtiva = compra;
      });
      if (compra != null) {
        _itemCompraRepository.getItensCompra(compra.id).listen((itens) {
          setState(() {
            _itensNoCarrinho = itens;
          });
        });
      } else {
        setState(() {
          _itensNoCarrinho = []; // Limpa se não houver compra ativa
        });
      }
    });
  }

  void _listenToOrcamento() {
    _orcamentoRepository.getOrcamento().listen((orcamento) {
      setState(() {
        _orcamentoAtual = orcamento;
      });
    });
  }

  void _listenToAllProdutosFrequentes() {
    _produtoRepository.getActiveProdutos().listen((produtos) {
      setState(() {
        _allProdutosFrequentes = produtos;
      });
    });
  }

  // Iniciar uma nova compra
  Future<void> _iniciarCompra() async {
    try {
      await _compraRepository.iniciarNovaCompra();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Nova compra iniciada!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao iniciar compra: $e')));
      }
    }
  }

  // CORREÇÃO: Chama o novo modal AddFrequentProductToCartModal
  Future<void> _addProdutoFrequenteToCarrinho(ProdutoModel produto) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return AddFrequentProductToCartModal(
          product: produto,
          activePurchase: _compraAtiva,
          showSnackbar: (message) {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(message)));
            }
          },
          unidadesDescricao:
              _unidadesDescricao, // Passa as descrições das unidades
          compraRepository: _compraRepository,
          itemCompraRepository: _itemCompraRepository,
        );
      },
    );
  }

  // Remover item do carrinho
  Future<void> _removeItemFromCarrinho(ItemCompraModel item) async {
    try {
      if (_compraAtiva == null) return;

      await _itemCompraRepository.removeItemCompra(item.id);

      // Recalcula o total da compra e atualiza no Firebase
      final currentTotal = _compraAtiva!.valorTotalCalculado - item.subtotal;
      await _compraRepository.updateCompra(
        _compraAtiva!.copyWith(valorTotalCalculado: currentTotal),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.nomeProduto} removido do carrinho.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao remover item: $e')));
      }
    }
  }

  // Adicionar item avulso ao carrinho
  Future<void> _addAvulsoToCarrinho() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        // Use o novo widget para o formulário avulso
        return AddAvulsoModalForm(
          compraAtiva: _compraAtiva,
          showSnackbar: (message) {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(message)));
            }
          },
        );
      },
    ); // whenComplete não é necessário aqui
  }

  // Finalizar compra (mantido o fluxo existente, mas aprimorado)
  Future<void> _finalizarCompra() async {
    if (_compraAtiva == null || _itensNoCarrinho.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum item no carrinho para finalizar a compra.'),
        ),
      );
      return;
    }

    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Finalização'),
        content: Text(
          'Deseja finalizar esta compra? O valor total será R\$ ${_compraAtiva!.valorTotalCalculado.toStringAsFixed(2).replaceAll('.', ',')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _compraRepository.finalizarCompra(
          _compraAtiva!.id,
          _compraAtiva!.valorTotalCalculado,
        );

        // Atualizar QuantidadeEmEstoque dos produtos da lista frequente
        for (var item in _itensNoCarrinho) {
          if (item.produtoId != null) {
            // Se for um produto da lista frequente
            final produtoOriginal = _allProdutosFrequentes.firstWhere(
              (p) => p.id == item.produtoId,
            );
            final updatedEstoque =
                produtoOriginal.quantidadeEmEstoque + item.quantidadeComprada;

            // Lógica para notificar e atualizar Quantidade Ideal, se exceder
            if (updatedEstoque > produtoOriginal.quantidadeIdealMes) {
              await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Estoque Excedente!'),
                  content: Text(
                    '${produtoOriginal.nome}: Estoque atual (${updatedEstoque.toStringAsFixed(1)}) excede o ideal mensal (${produtoOriginal.quantidadeIdealMes.toStringAsFixed(1)}).\nVocê poderá ajustar a quantidade ideal agora ou posteriormente na lista de produtos.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        // Atualiza apenas o estoque
                        _produtoRepository.updateProduto(
                          produtoOriginal.copyWith(
                            quantidadeEmEstoque: updatedEstoque,
                            updatedAt: DateTime.now(),
                          ),
                        );
                        Navigator.of(context).pop();
                      },
                      child: const Text('Não Atualizar Ideal'),
                    ),
                    TextButton(
                      onPressed: () {
                        // Atualiza estoque E ideal
                        _produtoRepository.updateProduto(
                          produtoOriginal.copyWith(
                            quantidadeEmEstoque: updatedEstoque,
                            quantidadeIdealMes: updatedEstoque,
                            updatedAt: DateTime.now(),
                          ),
                        );
                        Navigator.of(context).pop();
                      },
                      child: const Text('Atualizar Ideal'),
                    ),
                  ],
                ),
              );
            } else {
              // Apenas atualiza o estoque se não exceder
              await _produtoRepository.updateProduto(
                produtoOriginal.copyWith(
                  quantidadeEmEstoque: updatedEstoque,
                  updatedAt: DateTime.now(),
                ),
              );
            }
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Compra finalizada com sucesso!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao finalizar compra: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double saldoRestante =
        (_orcamentoAtual?.valorMaximo ?? 0.0) -
        (_compraAtiva?.valorTotalCalculado ?? 0.0);
    Color saldoColor = Colors.green;
    String saldoAlert = '';
    IconData? saldoIcon;

    if (saldoRestante < 0) {
      saldoColor = Colors.red;
      saldoAlert = 'Orçamento Excedido!';
      saldoIcon = Icons.error;
    } else if (saldoRestante < (_orcamentoAtual?.valorMaximo ?? 0.0) * 0.2 &&
        (_orcamentoAtual?.valorMaximo ?? 0) > 0) {
      saldoColor = Colors.orange;
      saldoAlert = 'Atenção ao Orçamento!';
      saldoIcon = Icons.warning;
    }

    // Produtos que precisam ser comprados (calculados com base no estoque e nos itens no carrinho)
    final List<ProdutoModel> produtosPrecisaComprar = _allProdutosFrequentes
        .where((p) {
          // Quantidade no estoque que o usuário TEM
          double currentStock = p.quantidadeEmEstoque;
          // Quantidade deste produto já "no carrinho" na sessão atual
          double quantityInCart = _itensNoCarrinho
              .where((item) => item.produtoId == p.id)
              .fold(0.0, (sum, item) => sum + item.quantidadeComprada);

          // A necessidade real agora considera o que já está no carrinho
          return (p.quantidadeIdealMes - currentStock - quantityInCart) > 0;
        })
        .toList();

    // Organiza os itens no carrinho por categoria para exibição
    final Map<String, List<ItemCompraModel>> itensNoCarrinhoPorCategoria = {};
    for (var item in _itensNoCarrinho) {
      String categoriaDesc = 'Itens Avulsos'; // Padrão para avulsos
      if (item.produtoId != null) {
        final produtoFreq = _allProdutosFrequentes.firstWhereOrNull(
          (p) => p.id == item.produtoId,
        );
        if (produtoFreq != null) {
          categoriaDesc =
              _categoriasDescricao[produtoFreq.categoriaId] ??
              'Outros da Lista';
        }
      }
      itensNoCarrinhoPorCategoria
          .putIfAbsent(categoriaDesc, () => [])
          .add(item);
    }
    final sortedItensNoCarrinhoCategories =
        itensNoCarrinhoPorCategoria.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compra Ativa'),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_box_outlined,
            ), // Ícone para adicionar avulso
            onPressed: _addAvulsoToCarrinho,
            tooltip: 'Adicionar Item Avulso',
          ),
          if (_compraAtiva != null &&
              _compraAtiva!.compraStatusId ==
                  CompraStatusType.ativa.value.toString() &&
              _itensNoCarrinho.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              onPressed: _finalizarCompra,
              tooltip: 'Finalizar Compra',
            )
          else if (_compraAtiva != null &&
              _compraAtiva!.compraStatusId ==
                  CompraStatusType.ativa.value.toString())
            IconButton(
              // Ícone desabilitado quando carrinho está vazio
              icon: Icon(Icons.check_circle_outline, color: Colors.grey[400]),
              onPressed: null, // Desabilitado
              tooltip: 'Carrinho vazio para finalizar',
            ),
        ],
      ),
      body: Column(
        children: [
          // Seção de Status do Orçamento e Compra
          Container(
            padding: const EdgeInsets.all(16.0),
            color: saldoColor.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Orçamento Atual: R\$ ${_orcamentoAtual?.valorMaximo.toStringAsFixed(2).replaceAll('.', ',') ?? '0,00'}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'Total no Carrinho: R\$ ${_compraAtiva?.valorTotalCalculado.toStringAsFixed(2).replaceAll('.', ',') ?? '0,00'}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Text(
                      'Saldo Restante: R\$ ${saldoRestante.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: saldoColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (saldoIcon != null) ...[
                      const SizedBox(width: 8),
                      Icon(saldoIcon, color: saldoColor),
                    ],
                  ],
                ),
                if (saldoAlert.isNotEmpty)
                  Text(
                    saldoAlert,
                    style: TextStyle(
                      color: saldoColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          // Condição para exibir "Nenhuma compra ativa" ou os painéis
          _compraAtiva == null ||
                  _compraAtiva!.compraStatusId !=
                      CompraStatusType.ativa.value.toString()
              ? Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Nenhuma compra ativa no momento.'),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: _iniciarCompra,
                          icon: const Icon(Icons.shopping_cart),
                          label: const Text('Iniciar Nova Compra'),
                        ),
                      ],
                    ),
                  ),
                )
              : Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(8.0),
                    children: [
                      // Painel "Precisa Comprar"
                      ExpansionPanelList(
                        expansionCallback: (panelIndex, isExpanded) {
                          setState(() {
                            _panelPrecisaComprarExpanded =
                                !_panelPrecisaComprarExpanded;
                          });
                        },
                        children: [
                          ExpansionPanel(
                            headerBuilder: (context, isExpanded) {
                              return ListTile(
                                title: Text(
                                  'Precisa Comprar (${produtosPrecisaComprar.length})',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              );
                            },
                            body: produtosPrecisaComprar.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Text(
                                      'Você não precisa comprar mais nenhum item da lista! 🎉',
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: produtosPrecisaComprar.length,
                                    itemBuilder: (context, index) {
                                      final produto =
                                          produtosPrecisaComprar[index];
                                      final quantidade =
                                          (produto.quantidadeIdealMes -
                                                  produto.quantidadeEmEstoque)
                                              .toStringAsFixed(1);
                                      final unidade =
                                          _unidadesSimbolo[produto
                                              .unidadeMedidaId] ??
                                          'N/A';
                                      return Card(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        child: ListTile(
                                          title: Text(produto.nome),
                                          subtitle: Text(
                                            'Comprar: $quantidade $unidade',
                                          ),
                                          trailing: IconButton(
                                            icon: const Icon(
                                              Icons.add_circle,
                                              color: Colors.green,
                                            ),
                                            onPressed: () =>
                                                _addProdutoFrequenteToCarrinho(
                                                  produto,
                                                ),
                                            tooltip: 'Adicionar ao carrinho',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                            isExpanded: _panelPrecisaComprarExpanded,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Painel "No Carrinho"
                      ExpansionPanelList(
                        expansionCallback: (panelIndex, isExpanded) {
                          setState(() {
                            _panelNoCarrinhoExpanded =
                                !_panelNoCarrinhoExpanded;
                          });
                        },
                        children: [
                          ExpansionPanel(
                            headerBuilder: (context, isExpanded) {
                              return ListTile(
                                title: Text(
                                  'No Carrinho (${_itensNoCarrinho.length})',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              );
                            },
                            body: _itensNoCarrinho.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Text(
                                      'Nenhum item adicionado ao carrinho ainda.',
                                    ),
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: sortedItensNoCarrinhoCategories.map((
                                      categoria,
                                    ) {
                                      final itensDaCategoria =
                                          itensNoCarrinhoPorCategoria[categoria]!;
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 16.0,
                                              top: 8.0,
                                              bottom: 4.0,
                                            ),
                                            child: Text(
                                              categoria,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ),
                                          ListView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            itemCount: itensDaCategoria.length,
                                            itemBuilder: (context, index) {
                                              final item =
                                                  itensDaCategoria[index];
                                              return Card(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                child: ListTile(
                                                  title: Text(item.nomeProduto),
                                                  subtitle: Text(
                                                    '${item.quantidadeComprada.toStringAsFixed(1)} x R\$ ${item.precoUnitario.toStringAsFixed(2).replaceAll('.', ',')}',
                                                  ),
                                                  trailing: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        'R\$ ${item.subtotal.toStringAsFixed(2).replaceAll('.', ',')}',
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.remove_circle,
                                                          color: Colors.red,
                                                        ),
                                                        onPressed: () =>
                                                            _removeItemFromCarrinho(
                                                              item,
                                                            ),
                                                        tooltip:
                                                            'Remover do carrinho',
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                            isExpanded: _panelNoCarrinhoExpanded,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ],
      ),
      floatingActionButton:
          (_compraAtiva != null &&
              _compraAtiva!.compraStatusId ==
                  CompraStatusType.ativa.value.toString())
          ? FloatingActionButton.extended(
              onPressed: _addAvulsoToCarrinho, // FAB para adicionar avulso
              label: const Text('Item Avulso'),
              icon: const Icon(Icons.add),
            )
          : null,
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat, // Centraliza o FAB
    );
  }
}

// Extensão para firstWhereOrNull em listas, para evitar erro se item não for encontrado
extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
