import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../models/location_model.dart';
import '../database/database_helper.dart';

class LocationViewModel extends ChangeNotifier {
  // --- VARIABLES DE ESTADO ---
  bool _isLoading = true; 
  List<LocationModel> _savedLocations = [];
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  double _totalDistance = 0.0;
  LatLng? _currentPosition;

  // --- GETTERS (Para que la Vista pueda leer estos datos) ---
  bool get isLoading => _isLoading; 
  List<LocationModel> get savedLocations => _savedLocations;
  Set<Polyline> get polylines => _polylines;
  Set<Marker> get markers => _markers;
  double get totalDistance => _totalDistance;
  LatLng? get currentPosition => _currentPosition;

  LocationViewModel() {
    _initSetup();
  }

  // Inicializa pidiendo permisos y cargando datos previos
Future<void> _initSetup() async {
    await _checkLocationPermission();
    await _fetchInitialPosition(); // <-- OBTENEMOS LA UBICACIÓN INICIAL PARA CENTRAR EL MAPA
    await loadLocations();
    _isLoading = false;            // <-- AVISAMOS QUE YA CARGÓ
    notifyListeners();             // <-- ACTUALIZAMOS LA PANTALLA
  }

  // 1. Validar permisos de GPS
  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
  }

  // 2. Guardar la ubicación actual en SQLite
  Future<void> saveCurrentLocation() async {
    try {
      // Obtenemos la coordenada exacta
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      
      _currentPosition = LatLng(position.latitude, position.longitude);

      // Formateamos la fecha y hora usando 'intl'
      String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      // Creamos el modelo
      LocationModel newLocation = LocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: formattedDate,
      );

      // Guardamos en la Base de Datos
      await DatabaseHelper.instance.insertLocation(newLocation);

      // Recargamos la lista para actualizar el mapa
      await loadLocations();
    } catch (e) {
      debugPrint("Error obteniendo ubicación: $e");
    }
  }

  // 3. Cargar las ubicaciones de SQLite y preparar el mapa
  Future<void> loadLocations() async {
    _savedLocations = await DatabaseHelper.instance.getAllLocations();
    
    _updateMapData();
    _calculateTotalDistance();
    
    // Avisamos a la Vista (pantalla) que hay datos nuevos para redibujar
    notifyListeners();
  }

  // 4. Limpiar la ruta (Nuestra funcionalidad extra obligatoria)
  Future<void> clearRoute() async {
    await DatabaseHelper.instance.deleteAllLocations();
    _savedLocations.clear();
    _polylines.clear();
    _markers.clear();
    _totalDistance = 0.0;
    notifyListeners();
  }

  // 5. Guardar una ubicación manual (Para pruebas simuladas)
  Future<void> saveCustomLocation(LatLng point) async {
    try {
      // Formateamos la fecha y hora actual
      String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      // Creamos el modelo con la ubicación manual
      LocationModel newLocation = LocationModel(
        latitude: point.latitude,
        longitude: point.longitude,
        timestamp: formattedDate,
      );

      // Guardamos en la Base de Datos
      await DatabaseHelper.instance.insertLocation(newLocation);

      // Recargamos la lista para actualizar el mapa (dibujar línea y marcador)
      await loadLocations();
    } catch (e) {
      debugPrint("Error guardando ubicación manual: $e");
    }
  }

  Future<void> _fetchInitialPosition() async { // <-- MÉTODO PARA OBTENER LA UBICACIÓN INICIAL
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _currentPosition = LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint("No se pudo obtener la ubicación: $e");
    }
  }

  // --- MÉTODOS INTERNOS PARA PROCESAR DATOS ---

  // Prepara las Polilíneas (la ruta trazada) y los Marcadores
  void _updateMapData() {
    List<LatLng> routePoints = [];
    _markers.clear();

    for (int i = 0; i < _savedLocations.length; i++) {
      var loc = _savedLocations[i];
      LatLng point = LatLng(loc.latitude, loc.longitude);
      routePoints.add(point);

      // Funcionalidad Extra 2: Marcadores con InfoWindow (Fecha y Hora)
      _markers.add(
        Marker(
          markerId: MarkerId('punto_$i'),
          position: point,
          infoWindow: InfoWindow(
            title: 'Punto ${i + 1}',
            snippet: loc.timestamp, // Aquí mostramos la fecha y hora guardada
          ),
        ),
      );
    }

    _polylines.clear();
    if (routePoints.isNotEmpty) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('ruta_historial'),
          points: routePoints,
          color: Colors.blue,
          width: 5,
        ),
      );
    }
  }

  // Funcionalidad Extra 1: Cálculo de distancia total en metros
  void _calculateTotalDistance() {
    _totalDistance = 0.0;
    if (_savedLocations.length < 2) return;

    for (int i = 0; i < _savedLocations.length - 1; i++) {
      _totalDistance += Geolocator.distanceBetween(
        _savedLocations[i].latitude,
        _savedLocations[i].longitude,
        _savedLocations[i+1].latitude,
        _savedLocations[i+1].longitude,
      );
    }
  }
}