// ignore_for_file: use_build_context_synchronously, unused_field

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lista_compras/data/models/categoria_model.dart';
import 'package:lista_compras/data/repositories/categoria_repository.dart';
import 'package:lista_compras/data/repositories/premium_status_repository.dart';
import 'package:lista_compras/main.dart';
import 'package:lista_compras/services/ad_manager.dart';

class EditCategoriaModal extends StatefulWidget {
  final CategoriaModel categoria;

  const EditCategoriaModal({super.key, required this.categoria});

  @override
  State<EditCategoriaModal> createState() => _EditCategoriaModalState();
}

class _EditCategoriaModalState extends State<EditCategoriaModal> {
  final TextEditingController _descricaoController = TextEditingController();
  final PremiumStatusRepository _premiumStatusRepository =
      premiumStatusRepository;
  final CategoriaRepository _repository = CategoriaRepository();

  bool _isPremium = false;

  late StreamSubscription<bool> _premiumStatusSubscription;

  @override
  void initState() {
    super.initState();

    _premiumStatusSubscription = _premiumStatusRepository.isPremiumStream
        .listen((isPremium) {
          setState(() {
            _isPremium = isPremium;
          });
        });

    AdManager.loadInterstitialAd();
    _descricaoController.text = widget.categoria.descricao;
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _updateCategoria() async {
    if (_descricaoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha a descrição.')),
      );
      AdManager.maybeShowInterstitialAd(_isPremium);
      return;
    }

    try {
      final existingCategory = await _repository.getCategoriaByDescricao(
        _descricaoController.text.toLowerCase(),
      );

      if (existingCategory != null &&
          existingCategory.id != widget.categoria.id) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Já existe outra categoria com essa descrição.'),
          ),
        );
        return;
      }

      final updatedCategoria = CategoriaModel(
        id: widget.categoria.id,
        descricao: _descricaoController.text,
      );

      await _repository.updateCategoria(updatedCategoria);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Categoria "${updatedCategoria.descricao}" atualizada!',
            ),
          ),
        );
        AdManager.showInterstitialAd(_isPremium);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar categoria: $e')),
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
              'Editar Categoria',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _descricaoController,
              decoration: const InputDecoration(
                labelText: 'Descrição da Categoria',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateCategoria,
              child: const Text('Salvar Alterações'),
            ),
          ],
        ),
      ),
    );
  }
}
