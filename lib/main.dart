import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String lightMapURL =
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';
  List<LatLng> points = [];
  final LocationDatabaseHelper _databaseHelper = LocationDatabaseHelper();
  late Timer _timer;
  Location location = Location();
  LatLng initialCenter =
      const LatLng(31.309346, 48.675024); // Initial center set to Ahvaz city

  @override
  void initState() {
    super.initState();
    getStoredLocationDataFromDatabase();
    startTimer();
    // Get current location and set it as the initial center
    getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Background Location Service'),
        ),
        body: Center(
          child: Column(
            children: [
              Flexible(
                flex: 3,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: points.isNotEmpty
                        ? points.last
                        : const LatLng(31.304292, 48.671116),
                    initialZoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: lightMapURL,
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: points,
                          color: Colors.red,
                          strokeWidth: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Flexible(
                flex: 1,
                child: ListView(
                  children: [
                    for (int i = 0; i < points.length; i++)
                      ListTile(
                        title: Text('Point ${i + 1}'),
                        subtitle: Text(
                            'Latitude: ${points[i].latitude}, Longitude: ${points[i].longitude}'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      getLocationData();
    });
  }

  void getLocationData() async {
    try {
      LocationData currentLocation = await location.getLocation();
      setState(() {
        points
            .add(LatLng(currentLocation.latitude!, currentLocation.longitude!));
      });
      await storeLocationDataInDatabase(
          currentLocation.latitude!, currentLocation.longitude!);
    } catch (e) {
      print('Failed to get current location: $e');
    }
  }

  Future<void> storeLocationDataInDatabase(
      double latitude, double longitude) async {
    await _databaseHelper.insertLocation(latitude, longitude);
  }

  Future<void> getStoredLocationDataFromDatabase() async {
    List<Map<String, dynamic>> locationMaps =
        await _databaseHelper.getAllLocations();
    setState(() {
      points = locationMaps.map((location) {
        double latitude = location['latitude'] as double;
        double longitude = location['longitude'] as double;
        return LatLng(latitude, longitude);
      }).toList();
    });
  }

  void getCurrentLocation() async {
    try {
      LocationData currentLocation = await location.getLocation();
      setState(() {
        initialCenter =
            LatLng(currentLocation.latitude!, currentLocation.longitude!);
        points.add(initialCenter); // Add current location to the beginning
      });
    } catch (e) {
      print('Failed to get current location: $e');
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}

class LocationDatabaseHelper {
  static final LocationDatabaseHelper _instance =
      LocationDatabaseHelper._internal();

  factory LocationDatabaseHelper() => _instance;

  LocationDatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    String path = join(await getDatabasesPath(), 'locations.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE locations(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            latitude REAL,
            longitude REAL
          )
        ''');
      },
    );
  }

  Future<void> insertLocation(double latitude, double longitude) async {
    final Database db = await database;
    await db.insert(
      'locations',
      {'latitude': latitude, 'longitude': longitude},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAllLocations() async {
    final Database db = await database;
    return await db.query('locations');
  }
}
