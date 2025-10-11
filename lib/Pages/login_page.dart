import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'mapa_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool cargando = false;
  String? errorMsg;

  Future<void> _login() async {
    setState(() => cargando = true);
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (response.session != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MapaPage()),
        );
      } else {
        setState(() => errorMsg = 'Credenciales incorrectas');
      }
    } catch (e) {
      setState(() => errorMsg = 'Error: $e');
    } finally {
      setState(() => cargando = false);
    }
  }

  Future<void> _registrar() async {
    setState(() => cargando = true);
    try {
      await Supabase.instance.client.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      setState(() => errorMsg =
          'Cuenta creada. Revisa tu correo para confirmar tu cuenta.');
    } catch (e) {
      setState(() => errorMsg = 'Error: $e');
    } finally {
      setState(() => cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Iniciar Sesión',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Correo'),
                  ),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'Contraseña'),
                  ),
                  const SizedBox(height: 20),
                  if (errorMsg != null)
                    Text(errorMsg!,
                        style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: cargando ? null : _login,
                    child: cargando
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Entrar'),
                  ),
                  const SizedBox(height: 18),
                  /*TextButton(
                    onPressed: cargando ? null : _registrar,
                    child: const Text('Crear cuenta'),
                  ), */
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
