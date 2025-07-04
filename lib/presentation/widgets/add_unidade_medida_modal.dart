// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:lista_compras/data/models/unidade_medida_model.dart';
import 'package:lista_compras/data/repositories/unidade_medida_repository.dart';

class AddUnidadeMedidaModal extends StatefulWidget {
  const AddUnidadeMedidaModal({super.key});

  @override
  State<AddUnidadeMedidaModal> createState() => _AddUnidadeMedidaModalState();
}

class _AddUnidadeMedidaModalState extends State<AddUnidadeMedidaModal> {
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _simboloController =
      TextEditingController(); // NOVO CONTROLADOR

  final UnidadeMedidaRepository _repository = UnidadeMedidaRepository();

  @override
  void dispose() {
    _descricaoController.dispose();
    _simboloController.dispose(); // DISPOSE DO NOVO CONTROLADOR
    super.dispose();
  }

  Future<void> _addUnidadeMedida() async {
    if (_descricaoController.text.isEmpty || _simboloController.text.isEmpty) {
      // VALIDAÇÃO ATUALIZADA
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha a descrição e o símbolo.'),
        ),
      );
      return;
    }

    try {
      // Validação de duplicidade por descrição e símbolo (case-insensitive)
      final existingUnit = await _repository.getUnidadeByDescricaoAndSimbolo(
        _descricaoController.text.toLowerCase(),
        _simboloController.text.toLowerCase(),
      );

      if (existingUnit != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Já existe uma unidade de medida com essa descrição e símbolo.',
            ),
          ),
        );
        return;
      }

      final newUnidade = UnidadeMedidaModel(
        descricao: _descricaoController.text,
        simbolo: _simboloController.text
            .toLowerCase(), // Salvar símbolo em minúsculas
      );

      // Não precisamos mais chamar initializeDefaultUnidadesMedida, pois as unidades serão criadas pelo usuário
      await _repository.addUnidade(newUnidade);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unidade de medida "${newUnidade.descricao} (${newUnidade.simbolo})" adicionada!',
            ),
          ),
        );
        Navigator.pop(context); // Fecha o modal
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao adicionar unidade: $e')),
        );
      }
    }
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
          children: [
            Text(
              'Adicionar Nova Unidade de Medida',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _descricaoController,
              decoration: const InputDecoration(
                labelText: 'Descrição da Unidade (ex: "Quilograma")',
                hintText: 'Ex: Pacote, Metro',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _simboloController,
              decoration: const InputDecoration(
                labelText: 'Símbolo da Unidade (ex: "kg")',
                hintText: 'Ex: un, L, g',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addUnidadeMedida,
              child: const Text('Salvar Unidade de Medida'),
            ),
          ],
        ),
      ),
    );
  }
}
