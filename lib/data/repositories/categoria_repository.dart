// ignore_for_file: depend_on_referenced_packages, cast_from_null_always_fails, unnecessary_brace_in_string_interps, unused_import

import 'dart:math' as developer;

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lista_compras/presentation/pages/active_shopping_page.dart';
import '../models/categoria_model.dart';
import 'package:rxdart/rxdart.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // NOVO IMPORT
import 'package:firebase_auth/firebase_auth.dart'; // NOVO IMPORT

class CategoriaRepository {
  late Box<CategoriaModel> _categoriasBox;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CategoriaRepository() {
    _categoriasBox = Hive.box<CategoriaModel>('categoriasBox');
  }

  CollectionReference<Map<String, dynamic>> _getFirestoreCollection(
    String userId,
  ) {
    return _firestore.collection('users').doc(userId).collection('categorias');
  }

  Stream<List<CategoriaModel>> getCategorias() {
    // Filtrar apenas categorias ativas
    final user = _auth.currentUser;
    if (user != null) {
      // && verificar status premium
      return _getFirestoreCollection(user.uid)
          .where('isRemoved', isEqualTo: false)
          .orderBy('descricao', descending: false)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => CategoriaModel.fromFirestore(doc))
                .toList(),
          )
          .startWith([]);
    } else {
      return _categoriasBox
          .watch()
          .map((event) {
            final allCategorias = _categoriasBox.values
                .where((c) => c.isActive && !c.isRemoved)
                .toList(); // FILTRO AQUI
            allCategorias.sort(
              (a, b) => a.descricao.toLowerCase().compareTo(
                b.descricao.toLowerCase(),
              ),
            );
            return allCategorias;
          })
          .startWith(
            _categoriasBox.values
                .where((c) => c.isActive && !c.isRemoved)
                .toList(),
          );
    } // Emissão inicial filtrada
  }

  Future<void> addCategoria(CategoriaModel categoria) async {
    final user = _auth.currentUser;
    final categoriaComUserId = categoria.copyWith(userId: user?.uid);

    await _categoriasBox.put(categoriaComUserId.id, categoriaComUserId);

    if (user != null) {
      // && verificar status premium
      await _getFirestoreCollection(
        user.uid,
      ).doc(categoriaComUserId.id).set(categoriaComUserId.toFirestore());
    }
  }

  Future<CategoriaModel?> getCategoriaByDescricao(String descricao) async {
    final user = _auth.currentUser;
    if (user != null) {
      // && verificar status premium
      final querySnapshot = await _getFirestoreCollection(user.uid)
          .where('descricao', isEqualTo: descricao)
          .where('isRemoved', isEqualTo: false)
          .limit(1)
          .get();
      return querySnapshot.docs.isNotEmpty
          ? CategoriaModel.fromFirestore(querySnapshot.docs.first)
          : null;
    } else {
      return _categoriasBox.values.firstWhereOrNull(
        (c) =>
            c.descricao.toLowerCase() == descricao.toLowerCase() &&
            c.isActive &&
            !c.isRemoved,
      );
    }
  }

  Future<void> updateCategoria(CategoriaModel categoria) async {
    final user = _auth.currentUser;
    final categoriaComUserId = categoria.copyWith(userId: user?.uid);

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

    if (user != null) {
      // && verificar status premium
      await _getFirestoreCollection(
        user.uid,
      ).doc(categoriaComUserId.id).update(categoriaComUserId.toFirestore());
    }
  }

  Future<void> deleteCategoria(String id) async {
    final user = _auth.currentUser;

    final categoriaHive = _categoriasBox.get(id);
    if (categoriaHive != null) {
      categoriaHive.isActive = false;
      categoriaHive.isRemoved = true;
      await categoriaHive.save();
    }

    if (user != null) {
      // && verificar status premium
      await _getFirestoreCollection(
        user.uid,
      ).doc(id).update({'isActive': false, 'isRemoved': true});
    }
  }
}
