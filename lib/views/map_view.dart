import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../viewmodels/location_viewmodel.dart';

class MapView extends StatelessWidget {
  const MapView({super.key});

@override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LocationViewModel>();

    // 1. PANTALLA DE CARGA: Si el GPS todavía está buscando ubicación
    if (viewModel.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(), // Ruedita de carga
        ),
      );
    }

    // 2. LÓGICA DE LA CÁMARA - Si ya hay una ruta guardada, centramos en el último punto. Si no, centramos en la ubicación actual (si ya se obtuvo).
    LatLng startingPoint = const LatLng(0, 0); // Por defecto
    
    if (viewModel.savedLocations.isNotEmpty) {
      // Si ya hay una ruta guardada, empezamos en el último punto
      startingPoint = LatLng(
        viewModel.savedLocations.last.latitude,
        viewModel.savedLocations.last.longitude,
      );
    } else if (viewModel.currentPosition != null) {
      // Si la base de datos está vacía pero ya tenemos la ubicación actual, empezamos ahí
      startingPoint = viewModel.currentPosition!;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Ruta GPS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () {
              viewModel.clearRoute();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ruta y base de datos limpiadas')),
              );
            },
          )
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            // --- AQUÍ USAMOS NUESTRO NUEVO STARTING POINT ---
            initialCameraPosition: CameraPosition(
              target: startingPoint,
              zoom: 15, // Zoom más cercano a las calles
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            polylines: viewModel.polylines, 
            markers: viewModel.markers,     
            onTap: (LatLng point) {
              viewModel.saveCustomLocation(point);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Punto manual guardado con éxito')),
              );
            },
            onMapCreated: (GoogleMapController controller) {},
          ),

          // Tarjeta de la distancia
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Card(
              elevation: 4,
              color: Colors.white.withOpacity(0.9),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  'Distancia Total: ${(viewModel.totalDistance / 1000).toStringAsFixed(2)} km',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          viewModel.saveCurrentLocation();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Coordenada guardada con éxito')),
          );
        },
        label: const Text('Guardar Ubicación'),
        icon: const Icon(Icons.add_location_alt),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}