import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_rutas_repartidor/Pages/mapa_page.dart';
import 'package:app_rutas_repartidor/Pages/login_page.dart'; // 👈 la agregaremos

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://bzddyggdbcbntxxvecwd.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ6ZGR5Z2dkYmNibnR4eHZlY3dkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg5MzUzNzIsImV4cCI6MjA3NDUxMTM3Mn0.ES8km1jicjTQAm6tzxXDWZecsn70_21o50JiQ74Sexg',
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final SupabaseClient supabase;

  @override
  void initState() {
    super.initState();
    supabase = Supabase.instance.client;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rutas Repartidor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: StreamBuilder<AuthState>(
        stream: supabase.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final session = supabase.auth.currentSession;

          // Si no hay sesión → mostrar login
          if (session == null) {
            return const LoginPage();
          }
          // Si hay sesión → mostrar mapa
          return const MapaPage();
        },
      ),
    );
  }
}
