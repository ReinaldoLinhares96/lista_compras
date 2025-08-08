// ignore_for_file: depend_on_referenced_packages, unnecessary_to_list_in_spreads

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lista_compras/data/models/compra_status_model.dart';
import 'package:lista_compras/data/repositories/compra_status_repository.dart';

// Definição do modelo de dados para os filtros (para retornar do modal)
class PurchaseFilterData {
  final String? statusId;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minTotal;
  final double? maxTotal;

  PurchaseFilterData({
    this.statusId,
    this.startDate,
    this.endDate,
    this.minTotal,
    this.maxTotal,
  });
}

class PurchaseHistoryFilterModal extends StatefulWidget {
  final PurchaseFilterData? initialFilters;

  const PurchaseHistoryFilterModal({super.key, this.initialFilters});

  @override
  State<PurchaseHistoryFilterModal> createState() =>
      _PurchaseHistoryFilterModalState();
}

class _PurchaseHistoryFilterModalState
    extends State<PurchaseHistoryFilterModal> {
  final CompraStatusRepository _compraStatusRepository =
      CompraStatusRepository();
  String? _selectedStatusId;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  final TextEditingController _minTotalController = TextEditingController();
  final TextEditingController _maxTotalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialFilters != null) {
      _selectedStatusId = widget.initialFilters!.statusId;
      _selectedStartDate = widget.initialFilters!.startDate;
      _selectedEndDate = widget.initialFilters!.endDate;
      if (widget.initialFilters!.minTotal != null) {
        _minTotalController.text = widget.initialFilters!.minTotal!
            .toStringAsFixed(2)
            .replaceAll('.', ',');
      }
      if (widget.initialFilters!.maxTotal != null) {
        _maxTotalController.text = widget.initialFilters!.maxTotal!
            .toStringAsFixed(2)
            .replaceAll('.', ',');
      }
    }
  }

  @override
  void dispose() {
    _minTotalController.dispose();
    _maxTotalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 60,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtrar Histórico de Compras',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),

            StreamBuilder<List<CompraStatusModel>>(
              stream: _compraStatusRepository.getCompraStatus(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                final statuses = snapshot.data!;
                return DropdownButtonFormField<String>(
                  value: _selectedStatusId,
                  hint: const Text('Filtrar por Status'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Todos os Status'),
                    ),
                    ...statuses
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.descricao),
                          ),
                        )
                        .toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatusId = value;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 20),

            Text(
              'Filtrar por Data:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: Text(
                      _selectedStartDate == null
                          ? 'Data Inicial'
                          : DateFormat(
                              'dd/MM/yyyy',
                            ).format(_selectedStartDate!),
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _selectedStartDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _selectedStartDate = pickedDate;
                        });
                      }
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: Text(
                      _selectedEndDate == null
                          ? 'Data Final'
                          : DateFormat('dd/MM/yyyy').format(_selectedEndDate!),
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _selectedEndDate ?? DateTime.now(),
                        firstDate: _selectedStartDate ?? DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _selectedEndDate = pickedDate;
                        });
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _selectedStartDate = null;
                      _selectedEndDate = null;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            Text(
              'Filtrar por Valor Total (R\$):',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minTotalController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Mínimo'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _maxTotalController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Máximo'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _minTotalController.clear();
                    _maxTotalController.clear();
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, null);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  child: const Text('Limpar Filtros'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final double? min = double.tryParse(
                      _minTotalController.text.replaceAll(',', '.'),
                    );
                    final double? max = double.tryParse(
                      _maxTotalController.text.replaceAll(',', '.'),
                    );

                    if ((_selectedStartDate != null &&
                            _selectedEndDate != null) &&
                        _selectedStartDate!.isAfter(_selectedEndDate!)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Data inicial não pode ser depois da data final.',
                          ),
                        ),
                      );
                      return;
                    }
                    if (min != null && max != null && min > max) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Valor mínimo não pode ser maior que o valor máximo.',
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(
                      context,
                      PurchaseFilterData(
                        statusId: _selectedStatusId,
                        startDate: _selectedStartDate,
                        endDate: _selectedEndDate,
                        minTotal: min,
                        maxTotal: max,
                      ),
                    );
                  },
                  child: const Text('Aplicar Filtros'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
