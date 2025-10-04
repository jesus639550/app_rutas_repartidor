  import 'dart:convert';
  import 'dart:math' show min, max;
  import 'package:flutter/material.dart';
  import 'package:google_maps_flutter/google_maps_flutter.dart';
  import 'package:supabase_flutter/supabase_flutter.dart';
  import 'package:geolocator/geolocator.dart';
  import 'package:http/http.dart' as http;
  import 'package:flutter_polyline_points/flutter_polyline_points.dart';
  import 'package:url_launcher/url_launcher.dart';

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

    static const String _apiKey = "AIzaSyBrA0ucm9qkGVPAL3ulTnu-ZD_Y8XeXUaY"; 
  String? _duracionEstimado; // texto del tiempo

  @override
  void initState() {
    super.initState();
    _cargarUbicacionActual().then((_) {
      _cargarDestinosSupabase();
    });
  }

    //Carcar ubicacion actual Movil
  Future<void> _cargarUbicacionActual() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Permiso de ubicación denegado');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Permiso de ubicación denegado permanentemente');
      return;
    }

    final pos = await Geolocator.getCurrentPosition();

    setState(() {
      _origen = LatLng(pos.latitude, pos.longitude);
      _markers.add(
        Marker(
          markerId: const MarkerId('origen'),
          position: _origen!,
          infoWindow: const InfoWindow(title: "Mi ubicación"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    });

    // 👇 mover cámara al centro de tu ubicación actual
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_origen!, 16), 
      );
    }

    print('Ubicación actual: ${pos.latitude}, ${pos.longitude}');
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

  Future<void> _trazarRuta(LatLng origen, LatLng destino) async {
    final url = Uri.parse('https://routes.googleapis.com/directions/v2:computeRoutes');

    final headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': _apiKey,
      'X-Goog-FieldMask': 'routes.polyline.encodedPolyline,routes.duration',
    };

    final body = jsonEncode({
      "origin": {
        "location": {
          "latLng": {
            "latitude": origen.latitude,
            "longitude": origen.longitude
          }
        }
      },
      "destination": {
        "location": {
          "latLng": {
            "latitude": destino.latitude,
            "longitude": destino.longitude
          }
        }
      },
      "travelMode": "DRIVE",
      "routingPreference": "TRAFFIC_AWARE"
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final routes = data['routes'];

      if (routes != null && routes.isNotEmpty) {
        final encoded = routes[0]['polyline']['encodedPolyline'];
        final duration = routes[0]['duration']; // Ej: "480s"

        // Convertimos duración a minutos
        int duracionSegundos = int.parse(duration.replaceAll('s', ''));
        int minutos = (duracionSegundos / 60).round();

        // Sumarle 15 minutos de margen
        minutos += 15;

        _duracionEstimado = '$minutos minutos';

        final decodedPoints = PolylinePoints().decodePolyline(encoded);
        final routeCoords = decodedPoints
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

        setState(() {
          _duracionEstimado = '$minutos min'; 
          _polylines.clear();
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('ruta'),
              color: Colors.red,
              width: 5,
              points: routeCoords,
            ),
          );
        });

        _fitBounds([origen, destino]);
      } else {
        print('No se encontraron rutas.');
      }
    } else {
      print('Error al obtener la ruta: ${response.body}');
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
        appBar: AppBar(title: const Text('Mi Map')),
        body: Stack(
    children: [
      GoogleMap(
        onMapCreated: (c) => _mapController = c,
        initialCameraPosition: CameraPosition(
          target: _origen ?? const LatLng(19.4326, -99.1332),
          zoom: 14,
        ),
        markers: _markers,
        polylines: _polylines,
        myLocationButtonEnabled: true,
        myLocationEnabled: false,
      ),
  if (_destino != null)
    Positioned(
  bottom: 40, // 👈 más arriba del borde
  left: 20,
  right: 20,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch, // 👈 para que el botón se expanda
    children: [
      if (_duracionEstimado != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            'Tiempo estimado: $_duracionEstimado',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      SizedBox(
        height: 48,
        child: ElevatedButton.icon(
          onPressed: () async {
            if (_origen != null && _destino != null) {
              final url = Uri.parse(
                'https://www.google.com/maps/dir/?api=1'
                '&origin=${_origen!.latitude},${_origen!.longitude}'
                '&destination=${_destino!.latitude},${_destino!.longitude}'
                '&travelmode=driving&dir_action=navigate',
              );

              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                print('No se pudo abrir Google Maps');
              }
            }
          },
          icon: const Icon(Icons.directions),
          label: const Text("Iniciar ruta"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    ],
  ),
),

    ],
  ),

      );
    }
  }
