import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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
  List<LatLng> points = [];
  SharedPreferences? _prefs;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    initializeSharedPreferences();
    startTimer();
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
                    initialZoom: 20.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png",
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: points,
                          color: Colors.red,
                          strokeWidth: 6,
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

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}
