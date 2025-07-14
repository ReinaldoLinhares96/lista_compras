import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Importar GoogleSignIn

import 'package:lista_compras/presentation/pages/product_list_page.dart'; // Seu app principal
import 'package:lista_compras/presentation/pages/create_account_screen.dart'; // Tela de Criação de Conta
import 'package:lista_compras/presentation/pages/premium_purchase_page.dart'; // Tela de Compra Premium

// ignore_for_file: unused_element, prefer_final_fields, use_build_context_synchronously, avoid_print, unnecessary_brace_in_string_interps

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // AQUI: Alterado para GoogleSignIn()
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool _isLoading = false; // Para controlar o estado de carregamento

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Métodos de Autenticação (movidos da AuthScreen)
  Future<void> _signInWithEmailAndPassword() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      // Se o login for bem-sucedido, o StreamBuilder no build
      // irá detectar a mudança e redirecionar para ProductListPage.
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found') {
        message = 'Nenhum usuário encontrado para este e-mail.';
      } else if (e.code == 'wrong-password') {
        message = 'Senha incorreta.';
      } else {
        message = 'Erro de login: ${e.message}';
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro inesperado: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // Usuário cancelou o login
        return;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Uma conta já existe com este e-mail usando outro método de login.',
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao fazer login com Google: ${e.message}'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro inesperado: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usar StreamBuilder para ouvir o estado de autenticação do Firebase
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(), // Monitora o estado de autenticação
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
          // Usuário está logado, redireciona para o app principal
          return const ProductListPage();
        } else {
          // Usuário NÃO está logado, exibe a tela de login/escolha
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'Bem-vindo ao Lista de Compras',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              backgroundColor: Colors.blue.shade100,
            ),
            body: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  ) // Indicador de carregamento quando autenticando
                : Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Imagem do Ícone do App
                          Image.asset(
                            'lib/presentation/assets/app_icon.png',
                            height: 120, // Tamanho ajustado
                            width: 120, // Tamanho ajustado
                          ),
                          const SizedBox(height: 20),
                          // Breve Descrição do App
                          const Text(
                            'Organize sua lista, controle seu orçamento e o total do carrinho em tempo real no supermercado, e nunca mais esqueça um item.',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 40),
                          // Campos de Login
                          TextField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'E-mail',
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: _passwordController,
                            decoration: const InputDecoration(
                              labelText: 'Senha',
                            ),
                            obscureText: true,
                          ),
                          const SizedBox(height: 20),
                          // Botão Entrar
                          ElevatedButton(
                            onPressed: _signInWithEmailAndPassword,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: const Text(
                              'Entrar',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Botão Entrar com Google
                          OutlinedButton(
                            onPressed: _signInWithGoogle,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: const Text(
                              'Entrar com Google',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Botão Criar Conta
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CreateAccountScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Não tem uma conta? Crie uma aqui.',
                            ),
                          ),
                          const SizedBox(height: 30),
                          const Divider(), // Separador visual
                          const SizedBox(height: 20),
                          // Botão Ser Premium
                          ElevatedButton(
                            onPressed: () {
                              // Navega para a tela de pagamento premium
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PremiumPurchasePage(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 60),
                              backgroundColor: Colors
                                  .deepPurple, // Cor de destaque para Premium
                              foregroundColor: Colors.white,
                            ),
                            child: const Text(
                              '✨ Ser Premium Agora! ✨',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Salve seus dados na nuvem, visualize histórico completo e use sem anúncios!',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.deepPurple,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
          );
        }
      },
    );
  }
}
