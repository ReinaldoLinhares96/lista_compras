// ignore_for_file: depend_on_referenced_packages, cast_from_null_always_fails, unnecessary_brace_in_string_interps, unused_import

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lista_compras/presentation/pages/active_shopping_page.dart';
import '../models/categoria_model.dart';
import 'package:rxdart/rxdart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_repository.dart'; // NOVO IMPORT: UserRepository// Import da extensão

class CategoriaRepository {
  late Box<CategoriaModel> _categoriasBox;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final UserRepository _userRepository; // NOVO: Instância de UserRepository

  CategoriaRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    required UserRepository userRepository, // NOVO: Receber UserRepository
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _userRepository = userRepository {
    _categoriasBox = Hive.box<CategoriaModel>('categoriasBox');
  }

  CollectionReference<Map<String, dynamic>> _getFirestoreCollection(
    String userId,
  ) {
    return _firestore.collection('users').doc(userId).collection('categorias');
  }

  Stream<List<CategoriaModel>> getCategorias() {
    final user = _auth.currentUser;
    final isPremium = _userRepository.isPremium; // Consultar o status premium

    if (user != null && isPremium) {
      // Usuário logado E PREMIUM: Observar Firestore
      return _getFirestoreCollection(user.uid)
          .where('isRemoved', isEqualTo: false)
          .orderBy('descricao', descending: false)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => CategoriaModel.fromFirestore(doc))
                .toList(),
          )
          .startWith([]); // Emissão inicial vazia
    } else {
      // NÃO PREMIUM (inclui anônimo se o fluxo permitisse, e logados não premium): Observar Hive
      return _categoriasBox
          .watch()
          .map((event) {
            final allCategorias = _categoriasBox.values
                .where(
                  (c) =>
                      c.isActive &&
                      !c.isRemoved &&
                      // FILTRO userId: Se usuário logado (não premium), userId deve ser o UID atual.
                      // Se usuário NÃO logado (anônimo, se o fluxo permitisse), userId deve ser null.
                      ((user == null && c.userId == null) ||
                          (user != null && c.userId == user.uid)),
                )
                .toList();
            allCategorias.sort(
              (a, b) => a.descricao.toLowerCase().compareTo(
                b.descricao.toLowerCase(),
              ),
            );
            return allCategorias;
          })
          .startWith(
            _categoriasBox.values
                .where(
                  (c) =>
                      c.isActive &&
                      !c.isRemoved &&
                      ((user == null && c.userId == null) ||
                          (user != null && c.userId == user.uid)),
                )
                .toList(),
          );
    }
  }

  Future<void> addCategoria(CategoriaModel categoria) async {
    final user = _auth.currentUser;
    final isPremium = _userRepository.isPremium;
    final categoriaComUserId = categoria.copyWith(userId: user?.uid);

    await _categoriasBox.put(
      categoriaComUserId.id,
      categoriaComUserId,
    ); // Salvar no Hive (sempre)

    if (user != null && isPremium) {
      // Se logado E PREMIUM, salva no Firestore
      await _getFirestoreCollection(
        user.uid,
      ).doc(categoriaComUserId.id).set(categoriaComUserId.toFirestore());
    }
  }

  Future<CategoriaModel?> getCategoriaByDescricao(String descricao) async {
    final user = _auth.currentUser;
    final isPremium = _userRepository.isPremium;

    if (user != null && isPremium) {
      // Logado E PREMIUM: Buscar do Firestore
      final querySnapshot = await _getFirestoreCollection(user.uid)
          .where('descricao', isEqualTo: descricao)
          .where('isRemoved', isEqualTo: false)
          .limit(1)
          .get();
      return querySnapshot.docs.isNotEmpty
          ? CategoriaModel.fromFirestore(querySnapshot.docs.first)
          : null;
    } else {
      // NÃO PREMIUM: Buscar do Hive
      return _categoriasBox.values.firstWhereOrNull(
        (c) =>
            c.descricao.toLowerCase() == descricao.toLowerCase() &&
            c.isActive &&
            !c.isRemoved &&
            ((user == null && c.userId == null) ||
                (user != null && c.userId == user.uid)), // FILTRO userId
      );
    }
  }

  Future<void> updateCategoria(CategoriaModel categoria) async {
    final user = _auth.currentUser;
    final isPremium = _userRepository.isPremium;
    final categoriaComUserId = categoria.copyWith(userId: user?.uid);

    // Atualizar no Hive
    final existingCategoriaHive = _categoriasBox.get(categoriaComUserId.id);
    if (existingCategoriaHive != null) {
      existingCategoriaHive.descricao = categoriaComUserId.descricao;
      existingCategoriaHive.isActive = categoriaComUserId.isActive;
      existingCategoriaHive.isRemoved = categoriaComUserId.isRemoved;
      existingCategoriaHive.userId = categoriaComUserId.userId;
      await existingCategoriaHive.save();
    } else {
      await _categoriasBox.put(categoriaComUserId.id, categoriaComUserId);
    }

    if (user != null && isPremium) {
      // Se logado E PREMIUM, atualiza no Firestore
      await _getFirestoreCollection(
        user.uid,
      ).doc(categoriaComUserId.id).update(categoriaComUserId.toFirestore());
    }
  }

  Future<void> deleteCategoria(String id) async {
    final user = _auth.currentUser;
    final isPremium = _userRepository.isPremium;

    // Remover logicamente no Hive
    final categoriaHive = _categoriasBox.get(id);
    if (categoriaHive != null) {
      categoriaHive.isActive = false;
      categoriaHive.isRemoved = true;
      await categoriaHive.save();
    }

    if (user != null && isPremium) {
      // Se logado E PREMIUM, atualiza no Firestore
      await _getFirestoreCollection(
        user.uid,
      ).doc(id).update({'isActive': false, 'isRemoved': true});
    }
  }
}
