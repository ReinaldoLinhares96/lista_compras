import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart'; // NOVO: Importar Hive

part 'user_profile_model.g.dart'; // NOVO: Esta linha será gerada pelo hive_generator

@HiveType(typeId: 7) // NOVO: typeId deve ser único para cada modelo
class UserProfileModel extends HiveObject {
  // NOVO: Estender HiveObject
  @HiveField(0)
  final String userId;
  @HiveField(1)
  final String email;
  @HiveField(2)
  final String? displayName;
  @HiveField(3) // NOVO: HiveField para isPremium
  bool isPremium; // Não é final, pode ser alterado

  UserProfileModel({
    required this.userId,
    required this.email,
    this.displayName,
    this.isPremium = false, // Padrão é não premium
  });

  // Converte um UserProfileModel para um mapa para salvar no Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'email': email,
      'displayName': displayName,
      'isPremium': isPremium,
      'lastUpdated':
          FieldValue.serverTimestamp(), // Adiciona um timestamp de atualização
    };
  }

  // Cria um UserProfileModel a partir de um documento do Firestore
  factory UserProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?; // Pode ser nulo
    if (data == null) {
      throw StateError('missing data for UserProfileModel(id: ${doc.id})');
    }
    return UserProfileModel(
      userId: data['userId'] as String,
      email: data['email'] as String,
      displayName: data['displayName'] as String?,
      isPremium:
          data['isPremium'] as bool? ??
          false, // Garante que é bool e tem padrão
    );
  }

  // Cria um UserProfileModel a partir de um mapa (útil para testes ou outros usos)
  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    return UserProfileModel(
      userId: map['userId'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String?,
      isPremium: map['isPremium'] as bool? ?? false,
    );
  }

  // Adicionando copyWith para consistência, se for usado em repositórios para atualizar
  UserProfileModel copyWith({
    String? userId,
    String? email,
    String? displayName,
    bool? isPremium,
  }) {
    return UserProfileModel(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      isPremium: isPremium ?? this.isPremium,
    );
  }
}
