// active_shopping_page.dart

// ignore_for_file: unused_import, no_leading_underscores_for_local_identifiers, use_build_context_synchronously, avoid_types_as_parameter_names, deprecated_member_use, prefer_final_fields, unused_field, duplicate_ignore, avoid_print, unnecessary_brace_in_string_interps, await_only_futures

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
import 'dart:developer' as developer;

import 'package:lista_compras/presentation/widgets/add_avulso_modal_form.dart';

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
  List<ProdutoModel> _allProdutosFrequentes = [];
  List<ItemCompraModel> _itensNoCarrinho = [];

  Map<String, String> _unidadesDescricao = {};
  Map<String, String> _unidadesSimbolo = {};
  Map<String, String> _categoriasDescricao = {};
  Map<String, CategoriaModel> _categoriasMap = {};

  bool _panelPrecisaComprarExpanded = true;
  bool _panelNoCarrinhoExpanded = true;

  @override
  void initState() {
    super.initState();
    _listenToAuxiliaryData();
    _listenToCompraAtiva();
    _listenToOrcamento();
    _listenToAllProdutosFrequentes();
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
          _itensNoCarrinho = [];
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
          unidadesDescricao: _unidadesDescricao,
          compraRepository: _compraRepository,
          itemCompraRepository: _itemCompraRepository,
        );
      },
    );
  }

  Future<void> _removeItemFromCarrinho(ItemCompraModel item) async {
    try {
      if (_compraAtiva == null) return;

      await _itemCompraRepository.removeItemCompra(item.id);

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

  Future<void> _addAvulsoToCarrinho() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return AddAvulsoModalForm(
          compraAtiva: _compraAtiva,
          showSnackbar: (message) {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(message)));
            }
          },
          itemCompraRepository: _itemCompraRepository,
          compraRepository: _compraRepository,
        );
      },
    );
  }

  Future<void> _finalizarCompra() async {
    // Manter esta validação inicial.
    // Se _itensNoCarrinho está vazio, _compraAtiva provavelmente também é nulo ou não deveria ser finalizada.
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
      // **CORREÇÃO DEFINITIVA:** CAPTURAR TODOS OS DADOS NECESSÁRIOS *ANTES* DA OPERAÇÃO DO FIREBASE

      // Cópia do ID e valor total da compra ativa atual (não será afetado pelo stream)
      final String idDaCompraFinalizada = _compraAtiva!.id;
      final double valorTotalParaFinalizar = _compraAtiva!.valorTotalCalculado;

      // Cópia da lista de itens do carrinho no momento da finalização
      final List<ItemCompraModel> itensDaCompraParaProcessar = List.from(
        _itensNoCarrinho,
      );

      try {
        developer.log(
          'DEBUG: Entrou no Try para finalizar compra. Compra ID capturado: $idDaCompraFinalizada',
        );

        // 1. FINALIZAR A COMPRA NO BD (isso fará _compraAtiva se tornar null via stream)
        await _compraRepository.finalizarCompra(
          idDaCompraFinalizada, // Usa o ID capturado
          valorTotalParaFinalizar, // Usa o valor capturado
        );
        developer.log(
          'DEBUG: Compra finalizada no BD. ID: $idDaCompraFinalizada. _compraAtiva AGORA É NULL VIA STREAM.',
        );

        // 2. PROCESSAR ITENS E ATUALIZAR ESTOQUE USANDO OS DADOS CAPTURADOS
        developer.log(
          'DEBUG: Processando ${itensDaCompraParaProcessar.length} itens para atualizar estoque.',
        );

        if (itensDaCompraParaProcessar.isEmpty) {
          developer.log(
            'DEBUG: Nao ha itens na lista capturada para atualizar o estoque.',
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Compra finalizada, mas nenhum item para atualizar estoque.',
                ),
              ),
            );
          }
          // Não há mais itens para processar, então podemos sair
          if (mounted) {
            // Garante que o contexto ainda é válido antes de mostrar SnackBar final
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Compra finalizada com sucesso!')),
            );
          }
          developer.log(
            'DEBUG: Fim da finalizacao da compra, sem erros aparentes.',
          );
          return; // Retorna aqui se não houver itens para evitar o loop
        }

        for (var item in itensDaCompraParaProcessar) {
          // ITERAR SOBRE A CÓPIA DA LISTA
          developer.log(
            'DEBUG: Entrou no for, Item: ${item.nomeProduto}, Qtd comprada: ${item.quantidadeComprada}',
          );

          if (item.produtoId != null) {
            final ProdutoModel? produtoOriginal = _allProdutosFrequentes
                .firstWhereOrNull((p) => p.id == item.produtoId);

            if (produtoOriginal == null) {
              developer.log(
                'DEBUG: PRODUTO ORIGINAL NAO ENCONTRADO PARA ITEM ${item.nomeProduto}. Pulando atualizacao de estoque.',
              );
              continue;
            }

            // Promoção de tipo: 'produtoOriginal' é garantido como não-nulo aqui
            final updatedEstoque =
                produtoOriginal.quantidadeEmEstoque + item.quantidadeComprada;

            developer.log(
              'DEBUG: updatedEstoque: ${updatedEstoque.toStringAsFixed(1)}',
            );
            developer.log(
              'DEBUG: quantidadeIdealMes: ${produtoOriginal.quantidadeIdealMes.toStringAsFixed(1)}',
            );

            ProdutoModel produtoParaAtualizar = produtoOriginal.copyWith(
              quantidadeEmEstoque: updatedEstoque,
              updatedAt: DateTime.now(),
            );

            if (updatedEstoque > produtoOriginal.quantidadeIdealMes) {
              final bool? updateIdeal = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Estoque Excedente!'),
                  content: Text(
                    '${produtoOriginal.nome}: Estoque atual (${updatedEstoque.toStringAsFixed(1)}) excede o ideal mensal (${produtoOriginal.quantidadeIdealMes.toStringAsFixed(1)}).\nVocê poderá ajustar a quantidade ideal agora ou posteriormente na lista de produtos.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                      child: const Text('Atualizar Ideal'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                      child: const Text('Não Atualizar Ideal'),
                    ),
                  ],
                ),
              );
              if (updateIdeal == true) {
                produtoParaAtualizar = produtoParaAtualizar.copyWith(
                  quantidadeIdealMes: updatedEstoque,
                );
                developer.log(
                  'DEBUG: Usuario escolheu atualizar ideal tambem.',
                );
              } else {
                developer.log('DEBUG: Usuario escolheu NAO atualizar ideal.');
              }
            }

            developer.log(
              'DEBUG: Chamando updateProduto para ${produtoOriginal.nome} com estoque ${produtoParaAtualizar.quantidadeEmEstoque}',
            );
            await _produtoRepository.updateProduto(produtoParaAtualizar);
            developer.log(
              'DEBUG: updateProduto chamado para ${produtoOriginal.nome}.',
            );
          } else {
            developer.log(
              'DEBUG: Item ${item.nomeProduto} eh avulso, estoque nao sera atualizado.',
            );
          }
        }

        // SnackBar final de sucesso, movida para cá para garantir que sempre apareça após tudo
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Compra finalizada com sucesso!')),
          );
        }
        developer.log(
          'DEBUG: Fim da finalizacao da compra, sem erros aparentes.',
        );
      } catch (e, stackTrace) {
        developer.log(
          'DEBUG: Erro ao finalizar compra: $e\nStackTrace: $stackTrace',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao finalizar compra: $e')),
          );
        }
      }
    }
  }

  // NOVO: Método para cancelar a compra
  Future<void> _cancelarCompra() async {
    // A compra só pode ser cancelada se estiver ativa e não for nula
    if (_compraAtiva == null ||
        _compraAtiva!.compraStatusId !=
            CompraStatusType.ativa.value.toString()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma compra ativa para cancelar.')),
      );
      return;
    }

    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Cancelamento'),
        content: const Text(
          'Tem certeza que deseja cancelar esta compra? Todos os itens serão removidos do carrinho.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Não'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sim, Cancelar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        developer.log(
          'DEBUG: Iniciando cancelamento da compra ID: ${_compraAtiva!.id}',
        );
        // Chama o método de cancelar compra no repositório
        await _compraRepository.cancelarCompra(_compraAtiva!.id);
        developer.log('DEBUG: Compra cancelada no BD.');

        // Opcional: Você pode querer remover os itens do carrinho também aqui
        // Embora o status da compra mude, os itens ainda ficam associados a ela.
        // Se a regra de negócio for limpar o carrinho ao cancelar:
        final List<ItemCompraModel> itensParaRemover = List.from(
          _itensNoCarrinho,
        );
        for (var item in itensParaRemover) {
          await _itemCompraRepository.removeItemCompra(item.id);
        }
        developer.log('DEBUG: Itens do carrinho removidos após cancelamento.');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Compra cancelada com sucesso!')),
          );
        }
      } catch (e, stackTrace) {
        developer.log(
          'DEBUG: Erro ao cancelar compra: $e\nStackTrace: $stackTrace',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao cancelar compra: $e')),
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
    final List<ProdutoModel> produtosPrecisaComprar = _allProdutosFrequentes
        .where((p) {
          double currentStock = p.quantidadeEmEstoque;
          double quantityInCart = _itensNoCarrinho
              .where((item) => item.produtoId == p.id)
              .fold(0.0, (sum, item) => sum + item.quantidadeComprada);

          return (p.quantidadeIdealMes - currentStock - quantityInCart) > 0;
        })
        .toList();

    final Map<String, List<ItemCompraModel>> itensNoCarrinhoPorCategoria = {};
    for (var item in _itensNoCarrinho) {
      String categoriaDesc = 'Itens Avulsos';
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
        // AppBar agora está aqui
        title: Text(
          'Saldo: R\$ ${saldoRestante.toStringAsFixed(2).replaceAll('.', ',')}',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(color: Colors.blueGrey),
        ),
        centerTitle: false,
        backgroundColor: Colors.blue.shade100,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: Colors.blueGrey),
            onPressed: _addAvulsoToCarrinho,
            tooltip: 'Adicionar Item Avulso',
          ),
          if (_compraAtiva != null &&
              _compraAtiva!.compraStatusId ==
                  CompraStatusType.ativa.value.toString())
            IconButton(
              icon: const Icon(
                Icons.cancel_outlined,
                color: Colors.orange,
              ), // Ícone de cancelar
              onPressed: _cancelarCompra,
              tooltip: 'Cancelar Compra',
            )
          else // Botão desabilitado se não houver compra ativa
            IconButton(
              icon: Icon(Icons.cancel_outlined, color: Colors.grey[400]),
              onPressed: null,
              tooltip: 'Nenhuma compra ativa para cancelar',
            ),
          if (_compraAtiva != null &&
              _compraAtiva!.compraStatusId ==
                  CompraStatusType.ativa.value.toString() &&
              _itensNoCarrinho.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.check_circle_outline, color: Colors.green),
              onPressed: _finalizarCompra,
              tooltip: 'Finalizar Compra',
            )
          else if (_compraAtiva != null &&
              _compraAtiva!.compraStatusId ==
                  CompraStatusType.ativa.value.toString())
            IconButton(
              icon: Icon(Icons.check_circle_outline, color: Colors.grey[400]),
              onPressed: null,
              tooltip: 'Carrinho vazio para finalizar',
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 20.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total No Carrinho',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'R\$ ${_compraAtiva?.valorTotalCalculado.toStringAsFixed(2).replaceAll('.', ',') ?? '0,00'}',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          _compraAtiva == null ||
                  _compraAtiva!.compraStatusId !=
                      CompraStatusType.ativa.value.toString()
              ? Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Nenhuma compra ativa no momento.',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 15),
                        ElevatedButton.icon(
                          onPressed: _iniciarCompra,
                          icon: const Icon(Icons.shopping_cart),
                          label: const Text(
                            'Iniciar Nova Compra',
                            style: TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(8.0),
                    children: [
                      ExpansionPanelList(
                        elevation: 4,
                        expandedHeaderPadding: EdgeInsets.zero,
                        animationDuration: const Duration(milliseconds: 400),
                        expansionCallback: (panelIndex, isExpanded) {
                          // CORREÇÃO: Atribuir diretamente o isExpanded
                          setState(() {
                            _panelPrecisaComprarExpanded = isExpanded;
                          });
                        },
                        children: [
                          ExpansionPanel(
                            headerBuilder: (context, isExpanded) {
                              return ListTile(
                                title: Text(
                                  'Precisa Comprar (${produtosPrecisaComprar.length})',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepOrange,
                                      ),
                                ),
                              );
                            },
                            body: produtosPrecisaComprar.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Text(
                                      'Você não precisa comprar mais nenhum item da lista! 🎉',
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey,
                                      ),
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
                                      final quantidadeCalculada =
                                          (produto.quantidadeIdealMes -
                                          produto.quantidadeEmEstoque -
                                          _itensNoCarrinho
                                              .where(
                                                (item) =>
                                                    item.produtoId ==
                                                    produto.id,
                                              )
                                              .fold(
                                                0.0,
                                                (sum, item) =>
                                                    sum +
                                                    item.quantidadeComprada,
                                              ));
                                      final unidade =
                                          _unidadesSimbolo[produto
                                              .unidadeMedidaId] ??
                                          'N/A';

                                      final displayQuantidade =
                                          quantidadeCalculada > 0
                                          ? quantidadeCalculada.toStringAsFixed(
                                              1,
                                            )
                                          : '0.0';

                                      return Card(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        elevation: 2,
                                        child: ListTile(
                                          title: Text(
                                            produto.nome,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          subtitle: Text(
                                            'Comprar: $displayQuantidade $unidade',
                                            style: const TextStyle(
                                              color: Colors.red,
                                            ),
                                          ),
                                          trailing: IconButton(
                                            icon: const Icon(
                                              Icons.add_circle,
                                              color: Colors.green,
                                              size: 30,
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
                      ExpansionPanelList(
                        elevation: 4,
                        expandedHeaderPadding: EdgeInsets.zero,
                        animationDuration: const Duration(milliseconds: 400),
                        expansionCallback: (panelIndex, isExpanded) {
                          // CORREÇÃO: Atribuir diretamente o isExpanded
                          setState(() {
                            _panelNoCarrinhoExpanded = isExpanded;
                          });
                        },
                        children: [
                          ExpansionPanel(
                            headerBuilder: (context, isExpanded) {
                              return ListTile(
                                title: Text(
                                  'No Carrinho (${_itensNoCarrinho.length})',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700,
                                      ),
                                ),
                              );
                            },
                            body: _itensNoCarrinho.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Text(
                                      'Nenhum item adicionado ao carrinho ainda.',
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey,
                                      ),
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
                                                    color: Colors.grey[800],
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
                                                elevation: 2,
                                                child: ListTile(
                                                  title: Text(
                                                    item.nomeProduto,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  subtitle: Text(
                                                    '${item.quantidadeComprada.toStringAsFixed(1)} x R\$ ${item.precoUnitario.toStringAsFixed(2).replaceAll('.', ',')}',
                                                    style: const TextStyle(
                                                      color: Colors.blueGrey,
                                                    ),
                                                  ),
                                                  trailing: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        'R\$ ${item.subtotal.toStringAsFixed(2).replaceAll('.', ',')}',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.black87,
                                                        ),
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.remove_circle,
                                                          color: Colors.red,
                                                          size: 28,
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
    );
  }
}

extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
