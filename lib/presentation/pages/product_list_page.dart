// ... imports existentes

// ignore_for_file: unused_field, no_leading_underscores_for_local_identifiers, use_build_context_synchronously, unused_import, unused_element, duplicate_ignore

// Importe a página de orçamento
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/produto_model.dart';
import '../../data/repositories/produto_repository.dart';
import '../../data/models/unidade_medida_model.dart';
import '../../data/repositories/unidade_medida_repository.dart';
import '../../data/models/categoria_model.dart';
import '../../data/repositories/categoria_repository.dart';
import 'package:lista_compras/presentation/pages/orcamento_page.dart';
import 'package:lista_compras/presentation/pages/active_shopping_page.dart';

// ignore_for_file: unused_field, no_leading_underscores_for_local_identifiers, use_build_context_synchronously, unused_import, unused_element

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

  Map<String, String> _unidadesDescricao = {};
  Map<String, String> _categoriasDescricao = {};
  Map<String, CategoriaModel> _categoriasMap =
      {}; // Novo: Mapa para CategoriaModel completo

  int _selectedIndex = 0;
  late PageController _pageController;

  final TextEditingController _searchController =
      TextEditingController(); // Controlador para o campo de busca
  String _searchText = ''; // Texto de busca atual

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _loadAuxiliaryData();

    // Listener para o campo de busca
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose(); // Dispose do controlador de busca
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  Future<void> _loadAuxiliaryData() async {
    _unidadeMedidaRepository.getUnidadesMedida().listen((unidades) {
      setState(() {
        _unidadesDescricao = {for (var u in unidades) u.id: u.descricao};
      });
    });

    _categoriaRepository.getCategorias().listen((categorias) {
      setState(() {
        _categoriasDescricao = {for (var c in categorias) c.id: c.descricao};
        _categoriasMap = {
          for (var c in categorias) c.id: c,
        }; // Preenche o mapa de categorias
      });
    });
  }

  void _showProductForm({ProdutoModel? produto}) {
    final TextEditingController _nomeController = TextEditingController(
      text: produto?.nome ?? '',
    );
    double _quantidadeIdealMes = produto?.quantidadeIdealMes ?? 1.0;
    String? _selectedUnidadeId = produto?.unidadeMedidaId;
    String? _selectedCategoriaId = produto?.categoriaId;

    final TextEditingController _quantidadeIdealController =
        TextEditingController(
          text: _quantidadeIdealMes.toStringAsFixed(1).replaceAll('.', ','),
        );

    // Mova a adição do listener para DENTRO do StatefulBuilder
    // e o dispose para o .whenComplete() do showModalBottomSheet
    // para garantir que o listener tenha acesso ao modalSetState correto.

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            // Defina a função do listener AQUI DENTRO,
            // para que ela tenha acesso direto ao 'modalSetState'.
            void _updateSliderFromTextLocal() {
              final value = double.tryParse(
                _quantidadeIdealController.text.replaceAll(',', '.'),
              );
              if (value != null) {
                modalSetState(() {
                  _quantidadeIdealMes = value.clamp(
                    0.1,
                    100.0,
                  ); // Garante que o valor esteja dentro dos limites
                });
              }
            }

            // Adicione o listener AQUI DENTRO do StatefulBuilder
            _quantidadeIdealController.addListener(_updateSliderFromTextLocal);

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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Quantidade Ideal Mês:',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        SizedBox(
                          width: 80, // Largura fixa para o TextFormField
                          child: TextField(
                            controller: _quantidadeIdealController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              isDense: true, // Torna o campo mais compacto
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 8.0,
                                horizontal: 8.0,
                              ),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _quantidadeIdealMes,
                      min: 0.1,
                      max: 100.0,
                      divisions: 999,
                      onChanged: (newValue) {
                        modalSetState(() {
                          _quantidadeIdealMes = newValue;
                          _quantidadeIdealController.text = newValue
                              .toStringAsFixed(1)
                              .replaceAll('.', ',');
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
                          id: produto?.id,
                          nome: _nomeController.text,
                          quantidadeIdealMes: _quantidadeIdealMes,
                          unidadeMedidaId: _selectedUnidadeId!,
                          categoriaId: _selectedCategoriaId!,
                          quantidadeEmEstoque:
                              produto?.quantidadeEmEstoque ?? 0.0,
                          isActive: produto?.isActive ?? true,
                          isRemoved: produto?.isRemoved ?? false,
                          createdAt: produto?.createdAt,
                          updatedAt: DateTime.now(),
                        );

                        if (produto == null) {
                          await _produtoRepository.addProduto(newProduto);
                        } else {
                          await _produtoRepository.updateProduto(newProduto);
                        }
                        if (mounted) {
                          Navigator.pop(context);
                        }
                      },
                      child: Text(
                        produto == null
                            ? 'Salvar Produto'
                            : 'Atualizar Produto',
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      // O listener foi adicionado localmente dentro do builder,
      // então apenas o dispose do controlador é suficiente para limpá-lo.
      _quantidadeIdealController.dispose();
    });
  }

  // Método para exibir o diálogo de atualização de estoque (MANTIDO NO NÍVEL DA CLASSE)
  void _showUpdateStockDialog(ProdutoModel produto) {
    final TextEditingController _stockController = TextEditingController(
      text: produto.quantidadeEmEstoque.toStringAsFixed(1).replaceAll('.', ','),
    );

    // Definir a função do listener localmente dentro do showDialog
    // para ter acesso ao StateSetter do diálogo, se necessário.
    // Por enquanto, não há um StateSetter no showDialog, então setState() seria do _ProductListPageState
    // Se você precisar de setState dentro do AlertDialog (para atualizar algo visualmente no diálogo),
    // você precisaria de um StatefulBuilder aqui também.

    showDialog(
      context: context,
      builder: (context) {
        // Se precisar de setState dentro do AlertDialog, descomente o StatefulBuilder
        // return StatefulBuilder(
        //   builder: (BuildContext context, StateSetter dialogSetState) {
        //     // Agora você pode usar dialogSetState(() { ... }) aqui dentro
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
                        quantidadeIdealMes: novaQuantidade,
                        updatedAt: DateTime.now(),
                      ),
                    );
                  } else {
                    await _produtoRepository.updateProduto(
                      produto.copyWith(
                        quantidadeEmEstoque: novaQuantidade,
                        updatedAt: DateTime.now(),
                      ),
                    );
                  }
                } else {
                  await _produtoRepository.updateProduto(
                    produto.copyWith(
                      quantidadeEmEstoque: novaQuantidade,
                      updatedAt: DateTime.now(),
                    ),
                  );
                }

                if (mounted) {
                  Navigator.of(context).pop();
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
        // } // Fim do StatefulBuilder, se descomentado
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: _selectedIndex == 0
            ? const Text('Minha Lista de Produtos')
            : _selectedIndex == 1
            ? const Text('Definir Orçamento Mensal')
            : const Text('Compra Ativa'),
        bottom: _selectedIndex == 0
            ? PreferredSize(
                preferredSize: const Size.fromHeight(60.0),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar produto...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10.0,
                        horizontal: 10.0,
                      ),
                    ),
                  ),
                ),
              )
            : null,
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
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('Erro ao carregar produtos: ${snapshot.error}'),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text('Nenhum produto cadastrado. Adicione um agora!'),
                );
              }

              List<ProdutoModel> produtos = snapshot.data!;

              // Aplicar filtro de busca
              if (_searchText.isNotEmpty) {
                produtos = produtos
                    .where(
                      (produto) => produto.nome.toLowerCase().contains(
                        _searchText.toLowerCase(),
                      ),
                    )
                    .toList();
              }

              // Agrupar produtos por categoria
              Map<String, List<ProdutoModel>> produtosPorCategoria = {};
              for (var produto in produtos) {
                final categoriaDescricao =
                    _categoriasDescricao[produto.categoriaId] ?? 'Outros';
                produtosPorCategoria
                    .putIfAbsent(categoriaDescricao, () => [])
                    .add(produto);
              }

              // Ordenar as categorias pelo nome
              final sortedCategories = produtosPorCategoria.keys.toList()
                ..sort();

              if (produtos.isEmpty && _searchText.isNotEmpty) {
                return const Center(
                  child: Text('Nenhum produto encontrado para sua busca.'),
                );
              }
              if (produtos.isEmpty && _searchText.isEmpty) {
                return const Center(
                  child: Text('Nenhum produto cadastrado. Adicione um agora!'),
                );
              }

              return ListView.builder(
                itemCount: sortedCategories.length,
                itemBuilder: (context, categoryIndex) {
                  final categoria = sortedCategories[categoryIndex];
                  final produtosDaCategoria = produtosPorCategoria[categoria]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          categoria,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap:
                            true, // Para não dar erro de renderização dentro de outro ListView
                        physics:
                            const NeverScrollableScrollPhysics(), // Desabilita o scroll do ListView aninhado
                        itemCount: produtosDaCategoria.length,
                        itemBuilder: (context, productIndex) {
                          final produto = produtosDaCategoria[productIndex];
                          final unidadeDescricao =
                              _unidadesDescricao[produto.unidadeMedidaId] ??
                              'N/A';
                          final double quantidadeParaComprar =
                              produto.quantidadeIdealMes -
                              produto.quantidadeEmEstoque;

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
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
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
                                  quantidadeParaComprar > 0
                                      ? Text(
                                          'Precisa Comprar: ${quantidadeParaComprar.toStringAsFixed(1)} $unidadeDescricao',
                                          style: TextStyle(
                                            color: Colors.red[700],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : Text(
                                          'Estoque completo',
                                          style: TextStyle(
                                            color: Colors.green[700],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                  // Novo: Adicionando o ícone de necessidade
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
                                    icon: const Icon(
                                      Icons.inventory,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () =>
                                        _showUpdateStockDialog(produto),
                                    tooltip: 'Atualizar Estoque',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () =>
                                        _showProductForm(produto: produto),
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
                                          title: const Text(
                                            'Confirmar Exclusão',
                                          ),
                                          content: Text(
                                            'Tem certeza que deseja remover ${produto.nome}?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(
                                                context,
                                              ).pop(false),
                                              child: const Text('Cancelar'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.of(
                                                context,
                                              ).pop(true),
                                              child: const Text('Remover'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await _produtoRepository
                                            .removeProdutoLogically(produto.id);
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
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
                      ),
                    ],
                  );
                },
              );
            },
          ),
          // Conteúdo da Tela 2: Orçamento (Próximo Refinamento)
          const OrcamentoPage(),
          // Conteúdo da Tela 3: Compra Ativa
          const ActiveShoppingPage(),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () => _showProductForm(),
              child: const Icon(Icons.add),
            )
          : null,
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
