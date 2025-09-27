import 'package:app_rutas_repartidor/Pages/mapa_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://bzddyggdbcbntxxvecwd.supabase.co', 
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ6ZGR5Z2dkYmNibnR4eHZlY3dkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg5MzUzNzIsImV4cCI6MjA3NDUxMTM3Mn0.ES8km1jicjTQAm6tzxXDWZecsn70_21o50JiQ74Sexg',                
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rutas Repartidor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const MapaPage(), 
    );
  }
}
