import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'data/repositories/unidade_medida_repository.dart';
import 'data/repositories/categoria_repository.dart';
import 'data/repositories/compra_status_repository.dart';
import 'presentation/pages/product_list_page.dart'; // Importe sua nova página

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inicializa os repositórios para garantir que os dados padrão existam
  await UnidadeMedidaRepository().initializeDefaultUnidadesMedida();
  await CategoriaRepository().initializeDefaultCategorias();
  await CompraStatusRepository().initializeDefaultCompraStatus();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minhas Compras de Supermercado',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home:
          const ProductListPage(), // Define ProductListPage como a tela inicial
    );
  }
}
