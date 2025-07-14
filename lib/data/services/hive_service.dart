// import 'package:flutter/foundation.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart'; // Para obter o UID atual

// // Importe todos os seus modelos de dados, eles precisarão de TypeAdapters
// import '../models/produto_model.dart';
// import '../models/orcamento_model.dart';
// import '../models/categoria_model.dart';
// import '../models/compra_model.dart';
// import '../models/item_compra_model.dart';
// import '../models/compra_status_model.dart'; // Se você armazena no Hive

// import '../../core/constants/firestore_collections.dart'; // Suas constantes de coleções

// class HiveService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   // Construtor privado para Singleton
//   HiveService._privateConstructor();

//   // Instância Singleton
//   static final HiveService _instance = HiveService._privateConstructor();

//   factory HiveService() {
//     return _instance;
//   }

//   // Método para inicializar o Hive (registrar adaptadores e abrir caixas)
//   Future<void> initHive() async {
//     await Hive.initFlutter();

//     // Registre todos os seus TypeAdapters aqui
//     Hive.registerAdapter(ProdutoModelAdapter());
//     Hive.registerAdapter(
//       OrcamentoModelAdapter(),
//     ); // Se Orcamento for um objeto complexo
//     Hive.registerAdapter(CategoriaModelAdapter());
//     Hive.registerAdapter(CompraModelAdapter());
//     Hive.registerAdapter(ItemCompraModelAdapter());
//     Hive.registerAdapter(CompraStatusModelAdapter());
//     // Adicione o registro de outros adaptadores conforme necessário
//   }

//   /// Migra todos os dados de um usuário anônimo do Hive para o Firestore.
//   ///
//   /// O `userId` é o UID do usuário que se tornou premium (ou fez login).
//   Future<void> migrateAnonymousDataToFirestore(String userId) async {
//     print(
//       'Iniciando migração de dados do Hive para o Firestore para o usuário: $userId',
//     );

//     if (userId.isEmpty) {
//       print('Erro: userId para migração está vazio.');
//       return;
//     }

//     // Coleções de usuário no Firestore (aninhadas sob o UID)
//     final CollectionReference userProductsCollection = _firestore
//         .collection(FirestoreCollections.users)
//         .doc(userId)
//         .collection(FirestoreCollections.produtos);
//     final CollectionReference userOrcamentoCollection = _firestore
//         .collection(FirestoreCollections.users)
//         .doc(userId)
//         .collection(FirestoreCollections.orcamento);
//     final CollectionReference userUnidadesMedidaCollection = _firestore
//         .collection(FirestoreCollections.users)
//         .doc(userId)
//         .collection(FirestoreCollections.unidadesMedida);
//     final CollectionReference userCategoriasCollection = _firestore
//         .collection(FirestoreCollections.users)
//         .doc(userId)
//         .collection(FirestoreCollections.categorias);
//     final CollectionReference userComprasCollection = _firestore
//         .collection(FirestoreCollections.users)
//         .doc(userId)
//         .collection(FirestoreCollections.compras);
//     final CollectionReference userItensCompraCollection = _firestore
//         .collection(FirestoreCollections.users)
//         .doc(userId)
//         .collection(FirestoreCollections.itensCompra);
//     final CollectionReference userCompraStatusCollection = _firestore
//         .collection(FirestoreCollections.users)
//         .doc(userId)
//         .collection(FirestoreCollections.comprasStatus);

//   //   // --- 1. Migrar Produtos ---
//   //   try {
//   //     final Box<ProdutoModel> produtosBox = await Hive.openBox<ProdutoModel>(
//   //       'produtos',
//   //     );
//   //     if (produtosBox.isNotEmpty) {
//   //       print('Migrando ${produtosBox.length} produtos...');
//   //       for (var produto in produtosBox.values) {
//   //         await userProductsCollection
//   //             .doc(produto.id)
//   //             .set(produto.toFirestore());
//   //       }
//   //       await produtosBox.clear(); // Limpa dados após migração
//   //       print('Produtos migrados e caixa Hive limpa.');
//   //     } else {
//   //       print('Nenhum produto para migrar no Hive.');
//   //     }
//   //     await produtosBox.close();
//   //   } catch (e) {
//   //     print('Erro ao migrar produtos: $e');
//   //   }

//   //   // --- 2. Migrar Orçamento ---
//   //   // Assumindo que orçamento é um único objeto/valor no Hive
//   //   try {
//   //     final Box<OrcamentoModel> orcamentoBox =
//   //         await Hive.openBox<OrcamentoModel>('orcamento');
//   //     if (orcamentoBox.isNotEmpty) {
//   //       print('Migrando orçamento...');
//   //       final orcamento = orcamentoBox.get(
//   //         'orcamento_unico',
//   //       ); // Ou a chave que você usa
//   //       if (orcamento != null) {
//   //         await userOrcamentoCollection
//   //             .doc('mensal')
//   //             .set(orcamento.toFirestore(), SetOptions(merge: true));
//   //       }
//   //       await orcamentoBox.clear();
//   //       print('Orçamento migrado e caixa Hive limpa.');
//   //     } else {
//   //       print('Nenhum orçamento para migrar no Hive.');
//   //     }
//   //     await orcamentoBox.close();
//   //   } catch (e) {
//   //     print('Erro ao migrar orçamento: $e');
//   //   }

