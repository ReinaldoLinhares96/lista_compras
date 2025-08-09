// ignore_for_file: prefer_final_fields, avoid_print

import 'package:flutter/material.dart';
import 'package:lista_compras/data/repositories/premium_status_repository.dart';
import 'package:lista_compras/presentation/pages/premium_purchase_page.dart';
import 'package:provider/provider.dart';
import '../../data/models/produto_model.dart';
import '../../data/repositories/produto_repository.dart';
import '../../data/models/categoria_model.dart';
import '../../data/repositories/categoria_repository.dart';
import 'package:lista_compras/presentation/pages/orcamento_page.dart';
import 'package:lista_compras/presentation/pages/active_shopping_page.dart';

// Importe os novos widgets e os existentes
import 'package:lista_compras/presentation/widgets/add_edit_product_modal.dart';
import 'package:lista_compras/presentation/widgets/update_stock_dialog.dart';
import 'package:lista_compras/presentation/widgets/product_search_bar.dart';
import 'package:lista_compras/presentation/widgets/product_category_panel.dart';
import 'package:lista_compras/presentation/widgets/add_categoria_modal.dart';

// NOVOS IMPORTS PARA AS PÁGINAS DE GERENCIAMENTO
import 'package:lista_compras/presentation/pages/categoria_management_page.dart';
import 'package:lista_compras/presentation/pages/purchase_history_page.dart';

import 'package:lista_compras/services/ad_manager.dart';

// ignore_for_file: unused_field, no_leading_underscores_for_local_identifiers, use_build_context_synchronously, unused_import, unused_element, duplicate_ignore

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final ProdutoRepository _produtoRepository = ProdutoRepository();
  final CategoriaRepository _categoriaRepository = CategoriaRepository();
  late final PremiumStatusRepository _premiumStatusRepository;

  Map<String, String> _categoriasDescricao = {};
  Map<String, CategoriaModel> _categoriasMap = {};

  int _selectedIndex = 0;
  late PageController _pageController;

  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  bool _isPremium = false;
  Map<String, bool> _categoryExpansionState = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _premiumStatusRepository = Provider.of<PremiumStatusRepository>(
      context,
      listen: false,
    );

    _loadAuxiliaryData();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text;
      });
    });

    AdManager.loadInterstitialAd();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    AdManager.disposeAd();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
    AdManager.maybeShowInterstitialAd(_isPremium);
  }

  Future<void> _loadAuxiliaryData() async {
    _categoriaRepository.getCategorias().listen((categorias) {
      setState(() {
        _categoriasDescricao = {for (var c in categorias) c.id: c.descricao};
        _categoriasMap = {for (var c in categorias) c.id: c};
        for (var c in categorias) {
          _categoryExpansionState.putIfAbsent(c.descricao, () => true);
        }
      });
    });
  }

  void _handleEditProduct(ProdutoModel product) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return AddEditProductModal(product: product);
      },
    );
  }

  Future<void> _handleDeleteProduct(ProdutoModel product) async {
    await _produtoRepository.deleteProduto(product.id);
  }

  void _handleUpdateStock(ProdutoModel product) async {
    await showDialog(
      context: context,
      builder: (context) {
        return UpdateStockDialog(
          product: product,
          productRepository: _produtoRepository,
        );
      },
    );
  }

  void _showAddOptionsModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StreamBuilder<bool>(
          stream: _premiumStatusRepository.isPremiumStream,
          initialData: _premiumStatusRepository.isPremium,
          builder: (context, snapshot) {
            _isPremium = snapshot.data ?? false;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 60,
                top: 20,
                left: 10,
                right: 10,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.shopping_basket),
                    title: const Text('Criar Novo Produto'),
                    onTap: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) {
                          return const AddEditProductModal();
                        },
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.category),
                    title: const Text('Criar Nova Categoria'),
                    onTap: () {
                      Navigator.pop(context);
                      AdManager.maybeShowInterstitialAd(_isPremium);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) {
                          return const AddCategoriaModal();
                        },
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('Histórico de Compras'),
                    // Habilitar a opção somente para usuários premium
                    onTap: _isPremium
                        ? () {
                            Navigator.pop(context);
                            AdManager.maybeShowInterstitialAd(_isPremium);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const PurchaseHistoryPage(),
                              ),
                            );
                          }
                        : null, // Desabilitar o botão se não for premium
                    trailing: !_isPremium
                        ? const Icon(Icons.lock, color: Colors.grey)
                        : null,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.category_outlined),
                    title: const Text('Categorias'),
                    onTap: () {
                      Navigator.pop(context);
                      AdManager.maybeShowInterstitialAd(_isPremium);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CategoriaManagementPage(),
                        ),
                      );
                    },
                  ),
                  // OPÇÃO DE PREMIUM (Botão dinâmico)
                  if (!_isPremium)
                    ListTile(
                      leading: const Icon(Icons.star),
                      title: const Text('Ser Premium Agora!'),
                      onTap: () {
                        Navigator.pop(context);
                        AdManager.maybeShowInterstitialAd(_isPremium);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PremiumPurchasePage(),
                          ),
                        );
                      },
                    )
                  else
                    ListTile(
                      leading: const Icon(Icons.star),
                      title: const Text(
                        'Você já é Premium!',
                        style: TextStyle(color: Colors.green),
                      ),
                      onTap: null, // Desabilitar se já for premium
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
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: _selectedIndex == 0
            ? const Text(
                'Produtos',
                style: TextStyle(fontWeight: FontWeight.bold),
              )
            : _selectedIndex == 1
            ? const Text(
                'Orçamento',
                style: TextStyle(fontWeight: FontWeight.bold),
              )
            : const Text(
                'Comprar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade100,
        bottom: _selectedIndex == 0
            ? PreferredSize(
                preferredSize: const Size.fromHeight(60.0),
                child: ProductSearchBar(
                  controller: _searchController,
                  onChanged: (text) {},
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

              if (_searchText.isNotEmpty) {
                produtos = produtos
                    .where(
                      (produto) => produto.nome.toLowerCase().contains(
                        _searchText.toLowerCase(),
                      ),
                    )
                    .toList();
              }

              Map<String, List<ProdutoModel>> produtosPorCategoria = {};
              for (var produto in produtos) {
                final categoriaDescricao =
                    _categoriasDescricao[produto.categoriaId] ?? 'Outros';
                produtosPorCategoria
                    .putIfAbsent(categoriaDescricao, () => [])
                    .add(produto);
              }

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

                  return ProductCategoryPanel(
                    key: ValueKey(categoria),
                    categoryName: categoria,
                    productsInCategory: produtosDaCategoria,
                    onEditProduct: _handleEditProduct,
                    onDeleteProduct: _handleDeleteProduct,
                    onUpdateStock: _handleUpdateStock,
                    isExpanded: _categoryExpansionState[categoria] ?? true,
                    onExpansionChanged: (isExpanded) {
                      setState(() {
                        _categoryExpansionState[categoria] = isExpanded;
                      });
                    },
                  );
                },
              );
            },
          ),
          const OrcamentoPage(),
          const ActiveShoppingPage(),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: _showAddOptionsModal,
              child: const Icon(Icons.list_rounded),
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
        backgroundColor: Colors.blue.shade100,
        onTap: _onItemTapped,
      ),
    );
  }
}
