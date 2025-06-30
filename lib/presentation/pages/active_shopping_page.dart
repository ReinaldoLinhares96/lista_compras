// ignore_for_file: unused_import, unnecessary_brace_in_string_interps, use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/compra_model.dart';
import '../../data/models/item_compra_model.dart';
import '../../data/models/produto_model.dart';
import '../../data/models/orcamento_model.dart';
import '../../data/repositories/compra_repository.dart';
import '../../data/repositories/item_compra_repository.dart';
import '../../data/repositories/produto_repository.dart';
import '../../data/repositories/orcamento_repository.dart';
import '../../core/enums/compra_status_type.dart'; // Para acessar os tipos de status

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

  CompraModel? _compraAtiva;
  OrcamentoModel? _orcamentoAtual;
  List<ProdutoModel> _produtosNecessarios =
      []; // Itens da lista frequente que precisam ser comprados
  List<ProdutoModel> _allProdutos =
      []; // Todos os produtos da lista frequente para busca

  final TextEditingController _itemNomeController = TextEditingController();
  final TextEditingController _itemQuantidadeController =
      TextEditingController();
  final TextEditingController _itemPrecoController = TextEditingController();

  ProdutoModel?
  _selectedProdutoFromList; // Produto selecionado da lista frequente para adicionar ao carrinho

  @override
  void initState() {
    super.initState();
    _listenToCompraAtiva();
    _listenToOrcamento();
    _loadAllProdutos();
  }

  @override
  void dispose() {
    _itemNomeController.dispose();
    _itemQuantidadeController.dispose();
    _itemPrecoController.dispose();
    super.dispose();
  }

  void _listenToCompraAtiva() {
    _compraRepository.getCompraAtiva().listen((compra) {
      setState(() {
        _compraAtiva = compra;
        if (compra != null) {
          _calculateProdutosNecessarios(); // Recalcula os necessários sempre que a compra ou produtos mudam
        }
      });
    });
  }

  void _listenToOrcamento() {
    _orcamentoRepository.getOrcamento().listen((orcamento) {
      setState(() {
        _orcamentoAtual = orcamento;
      });
    });
  }

  void _loadAllProdutos() {
    _produtoRepository.getActiveProdutos().listen((produtos) {
      setState(() {
        _allProdutos = produtos;
        if (_compraAtiva != null) {
          _calculateProdutosNecessarios();
        }
      });
    });
  }

  // Calcula os produtos que precisam ser comprados
  void _calculateProdutosNecessarios() {
    setState(() {
      _produtosNecessarios = _allProdutos
          .where(
            (p) =>
                (p.quantidadeIdealMes - p.quantidadeEmEstoque) >
                0, // Precisa comprar > 0
          )
          .toList();
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

  // Adicionar item ao carrinho
  Future<void> _addItemAoCarrinho({ProdutoModel? produtoFrequente}) async {
    String nome = produtoFrequente?.nome ?? _itemNomeController.text;
    double? quantidade = double.tryParse(
      _itemQuantidadeController.text.replaceAll(',', '.'),
    );
    double? precoUnitario = double.tryParse(
      _itemPrecoController.text.replaceAll(',', '.'),
    );

    if (_compraAtiva == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, inicie uma compra primeiro.')),
      );
      return;
    }

    if (nome.isEmpty ||
        quantidade == null ||
        quantidade <= 0 ||
        precoUnitario == null ||
        precoUnitario <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha todos os campos do item corretamente.'),
        ),
      );
      return;
    }

    try {
      final newItem = ItemCompraModel(
        compraId: _compraAtiva!.id,
        produtoId: produtoFrequente?.id,
        nomeProduto: nome,
        quantidadeComprada: quantidade,
        precoUnitario: precoUnitario,
        ehAvulso: produtoFrequente == null,
      );
      await _itemCompraRepository.addItemCompra(newItem);

      // Atualiza o valor total da compra ativa no Firebase
      final currentTotal = _compraAtiva!.valorTotalCalculado + newItem.subtotal;
      await _compraRepository.updateCompra(
        _compraAtiva!.copyWith(valorTotalCalculado: currentTotal),
      );

      // Limpa os campos do formulário após adicionar
      _itemNomeController.clear();
      _itemQuantidadeController.clear();
      _itemPrecoController.clear();
      setState(() {
        _selectedProdutoFromList = null; // Limpa a seleção da lista
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${nome} adicionado ao carrinho!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao adicionar item: $e')));
      }
    }
  }

  // Remover item do carrinho
  Future<void> _removeItemDoCarrinho(ItemCompraModel item) async {
    try {
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

  // Finalizar compra
  Future<void> _finalizarCompra() async {
    if (_compraAtiva == null) return;

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
        final List<ItemCompraModel> itensComprados =
            (await _itemCompraRepository
                .getItensCompra(_compraAtiva!.id)
                .first);
        for (var item in itensComprados) {
          if (item.produtoId != null) {
            // Se for um produto da lista frequente
            final produtoOriginal = _allProdutos.firstWhere(
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
                    '${produtoOriginal.nome}: Estoque atual (${updatedEstoque.toStringAsFixed(1)}) excede o ideal mensal (${produtoOriginal.quantidadeIdealMes.toStringAsFixed(1)}). Deseja atualizar a Quantidade Ideal para o novo estoque?',
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
                      child: const Text('Não'),
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
                      child: const Text('Sim'),
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

  // Diálogo para adicionar item
  void _showAddItemDialog() {
    _itemNomeController.clear();
    _itemQuantidadeController.clear();
    _itemPrecoController.clear();
    _selectedProdutoFromList = null; // Reseta a seleção

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            return Padding(
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
                  Text(
                    'Adicionar Item ao Carrinho',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 15),
                  // Dropdown para selecionar produtos da lista de "precisa comprar"
                  DropdownButtonFormField<ProdutoModel>(
                    value: _selectedProdutoFromList,
                    hint: const Text('Selecionar item da sua lista (opcional)'),
                    onChanged: (ProdutoModel? newValue) {
                      modalSetState(() {
                        _selectedProdutoFromList = newValue;
                        if (newValue != null) {
                          _itemNomeController.text = newValue.nome;
                          // Preenche a quantidade sugerida se houver
                          _itemQuantidadeController.text =
                              (newValue.quantidadeIdealMes -
                                      newValue.quantidadeEmEstoque)
                                  .toStringAsFixed(1)
                                  .replaceAll('.', ',');
                        } else {
                          _itemNomeController.clear();
                          _itemQuantidadeController.clear();
                        }
                      });
                    },
                    items: _produtosNecessarios.map((produto) {
                      final necessidade =
                          (produto.quantidadeIdealMes -
                                  produto.quantidadeEmEstoque)
                              .toStringAsFixed(1);
                      return DropdownMenuItem<ProdutoModel>(
                        value: produto,
                        child: Text('${produto.nome} (Precisa: $necessidade)'),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _itemNomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome do Item (ou preenchido pela lista)',
                    ),
                    enabled:
                        _selectedProdutoFromList ==
                        null, // Desabilita se um item da lista for selecionado
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _itemQuantidadeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Quantidade'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _itemPrecoController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Preço Unitário',
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _addItemAoCarrinho(
                          produtoFrequente: _selectedProdutoFromList,
                        );
                        Navigator.pop(context); // Fecha o modal após adicionar
                      },
                      child: const Text('Adicionar ao Carrinho'),
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

  @override
  Widget build(BuildContext context) {
    // Calcula o saldo restante e define a cor de alerta
    double saldoRestante =
        (_orcamentoAtual?.valorMaximo ?? 0.0) -
        (_compraAtiva?.valorTotalCalculado ?? 0.0);
    Color saldoColor = Colors.green;
    String saldoAlert = '';
    if (saldoRestante < 0) {
      saldoColor = Colors.red;
      saldoAlert = 'Orçamento Excedido!';
    } else if (saldoRestante < (_orcamentoAtual?.valorMaximo ?? 0.0) * 0.2) {
      // 20% do orçamento
      saldoColor = Colors.orange;
      saldoAlert = 'Atenção ao Orçamento!';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compra Ativa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed:
                _calculateProdutosNecessarios, // Recalcula os itens necessários
            tooltip: 'Atualizar itens necessários',
          ),
          if (_compraAtiva != null &&
              _compraAtiva!.compraStatusId ==
                  CompraStatusType.ativa.value.toString())
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              onPressed: _finalizarCompra,
              tooltip: 'Finalizar Compra',
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
                Text(
                  'Saldo Restante: R\$ ${saldoRestante.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: saldoColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (saldoAlert.isNotEmpty)
                  Text(
                    saldoAlert,
                    style: TextStyle(
                      color: saldoColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child:
                _compraAtiva == null ||
                    _compraAtiva!.compraStatusId !=
                        CompraStatusType.ativa.value.toString()
                ? Center(
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
                  )
                : StreamBuilder<List<ItemCompraModel>>(
                    stream: _itemCompraRepository.getItensCompra(
                      _compraAtiva!.id,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
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
                          child: Text('Nenhum item adicionado ao carrinho.'),
                        );
                      }

                      final itens = snapshot.data!;
                      return ListView.builder(
                        itemCount: itens.length,
                        itemBuilder: (context, index) {
                          final item = itens[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            child: ListTile(
                              title: Text(
                                item.nomeProduto,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${item.quantidadeComprada.toStringAsFixed(1)} x R\$ ${item.precoUnitario.toStringAsFixed(2).replaceAll('.', ',')}',
                              ),
                              trailing: Text(
                                'R\$ ${item.subtotal.toStringAsFixed(2).replaceAll('.', ',')}',
                              ),
                              leading: IconButton(
                                icon: const Icon(
                                  Icons.remove_circle,
                                  color: Colors.red,
                                ),
                                onPressed: () => _removeItemDoCarrinho(item),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton:
          (_compraAtiva != null &&
              _compraAtiva!.compraStatusId ==
                  CompraStatusType.ativa.value.toString())
          ? FloatingActionButton(
              onPressed: _showAddItemDialog,
              child: const Icon(Icons.add_shopping_cart),
            )
          : null, // O FAB só aparece se houver uma compra ativa
    );
  }
}
