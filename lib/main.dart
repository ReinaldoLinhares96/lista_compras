// ignore_for_file: await_only_futures

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lista_compras/data/models/log_model.dart';
import 'package:lista_compras/data/models/orcamento_model.dart';
import 'package:lista_compras/data/models/premium_status_model.dart';

// Importe todos os seus modelos para registrar seus adaptadores
import 'package:lista_compras/data/models/produto_model.dart';
import 'package:lista_compras/data/models/categoria_model.dart';
import 'package:lista_compras/data/models/compra_model.dart';
import 'package:lista_compras/data/models/item_compra_model.dart';
import 'package:lista_compras/data/models/compra_status_model.dart';
import 'package:lista_compras/data/repositories/categoria_repository.dart';

// Repositórios necessários para inicialização de dados padrão (se aplicável no Hive)
import 'package:lista_compras/data/repositories/compra_status_repository.dart';
import 'package:lista_compras/data/repositories/log_repository.dart';
import 'package:lista_compras/data/repositories/orcamento_repository.dart';
import 'package:lista_compras/data/repositories/premium_status_repository.dart';

// Importe a ProductListPage como a página inicial
import 'package:lista_compras/presentation/pages/product_list_page.dart'; // CORREÇÃO AQUI

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //await Hive.deleteFromDisk(); // Comente ou remova após a depuração inicial
  await Hive.initFlutter();

  // Registre todos os adaptadores gerados
  Hive.registerAdapter(ProdutoModelAdapter());
  Hive.registerAdapter(CategoriaModelAdapter());
  Hive.registerAdapter(CompraModelAdapter());
  Hive.registerAdapter(ItemCompraModelAdapter());
  Hive.registerAdapter(CompraStatusModelAdapter());
  Hive.registerAdapter(OrcamentoModelAdapter());
  Hive.registerAdapter(PremiumStatusModelAdapter());
  Hive.registerAdapter(LogModelAdapter());

  // ABRA AS CAIXAS (BOXES) QUE VOCÊ VAI USAR NO SEU APLICATIVO
  await Hive.openBox<ProdutoModel>('produtosBox');
  await Hive.openBox<CategoriaModel>('categoriasBox');
  await Hive.openBox<CompraModel>('comprasBox');
  await Hive.openBox<ItemCompraModel>('itensCompraBox');
  await Hive.openBox<CompraStatusModel>('compraStatusBox');
  await Hive.openBox<double>('orcamentoBox');
  await Hive.openBox<bool>('premiumStatusBox');
  await Hive.openBox<LogModel>('logBox');

  // Inicialização de repositórios que ainda gerenciam dados padrão.
  await CompraStatusRepository().initializeDefaultCompraStatus();
  await OrcamentoRepository().initializeDefaultOrcamento();
  await CategoriaRepository().initializeDefaultCategoria();
  await PremiumStatusRepository().initializeDefaultPremiumStatus();
  final logRepository = LogRepository();
  await logRepository.initializeDefaultLog();

  runApp(
    MultiProvider(
      providers: [Provider<LogRepository>.value(value: logRepository)],
      child: const MyApp(),
    ),
  );
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
      home: const ProductListPage(),
    );
  }
}
