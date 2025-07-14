// ignore_for_file: depend_on_referenced_packages, unnecessary_brace_in_string_interps, unused_import

import 'package:flutter/foundation.dart'; // Para kDebugMode
import 'package:hive_flutter/hive_flutter.dart';
import '../models/orcamento_model.dart';
import 'package:rxdart/rxdart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_repository.dart'; // NOVO IMPORT: UserRepository

class OrcamentoRepository {
  late Box<double> _orcamentoBox;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final UserRepository _userRepository; // NOVO: Instância de UserRepository

  static const String _orcamentoKey = 'valorMaximoOrcamento';

  OrcamentoRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    required UserRepository userRepository, // NOVO: Receber UserRepository
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _userRepository = userRepository {
    _orcamentoBox = Hive.box<double>('orcamentoBox');
  }

  CollectionReference<Map<String, dynamic>> _getFirestoreCollection(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('orcamento'); // Coleção orcamento
  }

  Future<void> initializeDefaultOrcamento() async {
    // Apenas inicializa no Hive. Firestore é inicializado na primeira escrita.
    if (!_orcamentoBox.containsKey(_orcamentoKey)) {
      await _orcamentoBox.put(_orcamentoKey, 0.0);
      if (kDebugMode) {
        print('Orçamento padrão inicializado no Hive com R\$0.00');
      }
    }
  }

  Stream<OrcamentoModel> getOrcamento() {
    final user = _auth.currentUser;
    final isPremium = _userRepository.isPremium; // Consultar status premium

    if (user != null && isPremium) {
      // Usuário logado E PREMIUM: Observa Firestore
      return _getFirestoreCollection(user.uid)
          .doc(_orcamentoKey)
          .snapshots()
          .map((doc) {
            return doc.exists
                ? OrcamentoModel.fromFirestore(doc)
                : OrcamentoModel(
                    id: _orcamentoKey,
                    valorMaximo: 0.0,
                    updatedAt: DateTime.now(),
                    userId: user.uid,
                  );
          })
          .startWith(
            OrcamentoModel(
              id: _orcamentoKey,
              valorMaximo: 0.0,
              updatedAt: DateTime.now(),
              userId: user.uid,
            ),
          );
    } else {
      // NÃO PREMIUM (inclui não logado, anônimo, ou logado não premium): Usa Hive
      return _orcamentoBox
          .watch(key: _orcamentoKey)
          .map((event) {
            final double valor = _orcamentoBox.get(_orcamentoKey) ?? 0.0;
            // O OrcamentoModel agora tem userId. Para usuários anônimos, userId é null.
            // Para usuários logados não premium, userId é o user.uid.
            return OrcamentoModel(
              id: _orcamentoKey,
              valorMaximo: valor,
              updatedAt: DateTime.now(),
              userId: user
                  ?.uid, // Vincula ao userId do usuário logado (ou null se anônimo)
            );
          })
          .startWith(
            OrcamentoModel(
              id: _orcamentoKey,
              valorMaximo: _orcamentoBox.get(_orcamentoKey) ?? 0.0,
              updatedAt: DateTime.now(),
              userId: user
                  ?.uid, // Vincula ao userId do usuário logado (ou null se anônimo)
            ),
          );
    }
  }

  Future<void> updateOrcamento(double novoValor) async {
    final user = _auth.currentUser;
    final isPremium = _userRepository.isPremium;
    final orcamentoAtual = OrcamentoModel(
      id: _orcamentoKey,
      valorMaximo: novoValor,
      updatedAt: DateTime.now(),
      userId: user?.uid, // Vincula ao userId do usuário logado
    );

    // Atualiza o valor double no Hive (para uso local/gratuito)
    await _orcamentoBox.put(_orcamentoKey, novoValor);

    if (user != null && isPremium) {
      // Se o usuário estiver logado E FOR PREMIUM, atualiza no Firestore
      await _getFirestoreCollection(user.uid)
          .doc(_orcamentoKey)
          .set(
            orcamentoAtual.toFirestore(),
          ); // Set/Update o documento completo no Firestore
    }
  }
}
