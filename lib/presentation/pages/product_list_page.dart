// ... imports existentes

// ignore_for_file: unused_field, no_leading_underscores_for_local_identifiers, use_build_context_synchronously, unused_import, unused_element

// Importe a página de orçamento
import 'package:flutter/material.dart';
import 'package:lista_compras/data/models/categoria_model.dart';
import 'package:lista_compras/data/models/orcamento_model.dart';
import 'package:lista_compras/data/models/produto_model.dart';
import 'package:lista_compras/data/models/unidade_medida_model.dart';
import 'package:lista_compras/data/repositories/categoria_repository.dart';
import 'package:lista_compras/data/repositories/orcamento_repository.dart';
import 'package:lista_compras/data/repositories/produto_repository.dart';
import 'package:lista_compras/data/repositories/unidade_medida_repository.dart';
import 'package:lista_compras/presentation/pages/active_shopping_page.dart'; // Importe a nova página
import '/presentation/pages/orcamento_page.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final ProdutoRepository _produtoRepository = ProdutoRepository();
  final UnidadeMedidaRepository _unidadeMedidaRepository =
      UnidadeMedidaRepository();
  final CategoriaRepository _categoriaRepository = CategoriaRepository();
  // Novo: Repositório de orçamento
  final OrcamentoRepository _orcamentoRepository = OrcamentoRepository();

  Map<String, String> _unidadesDescricao = {};
  Map<String, String> _categoriasDescricao = {};

  // Controlador para as páginas no BottomNavigationBar
  int _selectedIndex = 0;
  late PageController _pageController; // Será inicializado no initState

  // Objeto de orçamento para exibir na dashboard
  OrcamentoModel? _currentOrcamento;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _loadAuxiliaryData();
    // Escuta o orçamento para exibir na dashboard
    _orcamentoRepository.getOrcamento().listen((orcamento) {
      setState(() {
        _currentOrcamento = orcamento;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(
      index,
    ); // ou animateToPage para uma transição suave
  }

  // Carrega as descrições das unidades de medida e categorias
  Future<void> _loadAuxiliaryData() async {
    _unidadeMedidaRepository.getUnidadesMedida().listen((unidades) {
      setState(() {
        _unidadesDescricao = {for (var u in unidades) u.id: u.descricao};
      });
    });

    _categoriaRepository.getCategorias().listen((categorias) {
      setState(() {
        _categoriasDescricao = {for (var c in categorias) c.id: c.descricao};
      });
    });
  }

  // Novo: Método para exibir o diálogo de atualização de estoque
  void _showUpdateStockDialog(ProdutoModel produto) {
    final TextEditingController _stockController = TextEditingController(
      text: produto.quantidadeEmEstoque.toStringAsFixed(1).replaceAll('.', ','),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Atualizar Estoque de ${produto.nome}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ideal p/ Mês: ${produto.quantidadeIdealMes.toStringAsFixed(1)} ${_unidadesDescricao[produto.unidadeMedidaId] ?? 'N/A'}',
              ),
              TextField(
                controller: _stockController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
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

                // Lógica de notificação de excedente e atualização da quantidade ideal
                if (novaQuantidade > produto.quantidadeIdealMes) {
                  final bool? updateIdeal = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Estoque Excedente!'),
                      content: Text(
                        '${produto.nome}: Novo estoque (${novaQuantidade.toStringAsFixed(1)}) excede o ideal mensal (${produto.quantidadeIdealMes.toStringAsFixed(1)}). Deseja atualizar a Quantidade Ideal para o novo estoque?',
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
                    await _produtoRepository.updateProduto(
                      produto.copyWith(
                        quantidadeEmEstoque: novaQuantidade,
                        quantidadeIdealMes:
                            novaQuantidade, // Atualiza o ideal também
                        updatedAt: DateTime.now(),
                      ),
                    );
                  } else {
                    // Atualiza apenas o estoque
                    await _produtoRepository.updateProduto(
                      produto.copyWith(
                        quantidadeEmEstoque: novaQuantidade,
                        updatedAt: DateTime.now(),
                      ),
                    );
                  }
                } else {
                  // Apenas atualiza o estoque se não exceder
                  await _produtoRepository.updateProduto(
                    produto.copyWith(
                      quantidadeEmEstoque: novaQuantidade,
                      updatedAt: DateTime.now(),
                    ),
                  );
                }

                if (mounted) {
                  Navigator.of(context).pop(); // Fecha o diálogo
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Estoque de ${produto.nome} atualizado!'),
                    ),
                  );
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  // Método para exibir o formulário de adicionar/editar produto (mantido igual)
  void _showProductForm({ProdutoModel? produto}) {
    // ... CÓDIGO DO _showProductForm AQUI (MANTENHA EXATAMENTE O MESMO QUE JÁ ESTÁ) ...
    // Certifique-se de que este método esteja completo no seu arquivo.
    final TextEditingController _nomeController = TextEditingController(
      text: produto?.nome ?? '',
    );
    double _quantidadeIdealMes = produto?.quantidadeIdealMes ?? 1.0;
    String? _selectedUnidadeId = produto?.unidadeMedidaId;
    String? _selectedCategoriaId = produto?.categoriaId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Importante para o teclado não cobrir campos
      builder: (context) {
        return StatefulBuilder(
          // Use StatefulBuilder para atualizar o estado do modal
          builder: (BuildContext context, StateSetter modalSetState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom:
                    MediaQuery.of(context).viewInsets.bottom +
                    20, // Ajusta para o teclado
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    produto == null
                        ? 'Adicionar Novo Produto'
                        : 'Editar Produto',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextField(
                    controller: _nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome do Produto',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Quantidade Ideal Mês: ${_quantidadeIdealMes.toStringAsFixed(1)}',
                  ),
                  Slider(
                    value: _quantidadeIdealMes,
                    min: 0.1, // Permite valores decimais pequenos
                    max: 100.0,
                    divisions: 999, // Para permitir muitos valores decimais
                    onChanged: (newValue) {
                      modalSetState(() {
                        _quantidadeIdealMes = newValue;
                      });
                    },
                  ),
                  StreamBuilder<List<UnidadeMedidaModel>>(
                    stream: _unidadeMedidaRepository.getUnidadesMedida(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }
                      final unidades = snapshot.data!;
                      return DropdownButtonFormField<String>(
                        value: _selectedUnidadeId,
                        hint: const Text('Selecione a Unidade de Medida'),
                        items: unidades.map((unidade) {
                          return DropdownMenuItem(
                            value: unidade.id,
                            child: Text(unidade.descricao),
                          );
                        }).toList(),
                        onChanged: (value) {
                          modalSetState(() {
                            _selectedUnidadeId = value;
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<List<CategoriaModel>>(
                    stream: _categoriaRepository.getCategorias(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }
                      final categorias = snapshot.data!;
                      return DropdownButtonFormField<String>(
                        value: _selectedCategoriaId,
                        hint: const Text('Selecione a Categoria'),
                        items: categorias.map((categoria) {
                          return DropdownMenuItem(
                            value: categoria.id,
                            child: Text(categoria.descricao),
                          );
                        }).toList(),
                        onChanged: (value) {
                          modalSetState(() {
                            _selectedCategoriaId = value;
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (_nomeController.text.isEmpty ||
                          _selectedUnidadeId == null ||
                          _selectedCategoriaId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Preencha todos os campos!'),
                          ),
                        );
                        return;
                      }

                      final newProduto = ProdutoModel(
                        id: produto?.id, // Se editando, mantém o ID
                        nome: _nomeController.text,
                        quantidadeIdealMes: _quantidadeIdealMes,
                        unidadeMedidaId: _selectedUnidadeId!,
                        categoriaId: _selectedCategoriaId!,
                        quantidadeEmEstoque:
                            produto?.quantidadeEmEstoque ?? 0.0,
                        isActive: produto?.isActive ?? true,
                        isRemoved: produto?.isRemoved ?? false,
                        createdAt: produto?.createdAt,
                        updatedAt: DateTime.now(), // Atualiza sempre ao salvar
                      );

                      if (produto == null) {
                        await _produtoRepository.addProduto(newProduto);
                      } else {
                        await _produtoRepository.updateProduto(newProduto);
                      }
                      if (mounted) {
                        Navigator.pop(context); // Fecha o modal
                      }
                    },
                    child: Text(
                      produto == null ? 'Salvar Produto' : 'Atualizar Produto',
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
    return Scaffold(
      appBar: AppBar(
        title: _selectedIndex == 0
            ? const Text('Minha Lista de Produtos')
            : _selectedIndex == 1
            ? const Text('Definir Orçamento Mensal')
            : const Text('Compra Ativa'), // Título dinâmico para a nova tela
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          // Conteúdo da Tela 1: Lista de Produtos
          StreamBuilder<List<ProdutoModel>>(
            stream: _produtoRepository.getActiveProdutos(),
            builder: (context, snapshot) {
              // ... (código existente para carregar produtos) ...
              final produtos = snapshot.data!;
              return ListView.builder(
                itemCount: produtos.length,
                itemBuilder: (context, index) {
                  final produto = produtos[index];
                  // ... (obtenção de descrições e cálculo de quantidadeParaComprar) ...
                  final unidadeDescricao =
                      _unidadesDescricao[produto.unidadeMedidaId] ?? 'N/A';
                  final categoriaDescricao =
                      _categoriasDescricao[produto.categoriaId] ?? 'N/A';
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
                    margin: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: ListTile(
                      title: Text(
                        produto.nome,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ideal p/ Mês: ${produto.quantidadeIdealMes.toStringAsFixed(1)} $unidadeDescricao',
                          ),
                          Text(
                            'Em Estoque: ${produto.quantidadeEmEstoque.toStringAsFixed(1)} $unidadeDescricao',
                          ),
                          Text(
                            'Precisa Comprar: ${quantidadeParaComprar.toStringAsFixed(1)} $unidadeDescricao',
                            style: TextStyle(
                              color: quantidadeParaComprar > 0
                                  ? Colors.red[700]
                                  : Colors.green[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text('Categoria: $categoriaDescricao'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // NOVO BOTÃO: Atualizar Estoque
                          IconButton(
                            icon: const Icon(
                              Icons.inventory,
                              color: Colors.blue,
                            ),
                            onPressed: () => _showUpdateStockDialog(produto),
                            tooltip: 'Atualizar Estoque',
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showProductForm(produto: produto),
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
                                builder: (context) => AlertDialog(
                                  title: const Text('Confirmar Exclusão'),
                                  content: Text(
                                    'Tem certeza que deseja remover ${produto.nome}?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text('Remover'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await _produtoRepository.removeProdutoLogically(
                                  produto.id,
                                );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${produto.nome} removido!',
                                      ),
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
              );
            },
          ),
          // ... (OrcamentoPage e ActiveShoppingPage como estão) ...
          const OrcamentoPage(),
          const ActiveShoppingPage(),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () => _showProductForm(),
              child: const Icon(Icons.add),
            )
          : null, // O FAB agora é apenas para a tela de produtos
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Produtos'),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Orçamento',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Comprar',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        onTap: _onItemTapped,
      ),
    );
  }
}
