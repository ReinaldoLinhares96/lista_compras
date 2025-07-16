// lib/data/repositories/user_repository.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:lista_compras/data/models/user_profile_model.dart';
import 'package:rxdart/rxdart.dart'; // Para BehaviorSubject

class UserRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream para o status premium do usuário atual
  // BehaviorSubject mantém o último valor e emite para novos ouvintes
  final BehaviorSubject<bool> _isPremiumSubject = BehaviorSubject<bool>.seeded(
    false,
  );
  Stream<bool> get isPremiumStream => _isPremiumSubject.stream;
  // NOVO: Getter síncrono para o status premium atual
  bool get isPremium => _isPremiumSubject.value;

  // Stream para o UserProfileModel completo do usuário atual
  final BehaviorSubject<UserProfileModel?> _userProfileSubject =
      BehaviorSubject<UserProfileModel?>.seeded(null);
  Stream<UserProfileModel?> get userProfileStream => _userProfileSubject.stream;

  UserRepository() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _listenToUserProfile(user.uid);
      } else {
        // Usuário deslogado, resetar streams
        _isPremiumSubject.add(false);
        _userProfileSubject.add(null);
      }
    });
    // Opcional: Carregar status premium inicial do Hive (se estiver usando cache)
    // _isPremiumSubject.add(_premiumStatusBox.get('isPremium', defaultValue: false)!);
  }

  // Ouve as mudanças no perfil do usuário no Firestore
  void _listenToUserProfile(String userId) {
    _firestore.collection('users').doc(userId).snapshots().listen((
      docSnapshot,
    ) {
      if (docSnapshot.exists) {
        final userProfile = UserProfileModel.fromFirestore(docSnapshot);
        _isPremiumSubject.add(userProfile.isPremium);
        _userProfileSubject.add(userProfile);
      } else {
        // Documento do perfil não existe, considerar não premium
        _isPremiumSubject.add(false);
        _userProfileSubject.add(null);
        // Opcional: Criar perfil base se não existir
        // if(_auth.currentUser != null && _auth.currentUser!.uid == userId) {
        //   createUserProfile(userId: userId, email: _auth.currentUser!.email ?? 'email_nao_disponivel');
        // }
      }
    });
  }

  // Cria ou atualiza o perfil do usuário no Firestore
  Future<void> createUserProfile({
    required String userId,
    required String email,
    String? displayName,
    bool isPremium = false,
  }) async {
    final userProfile = UserProfileModel(
      userId: userId,
      email: email,
      displayName: displayName,
      isPremium: isPremium,
    );
    await _firestore
        .collection('users')
        .doc(userId)
        .set(userProfile.toFirestore(), SetOptions(merge: true));
  }

  // Obtém o perfil do usuário (útil para uma leitura única)
  Future<UserProfileModel?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserProfileModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao obter perfil do usuário: $e');
      }
      return null;
    }
  }

  // Atualiza o status premium de um usuário
  Future<void> updatePremiumStatus(String userId, bool newStatus) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isPremium': newStatus,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao atualizar status premium: $e');
      }
      rethrow;
    }
  }

  // Método para recuperar senha (usando Firebase Auth, não Firestore diretamente)
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (kDebugMode) {
        print('E-mail de redefinição de senha enviado para $email');
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Erro ao enviar e-mail de redefinição de senha: ${e.message}');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('Erro inesperado ao redefinir senha: $e');
      }
      rethrow;
    }
  }
}
