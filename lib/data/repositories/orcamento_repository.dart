// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/orcamento_model.dart';
import 'package:rxdart/rxdart.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // NOVO IMPORT
import 'package:firebase_auth/firebase_auth.dart'; // NOVO IMPORT

class OrcamentoRepository {
  late Box<double> _orcamentoBox;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _orcamentoKey = 'valorMaximoOrcamento';

  OrcamentoRepository() {
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
    if (!_orcamentoBox.containsKey(_orcamentoKey)) {
      await _orcamentoBox.put(_orcamentoKey, 0.0);
      if (kDebugMode) {
        print('Orçamento padrão inicializado no Hive com R\$0.00');
      }
    }
  }

  Stream<OrcamentoModel> getOrcamento() {
    final user = _auth.currentUser;
    if (user != null) {
      // && verificar status premium
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
      return _orcamentoBox
          .watch(key: _orcamentoKey)
          .map((event) {
            final double valor = _orcamentoBox.get(_orcamentoKey) ?? 0.0;
            return OrcamentoModel(
              id: _orcamentoKey,
              valorMaximo: valor,
              updatedAt: DateTime.now(),
            );
          })
          .startWith(
            OrcamentoModel(
              id: _orcamentoKey,
              valorMaximo: _orcamentoBox.get(_orcamentoKey) ?? 0.0,
              updatedAt: DateTime.now(),
            ),
          );
    }
  }

  Future<void> updateOrcamento(double novoValor) async {
    final user = _auth.currentUser;
    final orcamentoAtual = OrcamentoModel(
      id: _orcamentoKey,
      valorMaximo: novoValor,
      updatedAt: DateTime.now(),
      userId: user?.uid,
    );

    await _orcamentoBox.put(
      _orcamentoKey,
      novoValor,
    ); // Atualiza o valor double no Hive

    if (user != null) {
      // && verificar status premium
      await _getFirestoreCollection(user.uid)
          .doc(_orcamentoKey)
          .set(
            orcamentoAtual.toFirestore(),
          ); // Set/Update o documento completo no Firestore
    }
  }

  // Métodos de exclusão lógica para orçamento seriam mais complexos
  // pois a orcamentoBox armazena apenas o double. Se OrcamentoModel fosse
  // salvo diretamente na box, seria mais simples.
  // Por enquanto, não adicionamos delete/remove lógico aqui, pois não é o foco do bug atual.
}
