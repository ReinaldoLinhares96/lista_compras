// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'data/repositories/unidade_medida_repository.dart';
import 'data/repositories/categoria_repository.dart';
import 'data/repositories/compra_status_repository.dart';
import 'data/repositories/orcamento_repository.dart';
import 'data/repositories/compra_repository.dart'; // Importe o novo repositório
import 'package:flutter_localizations/flutter_localizations.dart';
import 'presentation/pages/product_list_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inicializa todos os repositórios padrão
  await CompraStatusRepository().initializeDefaultCompraStatus();
  await OrcamentoRepository().initializeDefaultOrcamento();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        // Adicione
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        // Adicione
        Locale('pt', 'BR'),
        // ... (outras que precisar)
      ],
      title: 'Lista de Compras', // Nome do projeto atualizado
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ProductListPage(),
    );
  }
}
