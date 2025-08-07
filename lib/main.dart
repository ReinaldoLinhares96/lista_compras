import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lista_compras/utils/firebase_options.dart';
import 'package:provider/provider.dart';

// Importe todos os seus modelos para registrar seus adaptadores
import 'package:lista_compras/data/models/produto_model.dart';
import 'package:lista_compras/data/models/categoria_model.dart';
import 'package:lista_compras/data/models/compra_model.dart';
import 'package:lista_compras/data/models/item_compra_model.dart';
import 'package:lista_compras/data/models/compra_status_model.dart';
import 'package:lista_compras/data/models/orcamento_model.dart';
import 'package:lista_compras/data/models/user_profile_model.dart';

// Importe o enum CompraStatusType (ainda é necessário, mas não para registro do Hive)
// ignore: unused_import
import 'package:lista_compras/core/enums/compra_status_type.dart'; // Re-adicionado, se foi removido

// Importe TODOS os repositórios que serão fornecidos
import 'package:lista_compras/data/repositories/compra_status_repository.dart';
import 'package:lista_compras/data/repositories/orcamento_repository.dart';
import 'package:lista_compras/data/repositories/user_repository.dart';
import 'package:lista_compras/data/repositories/produto_repository.dart';
import 'package:lista_compras/data/repositories/categoria_repository.dart';
import 'package:lista_compras/data/repositories/compra_repository.dart';
import 'package:lista_compras/data/repositories/item_compra_repository.dart';

import 'package:lista_compras/presentation/pages/welcome_screen.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialização do Hive e registro de adaptadores
  await Hive.initFlutter();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Se já foi inicializado, ignora o erro
    if (kDebugMode) {
      print("Firebase já inicializado: $e");
    }
  }

  // Inicializa o Google Mobile Ads SDK (pode ser inicializado mais de uma vez)
  await MobileAds.instance.initialize();

  // Registre todos os adaptadores gerados (verifique se os typeIds são únicos e sequenciais)
  Hive.registerAdapter(ProdutoModelAdapter()); // typeId: 0
  Hive.registerAdapter(CategoriaModelAdapter()); // typeId: 2
  Hive.registerAdapter(CompraModelAdapter()); // typeId: 3
  Hive.registerAdapter(ItemCompraModelAdapter()); // typeId: 4
  Hive.registerAdapter(CompraStatusModelAdapter()); // typeId: 5
  Hive.registerAdapter(OrcamentoModelAdapter()); // typeId: 6
  Hive.registerAdapter(UserProfileModelAdapter()); // typeId: 7

  // ABRA AS CAIXAS (BOXES) QUE VOCÊ VAI USAR NO SEU APLICATIVO
  await Hive.openBox<ProdutoModel>('produtosBox');
  await Hive.openBox<CategoriaModel>('categoriasBox');
  await Hive.openBox<CompraModel>('comprasBox');
  await Hive.openBox<ItemCompraModel>('itensCompraBox');
  await Hive.openBox<CompraStatusModel>('compraStatusBox');
  await Hive.openBox<double>('orcamentoBox');
  await Hive.openBox<bool>('premiumStatusBox'); // Para cache do status premium

  // Instancie o UserRepository primeiro
  final UserRepository userRepository = UserRepository();

  // Instancie os repositórios que dependem de outros repositórios, PASSANDO userRepository
  final CompraStatusRepository compraStatusRepository = CompraStatusRepository(
    userRepository: userRepository,
  ); // CORREÇÃO AQUI
  await compraStatusRepository.initializeDefaultCompraStatus();

  final OrcamentoRepository orcamentoRepository = OrcamentoRepository(
    userRepository: userRepository,
  ); // CORREÇÃO AQUI
  await orcamentoRepository.initializeDefaultOrcamento();

  final ProdutoRepository produtoRepository = ProdutoRepository(
    userRepository: userRepository,
  );
  final CategoriaRepository categoriaRepository = CategoriaRepository(
    userRepository: userRepository,
  );
  final CompraRepository compraRepository = CompraRepository(
    userRepository: userRepository,
  );
  final ItemCompraRepository itemCompraRepository = ItemCompraRepository(
    userRepository: userRepository,
  );
  runApp(
    MultiProvider(
      providers: [
        // Fornecer a instância única de cada repositório
        Provider<UserRepository>(create: (_) => userRepository),
        Provider<ProdutoRepository>(create: (_) => produtoRepository),
        Provider<CategoriaRepository>(create: (_) => categoriaRepository),
        Provider<CompraRepository>(create: (_) => compraRepository),
        Provider<ItemCompraRepository>(create: (_) => itemCompraRepository),
        Provider<CompraStatusRepository>(create: (_) => compraStatusRepository),
        Provider<OrcamentoRepository>(create: (_) => orcamentoRepository),
      ],
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
      home: const WelcomeScreen(),
    );
  }
}
