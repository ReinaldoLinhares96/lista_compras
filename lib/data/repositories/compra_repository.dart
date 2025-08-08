// ignore_for_file: cast_from_null_always_fails, unnecessary_nullable_for_final_variable_declarations, curly_braces_in_flow_control_structures, unused_import, depend_on_referenced_packages

import 'package:hive_flutter/hive_flutter.dart';
import 'package:lista_compras/presentation/pages/active_shopping_page.dart';
import '../models/compra_model.dart';
import '../../core/enums/compra_status_type.dart'; // Mantenha este enum
import '../models/compra_status_model.dart';
import 'package:rxdart/rxdart.dart';

class CompraRepository {
  late Box<CompraModel> _comprasBox;
  late Box<CompraStatusModel> _compraStatusBox;

  CompraRepository() {
    _comprasBox = Hive.box<CompraModel>('comprasBox');
    _compraStatusBox = Hive.box<CompraStatusModel>('compraStatusBox');
  }

  Future<CompraModel> iniciarNovaCompra() async {
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
    );
    await _comprasBox.put(novaCompra.id, novaCompra);
    return novaCompra;
  }

  Stream<CompraModel?> getCompraAtiva() {
    final CompraStatusModel? ativaStatusModel = _compraStatusBox.get(
      CompraStatusType.ativa.value.toString(),
    );

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
          final CompraStatusModel? currentAtivaStatusModel = _compraStatusBox
              .get(CompraStatusType.ativa.value.toString());

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

  Future<void> updateCompra(CompraModel compra) async {
    await _comprasBox.put(compra.id, compra);
    compra.save();
  }

  Future<void> finalizarCompra(String compraId, double valorFinal) async {
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
  }

  Future<void> cancelarCompra(String compraId, double valorFinal) async {
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
  }

  Stream<List<CompraModel>> getFilteredCompras({
    String? statusId,
    DateTime? startDate,
    DateTime? endDate,
    double? minTotal,
    double? maxTotal,
  }) {
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
          }).toList();

          filteredCompras.sort((a, b) {
            final dateA = a.dataHoraFim ?? a.dataHoraInicio;
            final dateB = b.dataHoraFim ?? b.dataHoraInicio;
            return dateB.compareTo(dateA);
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
            final dateA = a.dataHoraFim ?? a.dataHoraInicio;
            final dateB = b.dataHoraFim ?? b.dataHoraInicio;
            return dateB.compareTo(dateA);
          }),
        );
  }
}
