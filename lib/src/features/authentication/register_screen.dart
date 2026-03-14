import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kawiarnia/src/features/client_panel/client_panel_screen.dart';
import 'package:kawiarnia/src/features/achievements/services/achievements_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      // Krok 1: Utwórz użytkownika w Firebase Authentication
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = credential.user;
      if (user != null) {
        // Krok 2: Zapisz rolę użytkownika w Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'role': 'klient',
          'email': user.email, // Dobra praktyka, by przechowywać też email
        });

        // Krok 3: Zainicjuj statystyki osiągnięć
        final achievementsService = AchievementsService();
        await achievementsService.initializeUserStats(user.uid);

        // Krok 4: Przekieruj do panelu klienta
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const ClientPanelScreen()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'weak-password') {
        message = 'Podane hasło jest zbyt słabe.';
      } else if (e.code == 'email-already-in-use') {
        message = 'Konto dla tego adresu e-mail już istnieje.';
      } else {
        message = 'Wystąpił błąd rejestracji. Spróbuj ponownie.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rejestracja'),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.background,
              theme.colorScheme.secondary.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shadowColor: theme.colorScheme.primary.withOpacity(0.2),
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.person_add_outlined,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Utwórz konto',
                        style: theme.textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Dołącz do naszej kawiarni',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Adres e-mail',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Hasło',
                          prefixIcon: Icon(Icons.lock_outline),
                          helperText: 'Minimum 6 znaków',
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 32),
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 54),
                          ),
                          child: const Text(
                            'ZAREJESTRUJ SIĘ',
                            style: TextStyle(fontSize: 16, letterSpacing: 1.2),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
