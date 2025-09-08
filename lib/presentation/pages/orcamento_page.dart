// ignore_for_file: unused_field

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lista_compras/data/repositories/premium_status_repository.dart';
import 'package:lista_compras/main.dart';
import 'package:lista_compras/services/ad_manager.dart';
import '../../data/models/orcamento_model.dart';
import '../../data/repositories/orcamento_repository.dart';

class OrcamentoPage extends StatefulWidget {
  const OrcamentoPage({super.key});

  @override
  State<OrcamentoPage> createState() => _OrcamentoPageState();
}

class _OrcamentoPageState extends State<OrcamentoPage> {
  final OrcamentoRepository _orcamentoRepository = OrcamentoRepository();
  final TextEditingController _orcamentoController = TextEditingController();
  final PremiumStatusRepository _premiumStatusRepository =
      premiumStatusRepository;
  late StreamSubscription<bool> _premiumStatusSubscription;
  bool _isPremium = false;

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
    _orcamentoRepository.getOrcamento().listen((orcamento) {
      if (_orcamentoController.text !=
          orcamento.valorMaximo.toStringAsFixed(2).replaceAll('.', ',')) {
        _orcamentoController.text = orcamento.valorMaximo
            .toStringAsFixed(2)
            .replaceAll('.', ',');
      }
    });
  }

  @override
  void dispose() {
    _orcamentoController.dispose();
    super.dispose();
  }

  void _salvarOrcamento() async {
    final String inputText = _orcamentoController.text;
    final double? novoValor = double.tryParse(inputText.replaceAll(',', '.'));

    if (novoValor == null || novoValor < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, insira um valor válido para o orçamento.'),
        ),
      );
      AdManager.maybeShowInterstitialAd(_isPremium);
      return;
    }

    try {
      await _orcamentoRepository.updateOrcamento(novoValor);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Orçamento atualizado com sucesso!')),
        );
        AdManager.showInterstitialAd(_isPremium);
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao salvar orçamento: $e')));
        AdManager.maybeShowInterstitialAd(_isPremium);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 20.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: StreamBuilder<OrcamentoModel>(
                  stream: _orcamentoRepository.getOrcamento(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Erro ao carregar orçamento: ${snapshot.error}',
                        ),
                      );
                    }

                    final OrcamentoModel orcamento = snapshot.data!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Seu Orçamento Atual',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'R\$ ${orcamento.valorMaximo.toStringAsFixed(2).replaceAll('.', ',')}',
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            Text(
              'Definir Novo Orçamento',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _orcamentoController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Valor (R\$)',
                hintText: 'Ex: 500,00',
                prefixText: 'R\$ ',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _salvarOrcamento,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: const Text(
                  'Salvar Orçamento',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
