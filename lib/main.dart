import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/location_viewmodel.dart';
import 'views/map_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Aquí inyectamos nuestro ViewModel usando Provider
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocationViewModel()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Mi Ruta GPS',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MapView(), // Nuestra pantalla principal es el mapa
      ),
    );
  }
}
