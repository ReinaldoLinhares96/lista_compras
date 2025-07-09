import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lista_compras/data/models/orcamento_model.dart';

// Importe todos os seus modelos para registrar seus adaptadores
import 'package:lista_compras/data/models/produto_model.dart';
import 'package:lista_compras/data/models/unidade_medida_model.dart';
import 'package:lista_compras/data/models/categoria_model.dart';
import 'package:lista_compras/data/models/compra_model.dart';
import 'package:lista_compras/data/models/item_compra_model.dart';
import 'package:lista_compras/data/models/compra_status_model.dart';

// Repositórios necessários para inicialização de dados padrão (se aplicável no Hive)
import 'package:lista_compras/data/repositories/compra_status_repository.dart';
import 'package:lista_compras/data/repositories/orcamento_repository.dart';

// Importe a ProductListPage como a página inicial
import 'package:lista_compras/presentation/pages/product_list_page.dart'; // CORREÇÃO AQUI

import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // CUIDADO: ESTA LINHA APAGARÁ TODOS OS DADOS DO HIVE NO SEU DISPOSITIVO/EMULADOR!
  // USE APENAS PARA DEPURAÇÃO OU QUANDO PRECISA DE UM BANCO DE DADOS LIMPO.
  // await Hive.deleteFromDisk(); // Comente ou remova após a depuração inicial
  await Hive.deleteFromDisk();
  await Hive.initFlutter();

  // Registre todos os adaptadores gerados
  Hive.registerAdapter(ProdutoModelAdapter());
  Hive.registerAdapter(UnidadeMedidaModelAdapter());
  Hive.registerAdapter(CategoriaModelAdapter());
  Hive.registerAdapter(CompraModelAdapter());
  Hive.registerAdapter(ItemCompraModelAdapter());
  Hive.registerAdapter(CompraStatusModelAdapter());
  Hive.registerAdapter(
    OrcamentoModelAdapter(),
  ); // Não esquecer do OrcamentoModel

  // ABRA AS CAIXAS (BOXES) QUE VOCÊ VAI USAR NO SEU APLICATIVO
  await Hive.openBox<ProdutoModel>('produtosBox');
  await Hive.openBox<UnidadeMedidaModel>('unidadesMedidaBox');
  await Hive.openBox<CategoriaModel>('categoriasBox');
  await Hive.openBox<CompraModel>('comprasBox');
  await Hive.openBox<ItemCompraModel>('itensCompraBox');
  await Hive.openBox<CompraStatusModel>('compraStatusBox');
  await Hive.openBox<double>('orcamentoBox'); // Caixa para o valor do orçamento

  // Inicialização de repositórios que ainda gerenciam dados padrão.
  await CompraStatusRepository().initializeDefaultCompraStatus();
  await OrcamentoRepository().initializeDefaultOrcamento();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lista de Compras',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
      home:
          const ProductListPage(), // CORREÇÃO AQUI: Define ProductListPage como home
    );
  }
}
