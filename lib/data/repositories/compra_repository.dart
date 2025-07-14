// ignore_for_file: cast_from_null_always_fails, unnecessary_nullable_for_final_variable_declarations, curly_braces_in_flow_control_structures, unused_import, depend_on_referenced_packages

import 'package:hive_flutter/hive_flutter.dart';
import 'package:lista_compras/presentation/pages/active_shopping_page.dart';
import '../models/compra_model.dart';
import '../../core/enums/compra_status_type.dart'; // Mantenha este enum
import '../models/compra_status_model.dart';
import 'package:rxdart/rxdart.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // NOVO IMPORT
import 'package:firebase_auth/firebase_auth.dart'; // NOVO IMPORT

class CompraRepository {
  late Box<CompraModel> _comprasBox;
  late Box<CompraStatusModel> _compraStatusBox; // Referência à caixa de status
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CompraRepository() {
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

    await _comprasBox.put(novaCompra.id, novaCompra);
    if (user != null) {
      // && verificar status premium
      await _getFirestoreCollection(
        user.uid,
      ).doc(novaCompra.id).set(novaCompra.toFirestore());
    }
    return novaCompra;
  }

  Stream<CompraModel?> getCompraAtiva() {
    final user = _auth.currentUser;
    if (user != null) {
      // && verificar status premium
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
      final CompraStatusModel? ativaStatusModel = _compraStatusBox.get(
        CompraStatusType.ativa.value.toString(),
      ); // ATUALIZADO

      final CompraModel? initialActiveCompra = (ativaStatusModel == null)
          ? null
          : _comprasBox.values.firstWhereOrNull(
              (c) =>
                  c.isActive &&
                  !c.isRemoved &&
                  c.compraStatusId == ativaStatusModel.id,
            );

      return _comprasBox
          .watch()
          .map((event) {
            // Revalidar o CompraStatusModel para 'Ativa' a cada evento de stream (se ele puder mudar)
            final CompraStatusModel? currentAtivaStatusModel = _compraStatusBox
                .get(CompraStatusType.ativa.value.toString()); // ATUALIZADO

            if (currentAtivaStatusModel == null) {
              return null;
            }

            final CompraModel? compra = _comprasBox.values.firstWhereOrNull(
              (c) =>
                  c.isActive &&
                  !c.isRemoved &&
                  c.compraStatusId == currentAtivaStatusModel.id,
            );
            return compra;
          })
          .startWith(initialActiveCompra);
    }
  }

  Future<void> updateCompra(CompraModel compra) async {
    final user = _auth.currentUser;
    final compraComUserId = compra.copyWith(
      userId: user?.uid,
      updatedAt: DateTime.now(),
    );

    await _comprasBox.put(compraComUserId.id, compraComUserId);

    if (user != null) {
      // && verificar status premium
      await _getFirestoreCollection(
        user.uid,
      ).doc(compraComUserId.id).update(compraComUserId.toFirestore());
    }
  }

  Future<void> finalizarCompra(String compraId, double valorFinal) async {
    final user = _auth.currentUser;

    final CompraStatusModel? finalizadaStatus = _compraStatusBox.values
        .firstWhereOrNull(
          (s) => s.id == CompraStatusType.finalizada.value.toString(),
        );

    if (finalizadaStatus == null) {
      throw Exception(
        'Status "Finalizada" não encontrado na caixa de status de compra.',
      );
    }
    final String finalizadaStatusId = finalizadaStatus.id;

    final compra = _comprasBox.get(compraId);
    if (compra != null) {
      compra.dataHoraFim = DateTime.now();
      compra.valorTotalCalculado = valorFinal;
      compra.compraStatusId = finalizadaStatusId;
      compra.updatedAt = DateTime.now();
      await compra.save();
    }

    if (user != null) {
      // && verificar status premium
      await _getFirestoreCollection(user.uid).doc(compraId).update({
        'dataHoraFim': FieldValue.serverTimestamp(),
        'valorTotalCalculado': valorFinal,
        'compraStatusId': finalizadaStatus.id,
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> cancelarCompra(String compraId, double valorFinal) async {
    final user = _auth.currentUser;

    final CompraStatusModel? canceladoStatus = _compraStatusBox.values
        .firstWhereOrNull(
          (s) => s.id == CompraStatusType.cancelada.value.toString(),
        );

    if (canceladoStatus == null) {
      throw Exception(
        'Status "Finalizada" não encontrado na caixa de status de compra.',
      );
    }
    final String canceladoStatusId = canceladoStatus.id;

    final compra = _comprasBox.get(compraId);
    if (compra != null) {
      compra.dataHoraFim = DateTime.now();
      compra.valorTotalCalculado = valorFinal;
      compra.compraStatusId = canceladoStatusId;
      compra.updatedAt = DateTime.now();
      await compra.save();
    }

    if (user != null) {
      // && verificar status premium
      await _getFirestoreCollection(user.uid).doc(compraId).update({
        'dataHoraFim': FieldValue.serverTimestamp(),
        'valorTotalCalculado': 0.0,
        'compraStatusId': canceladoStatus.id,
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

    Stream<List<CompraModel>> hiveStream = _comprasBox
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
                    (s) => s.id == CompraStatusType.finalizada.value.toString(),
                  )
                  ?.id;
              final String? canceladaStatusId = _compraStatusBox.values
                  .firstWhereOrNull(
                    (s) => s.id == CompraStatusType.cancelada.value.toString(),
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
            return dateB.compareTo(dateA); // Do mais recente para o mais antigo
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

    if (user != null) {
      // && verificar status premium
      return _getFirestoreCollection(user.uid)
          .where('isActive', isEqualTo: false)
          .where('isRemoved', isEqualTo: false)
          .orderBy('dataHoraFim', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => CompraModel.fromFirestore(doc))
                .toList(),
          )
          .startWith([]);
    } else {
      return hiveStream;
    }
  }
}
