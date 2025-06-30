// ignore_for_file: use_build_context_synchronously, unused_import, no_leading_underscores_for_local_identifiers

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/produto_model.dart';
import '../../data/repositories/produto_repository.dart';
import '../../data/models/unidade_medida_model.dart'; // Para exibir a descrição da unidade
import '../../data/repositories/unidade_medida_repository.dart'; // Para carregar unidades
import '../../data/models/categoria_model.dart'; // Para exibir a descrição da categoria
import '../../data/repositories/categoria_repository.dart'; // Para carregar categorias

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

  // Mapas para armazenar as descrições das unidades e categorias por ID para fácil acesso
  Map<String, String> _unidadesDescricao = {};
  Map<String, String> _categoriasDescricao = {};

  @override
  void initState() {
    super.initState();
    _loadAuxiliaryData();
  }

  // Carrega as descrições das unidades de medida e categorias
  Future<void> _loadAuxiliaryData() async {
    // Carrega Unidades de Medida
    _unidadeMedidaRepository.getUnidadesMedida().listen((unidades) {
      setState(() {
        _unidadesDescricao = {for (var u in unidades) u.id: u.descricao};
      });
    });

    // Carrega Categorias
    _categoriaRepository.getCategorias().listen((categorias) {
      setState(() {
        _categoriasDescricao = {for (var c in categorias) c.id: c.descricao};
      });
    });
  }

  // Método para exibir o formulário de adicionar/editar produto
  void _showProductForm({ProdutoModel? produto}) {
    // Controladores para os campos do formulário
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
      appBar: AppBar(title: const Text('Minha Lista de Produtos')),
      body: StreamBuilder<List<ProdutoModel>>(
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

          final produtos = snapshot.data!;
          return ListView.builder(
            itemCount: produtos.length,
            itemBuilder: (context, index) {
              final produto = produtos[index];
              final unidadeDescricao =
                  _unidadesDescricao[produto.unidadeMedidaId] ?? 'N/A';
              final categoriaDescricao =
                  _categoriasDescricao[produto.categoriaId] ?? 'N/A';
              final quantidadeParaComprar =
                  (produto.quantidadeIdealMes - produto.quantidadeEmEstoque)
                      .toStringAsFixed(1);

              // Define a cor de fundo com base na quantidade a comprar
              Color? itemBackgroundColor;
              if (double.parse(quantidadeParaComprar) > 0) {
                itemBackgroundColor =
                    Colors.red[50]; // Laranja claro para itens a comprar
              } else {
                itemBackgroundColor = Colors
                    .green[50]; // Verde claro para itens sem necessidade de compra
              }

              return Card(
                color: itemBackgroundColor,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                        'Precisa Comprar: $quantidadeParaComprar $unidadeDescricao',
                        style: TextStyle(
                          color: double.parse(quantidadeParaComprar) > 0
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
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showProductForm(produto: produto),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_forever,
                          color: Colors.red,
                        ),
                        onPressed: () async {
                          // Confirmação de exclusão
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            _showProductForm(), // Abre o formulário para adicionar novo
        child: const Icon(Icons.add),
      ),
    );
  }
}
