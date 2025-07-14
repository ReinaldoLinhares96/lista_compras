import 'package:flutter/material.dart';

class PremiumPurchasePage extends StatefulWidget {
  const PremiumPurchasePage({super.key});

  @override
  State<PremiumPurchasePage> createState() => _PremiumPurchasePageState();
}

class _PremiumPurchasePageState extends State<PremiumPurchasePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seja Premium!'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple.shade100, // Cor para diferenciar
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Desbloqueie recursos premium!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Text(
                'Aqui você poderá comprar a versão Premium do aplicativo.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              // Futuramente, botões de compra (assinaturas, etc.)
              CircularProgressIndicator(), // Placeholder de carregamento
              Text('Carregando opções de compra...'),
            ],
          ),
        ),
      ),
    );
  }
}
