// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lista_compras/presentation/pages/product_list_page.dart'; // Seu app principal
import 'package:lista_compras/presentation/pages/auth_screen.dart'; // Criaremos esta tela

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    // Usar StreamBuilder para ouvir o estado de autenticação do Firebase
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child:
                  CircularProgressIndicator(), // Mostra carregamento enquanto verifica o login
            ),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          // Usuário está logado (pode ser anônimo, ou com conta)
          // Aqui você pode decidir se vai para a ProductListPage (seu app principal)
          // ou para uma tela intermediária se precisar verificar o status Premium
          return const ProductListPage(); // Direciona para o app principal
        } else {
          // Usuário não está logado
          // Oferece a escolha entre Gratuito e Pago/Login
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'Bem-vindo!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              backgroundColor: Colors.blue.shade100,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Como você gostaria de usar o aplicativo?',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      // Login anônimo para usuários "gratuitos"
                      _signInAnonymously(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Continuar Gratuitamente',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: () {
                      // Leva para a tela de Login/Criação de Conta para usuários "pagos"
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AuthScreen(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: const BorderSide(color: Colors.blue),
                    ),
                    child: const Text(
                      'Acessar Minha Conta / Premium',
                      style: TextStyle(fontSize: 18, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Future<void> _signInAnonymously(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signInAnonymously();
      // Se o login anônimo for bem-sucedido, o StreamBuilder no build
      // irá detectar a mudança e redirecionar para ProductListPage.
    } on FirebaseAuthException catch (e) {
      if (e.code == 'operation-not-allowed') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login anônimo não habilitado no Firebase.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao entrar anonimamente: ${e.message}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro inesperado: $e')));
    }
  }
}
