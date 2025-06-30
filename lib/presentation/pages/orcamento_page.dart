import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    // Escuta as mudanças no orçamento para manter o campo atualizado
    _orcamentoRepository.getOrcamento().listen((orcamento) {
      if (_orcamentoController.text !=
          orcamento.valorMaximo.toStringAsFixed(2)) {
        _orcamentoController.text = orcamento.valorMaximo.toStringAsFixed(2);
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
    final double? novoValor = double.tryParse(
      inputText.replaceAll(',', '.'),
    ); // Lida com vírgula como separador decimal

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
      appBar: AppBar(title: const Text('Definir Orçamento Mensal')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<OrcamentoModel>(
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

                final OrcamentoModel orcamento =
                    snapshot.data ??
                    OrcamentoModel(
                      id: OrcamentoRepository.orcamentoDocId,
                      valorMaximo: 0.0,
                    );

                return Text(
                  'Seu Orçamento Atual: R\$ ${orcamento.valorMaximo.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: Theme.of(context).textTheme.headlineSmall,
                );
              },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _orcamentoController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Novo Valor do Orçamento',
                hintText: 'Ex: 500,00',
                prefixText: 'R\$ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _salvarOrcamento,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
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
