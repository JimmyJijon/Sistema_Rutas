import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/location_model.dart';

class DatabaseHelper {
  // Patrón Singleton para tener una única instancia de la base de datos
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('locations.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Abre la base de datos (o la crea si no existe)
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // Aquí creamos la tabla con los campos necesarios para guardar las coordenadas y la fecha/hora
    await db.execute('''
    CREATE TABLE locations (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      latitude REAL NOT NULL,
      longitude REAL NOT NULL,
      timestamp TEXT NOT NULL
    )
    ''');
  }

  // --- MÉTODOS PARA OPERAR EN LA BASE DE DATOS ---

  // 1. Guardar una coordenada
  Future<int> insertLocation(LocationModel location) async {
    final db = await instance.database;
    return await db.insert('locations', location.toMap());
  }

  // 2. Leer todas las coordenadas guardadas (Para dibujar la ruta)
  Future<List<LocationModel>> getAllLocations() async {
    final db = await instance.database;
    final result = await db.query('locations', orderBy: 'id ASC'); // Ordenadas por cómo se guardaron
    return result.map((json) => LocationModel.fromMap(json)).toList();
  }

  // 3. Borrar todas las coordenadas (Para el botón de Limpiar Ruta)
  Future<int> deleteAllLocations() async {
    final db = await instance.database;
    return await db.delete('locations');
  }
}