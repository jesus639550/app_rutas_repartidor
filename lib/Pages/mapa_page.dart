import 'dart:convert';
import 'dart:math' show min, max;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class MapaPage extends StatefulWidget {
  const MapaPage({Key? key}) : super(key: key);

  @override
  State<MapaPage> createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage> {
  GoogleMapController? _mapController;

  LatLng? _origen; // ubicación actual
  LatLng? _destino; // elegido de Supabase

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  static const String _apiKey = "TU_API_KEY_AQUI"; // 👈 Google Maps API Key

  @override
  void initState() {
    super.initState();
    _cargarUbicacionActual();
    _cargarDestinosSupabase();
  }

  // Obtener ubicación actual
  Future<void> _cargarUbicacionActual() async {
    final pos = await Geolocator.getCurrentPosition();
    setState(() {
      _origen = LatLng(pos.latitude, pos.longitude);
      _markers.add(Marker(
        markerId: const MarkerId('origen'),
        position: _origen!,
        infoWindow: const InfoWindow(title: "Mi ubicación"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ));
    });
  }

  // Traer destinos desde Supabase
  Future<void> _cargarDestinosSupabase() async {
    final response = await Supabase.instance.client.from('destinos').select();
    for (var d in response) {
      final destino = LatLng(d['lat'], d['lng']);
      _markers.add(
        Marker(
          markerId: MarkerId(d['id'].toString()),
          position: destino,
          infoWindow: InfoWindow(title: d['nombre'], snippet: d['direccion']),
          onTap: () {
            setState(() {
              _destino = destino;
            });
            if (_origen != null) {
              _trazarRuta(_origen!, _destino!);
            }
          },
        ),
      );
    }
    setState(() {});
  }

  // Pedir ruta a Directions API
  Future<void> _trazarRuta(LatLng origen, LatLng destino) async {
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origen.latitude},${origen.longitude}&destination=${destino.latitude},${destino.longitude}&key=$_apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['routes'].isNotEmpty) {
        final points = data['routes'][0]['overview_polyline']['points'];
        final polylinePoints = PolylinePoints().decodePolyline(points);

        final ruta = polylinePoints
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList();

        setState(() {
          _polylines.clear();
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('ruta'),
              color: Colors.blue,
              width: 5,
              points: ruta,
            ),
          );
        });

        _fitBounds([origen, destino]);
      }
    }
  }

  // Ajustar cámara para ver inicio y destino
  Future<void> _fitBounds(List<LatLng> pts) async {
    if (_mapController == null || pts.isEmpty) return;
    double? minLat, maxLat, minLng, maxLng;
    for (final p in pts) {
      minLat = (minLat == null) ? p.latitude : min(minLat!, p.latitude);
      maxLat = (maxLat == null) ? p.latitude : max(maxLat!, p.latitude);
      minLng = (minLng == null) ? p.longitude : min(minLng!, p.longitude);
      maxLng = (maxLng == null) ? p.longitude : max(maxLng!, p.longitude);
    }
    final bounds = LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
    await _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa • Destinos Supabase')),
      body: GoogleMap(
        onMapCreated: (c) => _mapController = c,
        initialCameraPosition: const CameraPosition(target: LatLng(19.4326, -99.1332), zoom: 12),
        markers: _markers,
        polylines: _polylines,
        myLocationButtonEnabled: true,
        myLocationEnabled: false,
      ),
    );
  }
}
