// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:lista_compras/data/models/unidade_medida_model.dart';
import 'package:lista_compras/data/repositories/unidade_medida_repository.dart';

class EditUnidadeMedidaModal extends StatefulWidget {
  final UnidadeMedidaModel unidade;

  const EditUnidadeMedidaModal({super.key, required this.unidade});

  @override
  State<EditUnidadeMedidaModal> createState() => _EditUnidadeMedidaModalState();
}

class _EditUnidadeMedidaModalState extends State<EditUnidadeMedidaModal> {
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _simboloController = TextEditingController();

  final UnidadeMedidaRepository _repository = UnidadeMedidaRepository();

  @override
  void initState() {
    super.initState();
    _descricaoController.text = widget.unidade.descricao;
    _simboloController.text = widget.unidade.simbolo;
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _simboloController.dispose();
    super.dispose();
  }

  Future<void> _updateUnidadeMedida() async {
    if (_descricaoController.text.isEmpty || _simboloController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha a descrição e o símbolo.'),
        ),
      );
      return;
    }

    try {
      // Validação de duplicidade (exceto para o próprio item que está sendo editado)
      final existingUnit = await _repository.getUnidadeByDescricaoAndSimbolo(
        _descricaoController.text.toLowerCase(),
        _simboloController.text.toLowerCase(),
      );

      if (existingUnit != null && existingUnit.id != widget.unidade.id) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Já existe outra unidade de medida com essa descrição e símbolo.',
            ),
          ),
        );
        return;
      }

      final updatedUnidade = UnidadeMedidaModel(
        id: widget.unidade.id, // Mantém o ID original
        descricao: _descricaoController.text,
        simbolo: _simboloController.text.toLowerCase(),
      );

      await _repository.updateUnidade(updatedUnidade);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unidade de medida "${updatedUnidade.descricao} (${updatedUnidade.simbolo})" atualizada!',
            ),
          ),
        );
        Navigator.pop(context); // Fecha o modal
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar unidade: $e')),
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
              'Editar Unidade de Medida',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _descricaoController,
              decoration: const InputDecoration(
                labelText: 'Descrição da Unidade',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _simboloController,
              decoration: const InputDecoration(
                labelText: 'Símbolo da Unidade',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateUnidadeMedida,
              child: const Text('Salvar Alterações'),
            ),
          ],
        ),
      ),
    );
  }
}
