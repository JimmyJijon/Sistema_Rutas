class LocationModel {
  final int? id;
  final double latitude;
  final double longitude;
  final String timestamp; // Aquí guardaremos la fecha y hora formateada

  LocationModel({
    this.id,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  // Convertir nuestro objeto a un Mapa (para guardarlo en SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
    };
  }

  // Crear un objeto a partir de un Mapa (cuando leemos de SQLite)
  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      id: map['id'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      timestamp: map['timestamp'],
    );
  }
}