import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kawiarnia/src/features/home/role_gate.dart';

enum AuthMode { Login, Signup }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  var _authMode = AuthMode.Login;
  var _isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      if (_authMode == AuthMode.Login) {
        await _auth.signInWithEmailAndPassword(email: _emailController.text, password: _passwordController.text);
      } else {
        final userCredential = await _auth.createUserWithEmailAndPassword(email: _emailController.text, password: _passwordController.text);
        if (userCredential.user != null) {
          await _createUserDocument(userCredential.user!);
        }
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const RoleGate()));
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? 'Wystąpił błąd')),
        );
      }
    } finally {
      if(mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createUserDocument(User user) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    await userRef.set({
      'email': user.email,
      'role': 'klient',
      'points': 0,
      'vouchers': 0,
      'subscriptions': {},
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  void _switchAuthMode() {
    setState(() {
      _authMode = _authMode == AuthMode.Login ? AuthMode.Signup : AuthMode.Login;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
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
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo i branding kawiarni
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.local_cafe_rounded,
                      size: 80,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Kawiarnia',
                    style: theme.textTheme.displayMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Twoje miejsce pełne aromatu',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onBackground.withOpacity(0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Formularz w karcie
                  Card(
                    elevation: 8,
                    shadowColor: theme.colorScheme.primary.withOpacity(0.2),
                    child: Padding(
                      padding: const EdgeInsets.all(28.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _authMode == AuthMode.Login ? 'Witaj ponownie!' : 'Dołącz do nas',
                              style: theme.textTheme.headlineSmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _authMode == AuthMode.Login 
                                ? 'Zaloguj się do swojego konta'
                                : 'Stwórz nowe konto',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Adres e-mail',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) => (value == null || !value.contains('@')) 
                                ? 'Podaj poprawny adres e-mail' 
                                : null,
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _passwordController,
                              decoration: const InputDecoration(
                                labelText: 'Hasło',
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                              obscureText: true,
                              validator: (value) => (value == null || value.length < 6) 
                                ? 'Hasło musi mieć minimum 6 znaków' 
                                : null,
                            ),
                            const SizedBox(height: 32),
                            if (_isLoading)
                              const Center(child: CircularProgressIndicator())
                            else
                              ElevatedButton(
                                onPressed: _submit,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 54),
                                ),
                                child: Text(
                                  _authMode == AuthMode.Login ? 'ZALOGUJ SIĘ' : 'ZAREJESTRUJ SIĘ',
                                  style: const TextStyle(fontSize: 16, letterSpacing: 1.2),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: _switchAuthMode,
                    child: Text(
                      _authMode == AuthMode.Login 
                        ? 'Nie masz konta? Zarejestruj się' 
                        : 'Masz już konto? Zaloguj się',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
