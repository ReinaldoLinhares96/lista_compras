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
}
