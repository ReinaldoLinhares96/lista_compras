// ignore_for_file: cast_from_null_always_fails, unnecessary_nullable_for_final_variable_declarations, curly_braces_in_flow_control_structures, unused_import, depend_on_referenced_packages

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lista_compras/presentation/pages/active_shopping_page.dart';
import '../models/compra_model.dart';
import '../../core/enums/compra_status_type.dart';
import '../models/compra_status_model.dart';
import 'package:rxdart/rxdart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_repository.dart'; // NOVO IMPORT: UserRepository

class CompraRepository {
  late Box<CompraModel> _comprasBox;
  late Box<CompraStatusModel> _compraStatusBox;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final UserRepository _userRepository; // Instância de UserRepository

  CompraRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    required UserRepository userRepository, // Receber UserRepository
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _userRepository = userRepository {
    _comprasBox = Hive.box<CompraModel>('comprasBox');
    _compraStatusBox = Hive.box<CompraStatusModel>('compraStatusBox');
  }

  CollectionReference<Map<String, dynamic>> _getFirestoreCollection(
    String userId,
  ) {
    return _firestore.collection('users').doc(userId).collection('compras');
  }

  Future<CompraModel> iniciarNovaCompra() async {
    final user = _auth.currentUser;
    final isPremium = _userRepository.isPremium; // Consultar status premium

    final CompraStatusModel? ativaStatusModel = _compraStatusBox.get(
      CompraStatusType.ativa.value.toString(),
    );
    if (ativaStatusModel == null) {
      throw Exception(
        'Status "Ativa" não encontrado na caixa de status de compra.',
      );
    }

    final CompraModel? compraExistente = await getCompraAtiva().first;
    if (compraExistente != null) {
      throw Exception(
        'Já existe uma compra ativa. Finalize-a ou cancele-a primeiro.',
      );
    }

    final novaCompra = CompraModel(
      dataHoraInicio: DateTime.now(),
      compraStatusId: ativaStatusModel.id,
      valorTotalCalculado: 0.0,
      isActive: true,
      isRemoved: false,
      userId: user?.uid, // Vincular ao usuário logado
    );

    await _comprasBox.put(novaCompra.id, novaCompra); // Salva no Hive (sempre)
    if (user != null && isPremium) {
      // Se usuário logado E PREMIUM, salva no Firestore
      await _getFirestoreCollection(
        user.uid,
      ).doc(novaCompra.id).set(novaCompra.toFirestore());
    }
    return novaCompra;
  }

