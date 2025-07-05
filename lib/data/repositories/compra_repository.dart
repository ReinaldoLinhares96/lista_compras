import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/compra_model.dart';
import '../../core/constants/firestore_collections.dart';
import '../../core/enums/compra_status_type.dart'; // Para referenciar o enum

class CompraRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _comprasCollection = FirebaseFirestore.instance
      .collection(FirestoreCollections.compras);

  // Inicia uma nova compra (cria um documento de compra com status 'Ativa')
  Future<CompraModel> iniciarNovaCompra() async {
    // Busca o ID do status 'Ativa' na coleção comprasStatus
    final ativaStatusDoc = await _firestore
        .collection(FirestoreCollections.comprasStatus)
        .where('compraStatusType', isEqualTo: CompraStatusType.ativa.value)
        .limit(1)
        .get();

    if (ativaStatusDoc.docs.isEmpty) {
      throw Exception(
        'Status "Ativa" não encontrado na coleção de status de compra.',
      );
    }
    final String ativaStatusId = ativaStatusDoc.docs.first.id;

    final novaCompra = CompraModel(
      dataHoraInicio: DateTime.now(),
      compraStatusId: ativaStatusId, // Define o status como 'Ativa'
      valorTotalCalculado: 0.0,
      isActive: true,
      isRemoved: false,
    );
    await _comprasCollection.doc(novaCompra.id).set(novaCompra.toFirestore());
    return novaCompra;
  }

  // Obtém a compra ativa atual (se houver)
  Stream<CompraModel?> getCompraAtiva() {
    return _comprasCollection
        .where(
          'compraStatusId',
          isEqualTo: CompraStatusType.ativa.value.toString(),
        ) // Filtra por ID do status "Ativa"
        .where('isActive', isEqualTo: true)
        .limit(1) // Espera apenas uma compra ativa por vez para o MVP
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            return CompraModel.fromFirestore(snapshot.docs.first);
          }
          return null; // Nenhuma compra ativa encontrada
        });
  }

  // Atualiza uma compra (ex: valor total, data de fim, status)
  Future<void> updateCompra(CompraModel compra) async {
    await _comprasCollection.doc(compra.id).update(compra.toFirestore());
  }

  // Finaliza uma compra (muda o status para 'Finalizada', atualiza data/hora fim)
  Future<void> finalizarCompra(String compraId, double valorFinal) async {
    // Busca o ID do status 'Finalizada'
    final finalizadaStatusDoc = await _firestore
        .collection(FirestoreCollections.comprasStatus)
        .where('compraStatusType', isEqualTo: CompraStatusType.finalizada.value)
        .limit(1)
        .get();

    if (finalizadaStatusDoc.docs.isEmpty) {
      throw Exception(
        'Status "Finalizada" não encontrado na coleção de status de compra.',
      );
    }
    final String finalizadaStatusId = finalizadaStatusDoc.docs.first.id;

    await _comprasCollection.doc(compraId).update({
      'dataHoraFim': FieldValue.serverTimestamp(),
      'valorTotalCalculado': valorFinal,
      'compraStatusId': finalizadaStatusId, // Atualiza para 'Finalizada'
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Cancela uma compra (muda o status para 'Cancelada')
  Future<void> cancelarCompra(String compraId) async {
    // Busca o ID do status 'Cancelada'
    final canceladaStatusDoc = await _firestore
        .collection(FirestoreCollections.comprasStatus)
        .where('compraStatusType', isEqualTo: CompraStatusType.cancelada.value)
        .limit(1)
        .get();

    if (canceladaStatusDoc.docs.isEmpty) {
      throw Exception(
        'Status "Cancelada" não encontrado na coleção de status de compra.',
      );
    }
    final String canceladaStatusId = canceladaStatusDoc.docs.first.id;

    await _comprasCollection.doc(compraId).update({
      'dataHoraFim': FieldValue.serverTimestamp(),
      'compraStatusId': canceladaStatusId, // Atualiza para 'Cancelada'
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // NOVO: Método para obter todas as compras (ativas, finalizadas, canceladas)
  Stream<List<CompraModel>> getAllCompras() {
    // Ordenar pela data de criação ou data de fim (se existir), da mais recente para a mais antiga
    return _comprasCollection
        .orderBy(
          'dataHoraInicio',
          descending: true,
        ) // Ordem primária por data de início
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CompraModel.fromFirestore(doc))
              .toList(),
        );
  }

  // NOVO: Método para obter todas as compras com filtros
  Stream<List<CompraModel>> getFilteredCompras({
    String? statusId,
    DateTime? startDate,
    DateTime? endDate,
    double? minTotal,
    double? maxTotal,
  }) {
    Query query = _comprasCollection;

    // Filtro por status
    if (statusId != null && statusId.isNotEmpty) {
      query = query.where('compraStatusId', isEqualTo: statusId);
    }

    // Filtro por data
    // O Firestore exige um índice composto para consultas de range em múltiplos campos.
    // Para simplificar, focaremos no dataHoraInicio para o filtro principal.
    if (startDate != null) {
      query = query.where('dataHoraInicio', isGreaterThanOrEqualTo: startDate);
    }
    if (endDate != null) {
      // Para incluir o dia inteiro do endDate, adicione 23h59m59s
      final adjustedEndDate = endDate.add(
        const Duration(hours: 23, minutes: 59, seconds: 59),
      );
      query = query.where(
        'dataHoraInicio',
        isLessThanOrEqualTo: adjustedEndDate,
      );
    }

    // Filtro por valor total
    if (minTotal != null) {
      query = query.where(
        'valorTotalCalculado',
        isGreaterThanOrEqualTo: minTotal,
      );
    }
    if (maxTotal != null) {
      query = query.where('valorTotalCalculado', isLessThanOrEqualTo: maxTotal);
    }

    // Ordenação (sempre ordenada, mesmo com filtros)
    query = query.orderBy('dataHoraInicio', descending: true);

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => CompraModel.fromFirestore(doc)).toList(),
    );
  }
}
