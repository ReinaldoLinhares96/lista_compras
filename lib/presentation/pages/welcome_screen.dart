// lib/presentation/pages/welcome_screen.dart (APENAS AS ALTERAÇÕES RELEVANTES)

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lista_compras/data/repositories/user_repository.dart';

import 'package:lista_compras/presentation/pages/product_list_page.dart';
import 'package:lista_compras/presentation/pages/create_account_screen.dart';
import 'package:lista_compras/presentation/pages/premium_purchase_page.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  late final UserRepository _userRepository;

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Método auxiliar para criar/atualizar perfil após login
  Future<void> _handleSuccessfulLogin(User user) async {
    await _userRepository.createUserProfile(
      userId: user.uid,
      email: user.email!,
      displayName: user.displayName,
      // isPremium será false por padrão, a menos que seja atualizado pela compra
    );
    // O StreamBuilder no build já vai redirecionar para ProductListPage
  }

  Future<void> _signInWithEmailAndPassword() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(
            email: _emailController.text,
            password: _passwordController.text,
          );
      if (userCredential.user != null) {
        await _handleSuccessfulLogin(userCredential.user!);
      }
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
        return; // Usuário cancelou o login
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      if (userCredential.user != null) {
        await _handleSuccessfulLogin(userCredential.user!);
      }
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
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return const ProductListPage();
        } else {
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
                ? const Center(child: CircularProgressIndicator())
                : Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'lib/presentation/assets/logo.png',
                            height: 120,
                            width: 120,
                          ),
                          const SizedBox(height: 20),
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
                          const Divider(),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
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
                              backgroundColor: Colors.deepPurple,
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