  Stream<CompraModel?> getCompraAtiva() {
    final user = _auth.currentUser;
    final isPremium = _userRepository.isPremium; // Consultar status premium

    if (user != null && isPremium) {
      // Usuário logado E PREMIUM: Observa Firestore
      final CompraStatusModel? currentAtivaStatusModel = _compraStatusBox.get(
        CompraStatusType.ativa.value.toString(),
      );
      if (currentAtivaStatusModel == null) return Stream.value(null);

      return _getFirestoreCollection(user.uid)
          .where('isActive', isEqualTo: true)
          .where('isRemoved', isEqualTo: false)
          .where('compraStatusId', isEqualTo: currentAtivaStatusModel.id)
          .limit(1)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs.isNotEmpty
                ? CompraModel.fromFirestore(snapshot.docs.first)
                : null,
          )
          .startWith(null);
    } else {
      // NÃO PREMIUM (inclui não logado, anônimo, ou logado não premium): Usa Hive
      final CompraStatusModel? initialAtivaStatusModel = _compraStatusBox.get(
        CompraStatusType.ativa.value.toString(),
      );

      final CompraModel? initialActiveCompra = (initialAtivaStatusModel == null)
          ? null
          : _comprasBox.values.firstWhereOrNull(
              (c) =>
                  c.isActive &&
                  !c.isRemoved &&
                  c.compraStatusId == initialAtivaStatusModel.id &&
                  c.userId ==
                      _auth
                          .currentUser
                          ?.uid, // Filtra pelo userId atual (ou null para anonimos)
            );

      return _comprasBox
          .watch()
          .map((event) {
            final CompraStatusModel? currentAtivaStatusModel = _compraStatusBox
                .get(CompraStatusType.ativa.value.toString());

            if (currentAtivaStatusModel == null) {
              return null;
            }

            final CompraModel? compra = _comprasBox.values.firstWhereOrNull(
              (c) =>
                  c.isActive &&
                  !c.isRemoved &&
                  c.compraStatusId == currentAtivaStatusModel.id &&
                  c.userId == _auth.currentUser?.uid, // FILTRO userId
            );
            return compra;
          })
          .startWith(initialActiveCompra);
    }
  }

  Future<void> updateCompra(CompraModel compra) async {
    final user = _auth.currentUser;
    final isPremium = _userRepository.isPremium;
    final compraComUserId = compra.copyWith(
      userId: user?.uid,
      updatedAt: DateTime.now(),
    );

    await _comprasBox.put(
      compraComUserId.id,
      compraComUserId,
    ); // Atualiza no Hive

    if (user != null && isPremium) {
      // Se logado E PREMIUM, atualiza no Firestore
      await _getFirestoreCollection(
        user.uid,
      ).doc(compraComUserId.id).update(compraComUserId.toFirestore());
    }
  }

  Future<void> finalizarCompra(String compraId, double valorFinal) async {
    final user = _auth.currentUser;
    final isPremium = _userRepository.isPremium;

    final CompraStatusModel? finalizadaStatusModel = _compraStatusBox.get(
      CompraStatusType.finalizada.value.toString(),
    );

    if (finalizadaStatusModel == null) {
      throw Exception(
        'Status "Finalizada" não encontrado na caixa de status de compra.',
      );
    }
    final String finalizadaStatusId = finalizadaStatusModel.id;

    final compra = _comprasBox.get(compraId);
    if (compra != null) {
      compra.dataHoraFim = DateTime.now();
      compra.valorTotalCalculado = valorFinal;
      compra.compraStatusId = finalizadaStatusId;
      compra.isActive = false;
      compra.updatedAt = DateTime.now();
      await compra.save();
    }

    if (user != null && isPremium) {
      // Se logado E PREMIUM, atualiza no Firestore
      await _getFirestoreCollection(user.uid).doc(compraId).update({
        'dataHoraFim': FieldValue.serverTimestamp(),
        'valorTotalCalculado': valorFinal,
        'compraStatusId': finalizadaStatusModel.id,
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> cancelarCompra(String compraId) async {
    // Removido valorFinal, pois já é 0 para cancelado
    final user = _auth.currentUser;
    final isPremium = _userRepository.isPremium;

    final CompraStatusModel? canceladaStatusModel = _compraStatusBox.get(
      CompraStatusType.cancelada.value.toString(),
    );

    if (canceladaStatusModel == null) {
      throw Exception(
        'Status "Cancelada" não encontrado na caixa de status de compra.',
      );
    }
    final String canceladaStatusId = canceladaStatusModel.id;

    final compra = _comprasBox.get(compraId);
    if (compra != null) {
      compra.dataHoraFim = DateTime.now();
      compra.valorTotalCalculado = 0.0; // Valor 0 para cancelado
      compra.compraStatusId = canceladaStatusId;
      compra.isActive = false;
      compra.updatedAt = DateTime.now();
      await compra.save();
    }

    if (user != null && isPremium) {
      // Se logado E PREMIUM, atualiza no Firestore
      await _getFirestoreCollection(user.uid).doc(compraId).update({
        'dataHoraFim': FieldValue.serverTimestamp(),
        'valorTotalCalculado': 0.0,
        'compraStatusId': canceladaStatusId,
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<List<CompraModel>> getFilteredCompras({
    String? statusId,
    DateTime? startDate,
    DateTime? endDate,
    double? minTotal,
    double? maxTotal,
  }) {
    final user = _auth.currentUser;
    final isPremium = _userRepository.isPremium;

    final CompraStatusModel? finalizadaStatusModel = _compraStatusBox.get(
      CompraStatusType.finalizada.value.toString(),
    );
    final CompraStatusModel? canceladaStatusModel = _compraStatusBox.get(
      CompraStatusType.cancelada.value.toString(),
    );

    if (user != null && isPremium) {
      // Usuário logado E PREMIUM: Usa Firestore
      Query firestoreQuery = _getFirestoreCollection(user.uid);

      firestoreQuery = firestoreQuery.where('isActive', isEqualTo: false);
      firestoreQuery = firestoreQuery.where('isRemoved', isEqualTo: false);

      if (statusId != null) {
        final CompraStatusModel? targetStatusModel = _compraStatusBox.get(
          statusId,
        );
        if (targetStatusModel != null) {
          firestoreQuery = firestoreQuery.where(
            'compraStatusId',
            isEqualTo: targetStatusModel.id,
          );
        } else {
          return Stream.value([]); // Status não encontrado, retorna vazio
        }
      } else {
        firestoreQuery = firestoreQuery.where(
          'compraStatusId',
          whereIn: [
            finalizadaStatusModel?.id,
            canceladaStatusModel?.id,
          ].whereType<String>().toList(),
        );
      }

      firestoreQuery = firestoreQuery.orderBy('dataHoraFim', descending: true);

      if (startDate != null) {
        firestoreQuery = firestoreQuery.where(
          'dataHoraFim',
          isGreaterThanOrEqualTo: startDate,
        );
      }
      if (endDate != null) {
        firestoreQuery = firestoreQuery.where(
          'dataHoraFim',
          isLessThanOrEqualTo: endDate.add(
            const Duration(hours: 23, minutes: 59, seconds: 59),
          ),
        );
      }

      if (minTotal != null) {
        firestoreQuery = firestoreQuery.where(
          'valorTotalCalculado',
          isGreaterThanOrEqualTo: minTotal,
        );
      }
      if (maxTotal != null) {
        firestoreQuery = firestoreQuery.where(
          'valorTotalCalculado',
          isLessThanOrEqualTo: maxTotal,
        );
      }

      return firestoreQuery
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => CompraModel.fromFirestore(doc))
                .toList(),
          )
          .startWith([]);
    } else {
      // NÃO PREMIUM (inclui não logado, anônimo, ou logado não premium): Usa Hive
      return _comprasBox
          .watch()
          .map((event) {
            List<CompraModel> filteredCompras = _comprasBox.values.where((
              compra,
            ) {
              bool matchesStatus = true;
              if (statusId != null && statusId.isNotEmpty) {
                matchesStatus = compra.compraStatusId == statusId;
              } else {
                // Se nenhum status específico foi pedido, inclua APENAS Finalizada ou Cancelada.
                // Você precisará dos IDs de 'Finalizada' e 'Cancelada' aqui.
                final String? finalizadaStatusId = _compraStatusBox.values
                    .firstWhereOrNull(
                      (s) =>
                          s.id == CompraStatusType.finalizada.value.toString(),
                    )
                    ?.id;
                final String? canceladaStatusId = _compraStatusBox.values
                    .firstWhereOrNull(
                      (s) =>
                          s.id == CompraStatusType.cancelada.value.toString(),
                    )
                    ?.id;

                matchesStatus =
                    (compra.compraStatusId == finalizadaStatusId ||
                    compra.compraStatusId == canceladaStatusId);
              }

              // **CORREÇÃO AQUI:** Usar dataHoraFim para a filtragem de datas, se disponível
              final DateTime? dateToFilterBy =
                  compra.dataHoraFim ??
                  compra.dataHoraInicio; // Preferir dataFim, se não, dataInicio

              bool matchesDate = true;
              if (startDate != null && dateToFilterBy != null) {
                matchesDate =
                    matchesDate &&
                    (dateToFilterBy.isAfter(
                          startDate.subtract(const Duration(days: 1)),
                        ) || // Para incluir o dia inteiro inicial
                        dateToFilterBy.isAtSameMomentAs(startDate));
              }
              if (endDate != null && dateToFilterBy != null) {
                matchesDate =
                    matchesDate &&
                    (dateToFilterBy.isBefore(
                          endDate.add(const Duration(days: 1)),
                        ) || // Para incluir o dia inteiro final
                        dateToFilterBy.isAtSameMomentAs(endDate));
              }

              // Filtro por valor total (mantido como estava)
              bool matchesMinTotal =
                  minTotal == null || compra.valorTotalCalculado >= minTotal;
              bool matchesMaxTotal =
                  maxTotal == null || compra.valorTotalCalculado <= maxTotal;

              // Retorna verdadeiro se todas as condições forem atendidas
              return matchesStatus &&
                  matchesDate &&
                  matchesMinTotal &&
                  matchesMaxTotal;
            }).toList();

            // **CORREÇÃO AQUI:** Ordenar pela data mais relevante (dataHoraFim)
            filteredCompras.sort((a, b) {
              final dateA =
                  a.dataHoraFim ??
                  a.dataHoraInicio; // Prefere dataFim para ordenação
              final dateB =
                  b.dataHoraFim ??
                  b.dataHoraInicio; // Prefere dataFim para ordenação
              return dateB.compareTo(
                dateA,
              ); // Do mais recente para o mais antigo
            });

            return filteredCompras;
          })
          .startWith(
            _comprasBox.values.where((compra) {
              bool matchesStatus =
                  statusId == null || compra.compraStatusId == statusId;

              final DateTime? dateToFilterBy =
                  compra.dataHoraFim ?? compra.dataHoraInicio;

              bool matchesDate = true;
              if (startDate != null && dateToFilterBy != null) {
                matchesDate =
                    matchesDate &&
                    (dateToFilterBy.isAfter(
                          startDate.subtract(const Duration(days: 1)),
                        ) ||
                        dateToFilterBy.isAtSameMomentAs(startDate));
              }
              if (endDate != null && dateToFilterBy != null) {
                matchesDate =
                    matchesDate &&
                    (dateToFilterBy.isBefore(
                          endDate.add(const Duration(days: 1)),
                        ) ||
                        dateToFilterBy.isAtSameMomentAs(endDate));
              }

              bool matchesMinTotal =
                  minTotal == null || compra.valorTotalCalculado >= minTotal;
              bool matchesMaxTotal =
                  maxTotal == null || compra.valorTotalCalculado <= maxTotal;

              return matchesStatus &&
                  matchesDate &&
                  matchesMinTotal &&
                  matchesMaxTotal;
            }).toList()..sort((a, b) {
              // Ordenação para o startWith também
              final dateA = a.dataHoraFim ?? a.dataHoraInicio;
              final dateB = b.dataHoraFim ?? b.dataHoraInicio;
              return dateB.compareTo(dateA);
            }),
          );
    }
  }
}