//   //   // --- 4. Migrar Categorias ---
//   //   try {
//   //     final Box<CategoriaModel> categoriasBox =
//   //         await Hive.openBox<CategoriaModel>('categorias');
//   //     if (categoriasBox.isNotEmpty) {
//   //       print('Migrando ${categoriasBox.length} categorias...');
//   //       for (var categoria in categoriasBox.values) {
//   //         await userCategoriasCollection
//   //             .doc(categoria.id)
//   //             .set(categoria.toFirestore());
//   //       }
//   //       await categoriasBox.clear();
//   //       print('Categorias migradas e caixa Hive limpa.');
//   //     } else {
//   //       print('Nenhuma categoria para migrar no Hive.');
//   //     }
//   //     await categoriasBox.close();
//   //   } catch (e) {
//   //     print('Erro ao migrar categorias: $e');
//   //   }

//   //   // --- 5. Migrar Compras (Histórico) ---
//   //   try {
//   //     final Box<CompraModel> comprasBox = await Hive.openBox<CompraModel>(
//   //       'compras',
//   //     );
//   //     if (comprasBox.isNotEmpty) {
//   //       print('Migrando ${comprasBox.length} compras...');
//   //       for (var compra in comprasBox.values) {
//   //         await userComprasCollection.doc(compra.id).set(compra.toFirestore());

//   //         // Migrar Itens de Compra relacionados a esta compra
//   //         final Box<ItemCompraModel> itensCompraBox =
//   //             await Hive.openBox<ItemCompraModel>('itensCompra_${compra.id}');
//   //         if (itensCompraBox.isNotEmpty) {
//   //           print(
//   //             'Migrando ${itensCompraBox.length} itens para a compra ${compra.id}...',
//   //           );
//   //           for (var item in itensCompraBox.values) {
//   //             await userItensCompraCollection
//   //                 .doc(item.id)
//   //                 .set(item.toFirestore());
//   //           }
//   //           await itensCompraBox
//   //               .clear(); // Limpa caixa de itens da compra específica
//   //           print('Itens da compra ${compra.id} migrados e caixa Hive limpa.');
//   //         }
//   //         await itensCompraBox.close();
//   //       }
//   //       await comprasBox.clear(); // Limpa caixa de compras principal
//   //       print('Compras (histórico) migradas e caixa Hive limpa.');
//   //     } else {
//   //       print('Nenhuma compra para migrar no Hive.');
//   //     }
//   //     await comprasBox.close();
//   //   } catch (e) {
//   //     print('Erro ao migrar compras: $e');
//   //   }

//   //   // --- 6. Migrar CompraStatus (se armazenados no Hive, geralmente são globais) ---
//   //   // Se seus status de compra (Ativa, Finalizada, Cancelada) são fixos e não dependem do usuário,
//   //   // eles não precisam ser migrados por usuário. Se cada usuário puder criar seus próprios status,
//   //   // então a lógica abaixo seria aplicável. Para a maioria dos casos, são globais.
//   //   try {
//   //     final Box<CompraStatusModel> compraStatusBox =
//   //         await Hive.openBox<CompraStatusModel>('compraStatus');
//   //     if (compraStatusBox.isNotEmpty) {
//   //       print('Migrando ${compraStatusBox.length} status de compra...');
//   //       for (var status in compraStatusBox.values) {
//   //         await userCompraStatusCollection
//   //             .doc(status.id)
//   //             .set(status.toFirestore());
//   //       }
//   //       await compraStatusBox.clear();
//   //       print('Status de compra migrados e caixa Hive limpa.');
//   //     } else {
//   //       print('Nenhum status de compra para migrar no Hive.');
//   //     }
//   //     await compraStatusBox.close();
//   //   } catch (e) {
//   //     print('Erro ao migrar status de compra: $e');
//   //   }

//   //   print(
//   //     'Migração de dados do Hive para o Firestore concluída para o usuário: $userId',
//   //   );
//   // }

//   /// Limpa todos os dados armazenados no Hive.
//   /// Útil após a migração ou logout.
//   Future<void> clearAllHiveData() async {
//     if (kDebugMode) {
//       print('Limpando todos os dados do Hive...');
//     }
//     try {
//       // Lista de todas as caixas que seu app usa
//       final List<String> boxNames = [
//         'produtos',
//         'orcamento',
//         'categorias',
//         'compras',
//         'compraStatus',
//         // Adicione aqui os nomes das caixas de 'itensCompra_{compra.id}' se quiser limpar todas
//         // (Isso exigiria uma lógica para listar todas as chaves de compras anteriores para obter seus nomes de caixa)
//       ];

//       for (String boxName in boxNames) {
//         if (Hive.isBoxOpen(boxName)) {
//           await Hive.box(boxName).clear();
//           await Hive.box(boxName).close();

//         } else {
//           await Hive.openBox(boxName);
//           await Hive.box(boxName).clear();
//           await Hive.box(boxName).close();

//         }
//       }

//     } catch (e) {
//       if (kDebugMode) {
//         print('Erro ao limpar dados do Hive: $e');
//       }
//     }
//   }

//   // Métodos para persistir e buscar dados específicos no Hive (para uso antes da migração ou se não for premium)
//   // ... (Seus métodos ProdutoRepository, OrcamentoRepository, etc. com lógica Hive)
//   // Exemplo:
//   // Future<void> saveProdutoHive(ProdutoModel produto) async {
//   //   final box = await Hive.openBox<ProdutoModel>('produtos');
//   //   await box.put(produto.id, produto);
//   // }
// }
