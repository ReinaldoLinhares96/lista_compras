// ignore_for_file: depend_on_referenced_packages, avoid_print, unnecessary_brace_in_string_interps

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/compra_status_model.dart';
import '../../core/enums/compra_status_type.dart';
import 'package:rxdart/rxdart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CompraStatusRepository {
  late Box<CompraStatusModel> _compraStatusBox;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Instância do Firestore
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CompraStatusRepository() {
    _compraStatusBox = Hive.box<CompraStatusModel>('compraStatusBox');
  }

  CollectionReference<Map<String, dynamic>> _getFirestoreCollection() {
    // Retorna a coleção de status no nível raiz (global)
    return _firestore.collection('compraStatus');
  }

  Future<void> initializeDefaultCompraStatus() async {
    for (var type in CompraStatusType.values) {
      final String docId = type.value.toString();

      // Buscar no Hive
      final existingStatusHive = _compraStatusBox.get(docId);

      if (existingStatusHive == null) {
        String description;
        switch (type) {
          case CompraStatusType.ativa:
            description = 'Ativa';
            break;
          case CompraStatusType.finalizada:
            description = 'Finalizada';
            break;
          case CompraStatusType.cancelada:
            description = 'Cancelada';
            break;
        }
        final newStatus = CompraStatusModel(
          id: docId,
          descricao: description,
          isActive: true,
          isRemoved: false,
          userId: null, // Status padrão não têm userId
        );
        await _compraStatusBox.put(newStatus.id, newStatus);
        if (kDebugMode) {
          print(
            'Status de Compra padrão "${newStatus.descricao}" adicionado ao Hive.',
          );
        }

        // NOVO: Adicionar também ao Firestore (globalmente) se não existir lá
        // Isso é uma inicialização do lado do cliente para dados base.
        try {
          final docRef = _getFirestoreCollection().doc(newStatus.id);
          final docSnapshot = await docRef.get();
          if (!docSnapshot.exists) {
            await docRef.set(newStatus.toFirestore()); // Salvar no Firestore
            if (kDebugMode) {
              print(
                'Status de Compra padrão "${newStatus.descricao}" adicionado ao Firestore.',
              );
            }
          }
        } catch (e, stacktrace) {
          if (kDebugMode) {
            print(
              'Erro ao inicializar status padrão no Firestore: $e\n$stacktrace',
            );
          }
        }
      }
    }
  }

  // Obter todos os status de compra (Hive ou Firestore)
  Stream<List<CompraStatusModel>> getCompraStatus() {
    final user = _auth.currentUser;
    if (user != null) {
      // && verificar status premium
      // Se usuário logado, observar o Firestore (para status globais)
      return _getFirestoreCollection()
          .where('isRemoved', isEqualTo: false) // Se status puder ser removido
          .orderBy('descricao', descending: false)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => CompraStatusModel.fromFirestore(doc))
                .toList(),
          )
          .startWith([]); // Emissão inicial vazia
    } else {
      // Usuário não logado (anônimo/gratuito): Usa Hive
      return _compraStatusBox
          .watch()
          .map((event) {
            final allStatuses = _compraStatusBox.values
                .where((s) => s.isActive && !s.isRemoved)
                .toList();
            allStatuses.sort(
              (a, b) => a.descricao.toLowerCase().compareTo(
                b.descricao.toLowerCase(),
              ),
            );
            return allStatuses;
          })
          .startWith(
            _compraStatusBox.values
                .where((s) => s.isActive && !s.isRemoved)
                .toList(),
          );
    }
  }

  // Método para obter um status pelo ID (Hive ou Firestore)
  CompraStatusModel? getStatusById(String id) {
    final user = _auth.currentUser;
    if (user != null) {
      // && verificar status premium
      // Buscar do Firestore (síncrono, se os dados já estiverem em cache local pelo stream)
      // Ou, se realmente precisar de uma busca síncrona, fazer uma Future.
      // Por simplicidade, vamos buscar do Hive, que é mais rápido.
      final status = _compraStatusBox.get(id);
      return (status != null && status.isActive && !status.isRemoved)
          ? status
          : null;
    } else {
      // Usuário não logado (anônimo/gratuito): Usa Hive
      final status = _compraStatusBox.get(id);
      return (status != null && status.isActive && !status.isRemoved)
          ? status
          : null;
    }
  }

  // Adicionar métodos update e delete para CompraStatusModel se precisar gerenciar no futuro
  Future<void> updateCompraStatus(CompraStatusModel status) async {
    final user = _auth.currentUser;
    final statusComUserId = status.copyWith(
      userId: user?.uid,
    ); // Atualiza userId se for logado

    final existingStatusHive = _compraStatusBox.get(statusComUserId.id);
    if (existingStatusHive != null) {
      existingStatusHive.descricao = statusComUserId.descricao;
      existingStatusHive.isActive = statusComUserId.isActive;
      existingStatusHive.isRemoved = statusComUserId.isRemoved;
      existingStatusHive.userId = statusComUserId.userId; // Atualiza userId
      await existingStatusHive.save();
    } else {
      await _compraStatusBox.put(statusComUserId.id, statusComUserId);
    }

    if (user != null) {
      // && verificar status premium
      await _getFirestoreCollection()
          .doc(statusComUserId.id)
          .update(statusComUserId.toFirestore());
    }
  }

  Future<void> deleteCompraStatus(String id) async {
    final user = _auth.currentUser;

    final statusHive = _compraStatusBox.get(id);
    if (statusHive != null) {
      statusHive.isActive = false;
      statusHive.isRemoved = true;
      await statusHive.save();
    }

    if (user != null) {
      // && verificar status premium
      await _getFirestoreCollection().doc(id).update({
        'isActive': false,
        'isRemoved': true,
      });
    }
  }
}
