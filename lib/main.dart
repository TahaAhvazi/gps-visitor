import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String lightMapURL =
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';
  List<LatLng> points = [
    LatLng(31.2990, 48.6613),
  ];
  SharedPreferences? _prefs;
  late Timer _timer;
  Location location = Location();
  LatLng initialCenter =
      LatLng(31.2990, 48.6613); // Initial center set to Ahvaz city

  @override
  void initState() {
    super.initState();
    initializeSharedPreferences();
    // Load stored location data when the app starts
    getStoredLocationData();
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
                    center: initialCenter,
                    zoom: 15.0,
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

  void initializeSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      getLocationData();
    });
  }

  void getLocationData() async {
    // Simulating location data, replace with actual location retrieval logic
    double latitude = 40.7128; // New York City latitude
    double longitude = -74.0060; // New York City longitude

    setState(() {
      points.add(LatLng(latitude, longitude));
    });

    storeLocationData(latitude, longitude);
  }

  void storeLocationData(double latitude, double longitude) {
    List<String> locationStrings = _prefs?.getStringList('locations') ?? [];
    locationStrings.add('$latitude,$longitude');
    _prefs?.setStringList('locations', locationStrings);
  }

  void getStoredLocationData() {
    List<String>? storedLocationStrings = _prefs?.getStringList('locations');
    if (storedLocationStrings != null) {
      setState(() {
        points = storedLocationStrings.map((location) {
          List<String> coordinates = location.split(',');
          double latitude = double.parse(coordinates[0]);
          double longitude = double.parse(coordinates[1]);
          return LatLng(latitude, longitude);
        }).toList();
      });
    }
  }

  void getCurrentLocation() async {
    try {
      LocationData currentLocation = await location.getLocation();
      setState(() {
        initialCenter =
            LatLng(currentLocation.latitude!, currentLocation.longitude!);
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
