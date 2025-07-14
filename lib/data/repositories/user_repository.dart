// lib/data/repositories/user_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:rxdart/rxdart.dart'; // Para o BehaviorSubject

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Box<bool> _premiumStatusBox; // Para cachear o status premium localmente

  // Usar um BehaviorSubject para o stream de status premium
  final BehaviorSubject<bool> _isPremiumSubject = BehaviorSubject<bool>.seeded(
    false,
  );
  Stream<bool> get isPremiumStream => _isPremiumSubject.stream;
  bool get isPremium => _isPremiumSubject.value;

  UserRepository() {
    _premiumStatusBox = Hive.box<bool>('premiumStatusBox');
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _listenToUserPremiumStatus(user.uid);
      } else {
        _isPremiumSubject.add(false); // Resetar se deslogado
      }
    });
    // Carregar status premium inicial do Hive
    _isPremiumSubject.add(
      _premiumStatusBox.get('isPremium', defaultValue: false)!,
    );
  }

  // Coleção Firestore para perfis de usuário
  CollectionReference<Map<String, dynamic>> _getUserProfileCollection(
    String userId,
  ) {
    return _firestore.collection('users').doc(userId).collection('profile');
  }

  // Método para atualizar o status premium do usuário
  Future<void> updateUserPremiumStatus(bool status) async {
    final user = _auth.currentUser;
    if (user != null) {
      // Atualiza no Firestore
      await _getUserProfileCollection(user.uid).doc('data').set(
        {'isPremium': status, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(
          merge: true,
        ), // Usa merge para não sobrescrever outros campos
      );
      // Atualiza o cache local no Hive
      await _premiumStatusBox.put('isPremium', status);
      // Atualiza o stream para notificar os listeners
      _isPremiumSubject.add(status);
    }
  }

  // Ouve mudanças no status premium do Firestore
  void _listenToUserPremiumStatus(String userId) {
    _getUserProfileCollection(userId).doc('data').snapshots().listen((
      snapshot,
    ) {
      if (snapshot.exists) {
        final data = snapshot.data();
        final bool premium = data?['isPremium'] as bool? ?? false;
        if (premium != _isPremiumSubject.value) {
          _isPremiumSubject.add(premium);
          _premiumStatusBox.put('isPremium', premium); // Atualiza cache Hive
        }
      } else {
        // Documento de perfil não existe, assume não premium
        if (_isPremiumSubject.value != false) {
          _isPremiumSubject.add(false);
          _premiumStatusBox.put('isPremium', false);
        }
      }
    });
  }

  // Método para verificar se o usuário é premium (síncrono, baseado no último valor)
  bool checkIfUserIsPremium() {
    return _isPremiumSubject.value;
  }

  // Método para criar/atualizar o perfil do usuário no Firestore
  Future<void> createUserProfile(String userId, String? email) async {
    await _getUserProfileCollection(userId).doc('data').set({
      'userId': userId,
      'email': email,
      'isPremium': false, // Começa como não premium
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
