import 'package:flutter/material.dart';
import '../../data/models/orcamento_model.dart';
import '../../data/repositories/orcamento_repository.dart';
// Remova qualquer import do Firestore, se estiver aqui (ex: import 'package:cloud_firestore/cloud_firestore.dart';)

class OrcamentoPage extends StatefulWidget {
  const OrcamentoPage({super.key});

  @override
  State<OrcamentoPage> createState() => _OrcamentoPageState();
}

class _OrcamentoPageState extends State<OrcamentoPage> {
  final OrcamentoRepository _orcamentoRepository = OrcamentoRepository();
  final TextEditingController _orcamentoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Escuta as mudanças no orçamento para manter o campo atualizado
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
      return;
    }

    try {
      await _orcamentoRepository.updateOrcamento(novoValor);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Orçamento atualizado com sucesso!')),
        );
        FocusScope.of(context).unfocus(); // Fecha o teclado
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao salvar orçamento: $e')));
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
                  // O OrcamentoRepository já retorna OrcamentoModel no Stream.
                  // Certifique-se de que o orcamentoDocId existe no OrcamentoRepository
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

                    // Se a stream pode retornar nulo (ex: orElse no repositório), lide com isso.
                    // O OrcamentoRepository foi ajustado para retornar OrcamentoModel(id: ..., valorMaximo: 0.0)
                    // se não encontrar o orçamento, então snapshot.data não deve ser nulo aqui.
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
