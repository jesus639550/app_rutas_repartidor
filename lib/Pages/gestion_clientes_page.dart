import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class GestionClientesPage extends StatelessWidget {
  final int destinoId;
  final String nombreFarmacia;

  const GestionClientesPage({
    Key? key,
    required this.destinoId,
    required this.nombreFarmacia,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Clientes de $nombreFarmacia')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: Supabase.instance.client
            .from('clientes')
            .select()
            .eq('id_destino_fk', destinoId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final clientes = snapshot.data ?? [];

          return ListView.builder(
            itemCount: clientes.length,
            itemBuilder: (context, index) {
              final cliente = clientes[index];
             return Card(
  child: ListTile(
    title: Text(cliente['nombre']),
    subtitle: Text(cliente['telefono'] ?? 'Sin teléfono'),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.phone, color: Colors.green),
          tooltip: 'Llamar',
          onPressed: () {
            final telefono = cliente['telefono'];
            if (telefono != null && telefono.isNotEmpty) {
              launchUrl(Uri.parse('tel:$telefono'));
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.message, color: Colors.teal),
          tooltip: 'WhatsApp',
          onPressed: () {
            final telefono = cliente['telefono'];
            if (telefono != null && telefono.isNotEmpty) {
              final url = Uri.parse('https://wa.me/$telefono');
              launchUrl(url, mode: LaunchMode.externalApplication);
            }
          },
        ),
      ],
    ),
  ),
);

            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Puedes abrir un formulario para agregar cliente nuevo
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
