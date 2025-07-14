// lib/main.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// Firebase Imports
import 'package:firebase_core/firebase_core.dart';
import 'package:lista_compras/utils/firebase_options.dart';
//import 'firebase_options.dart';

// Importe todos os seus modelos para registrar seus adaptadores
import 'package:lista_compras/data/models/produto_model.dart';
import 'package:lista_compras/data/models/categoria_model.dart';
import 'package:lista_compras/data/models/compra_model.dart';
import 'package:lista_compras/data/models/item_compra_model.dart';
import 'package:lista_compras/data/models/compra_status_model.dart';
import 'package:lista_compras/data/models/orcamento_model.dart';

// Importe o enum CompraStatusType (ainda é necessário, mas não para registro do Hive)

// Repositórios necessários para inicialização de dados padrão (se aplicável no Hive)
import 'package:lista_compras/data/repositories/compra_status_repository.dart';
import 'package:lista_compras/data/repositories/orcamento_repository.dart';

// Importe a WelcomeScreen como a nova página inicial
import 'package:lista_compras/presentation/pages/welcome_screen.dart'; // Mantém WelcomeScreen como home

import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Google Mobile Ads SDK
  await MobileAds.instance.initialize();

  // Inicializa o Firebase Core
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inicialização do Hive e registro de adaptadores
  await Hive.initFlutter();

  // Registre todos os adaptadores gerados
  Hive.registerAdapter(ProdutoModelAdapter());
  Hive.registerAdapter(CategoriaModelAdapter());
  Hive.registerAdapter(CompraModelAdapter());
  Hive.registerAdapter(ItemCompraModelAdapter());
  Hive.registerAdapter(CompraStatusModelAdapter());
  Hive.registerAdapter(OrcamentoModelAdapter());

  // ABRA AS CAIXAS (BOXES) QUE VOCÊ VAI USAR NO SEU APLICATIVO
  await Hive.openBox<ProdutoModel>('produtosBox');
  await Hive.openBox<CategoriaModel>('categoriasBox');
  await Hive.openBox<CompraModel>('comprasBox');
  await Hive.openBox<ItemCompraModel>('itensCompraBox');
  await Hive.openBox<CompraStatusModel>('compraStatusBox');
  await Hive.openBox<double>('orcamentoBox');
  await Hive.openBox<bool>(
    'premiumStatusBox',
  ); // Abrir a caixa do contador de anúncios

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
      home: const WelcomeScreen(), // Continua sendo WelcomeScreen
    );
  }
}
