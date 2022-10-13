import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_floating_marker_titles/flutter_map_floating_marker_titles.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Open Street Map',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final FMTOOptions fmtoOptions = FMTOOptions();
  final List<FloatingMarkerTitleInfo> floatingTitles = [];
  late List<Marker> _markers;

  @override
  void initState() {
    super.initState();
    permsAndGPS();
    _markers = [
      LatLng(44.421, 10.404),
      LatLng(45.683, 10.839),
      LatLng(45.246, 5.783),
    ].map(
      (markerPosition) {
        floatingTitles.add(FloatingMarkerTitleInfo(
          id: markerPosition.hashCode,
          latLng: markerPosition,
          title: markerPosition.toString(),
          color: Colors.green,
        ));
        return Marker(
          point: markerPosition,
          width: 40,
          height: 40,
          builder: (_) => const Icon(Icons.location_on, size: 40),
          anchorPos: AnchorPos.align(AnchorAlign.top),
        );
      },
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Open Street Map')),
      body: FlutterMapWithFMTO(
        floatingTitles: floatingTitles,
        fmtoOptions: fmtoOptions,
        options: MapOptions(
            center: LatLng(45, 10),
            zoom: 6,
            maxZoom: 15,
            interactiveFlags: InteractiveFlag.all ^ InteractiveFlag.rotate),
        children: <Widget>[
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
          ),
          MarkerClusterLayerWidget(
            options: MarkerClusterLayerOptions(
              maxClusterRadius: 45,
              size: const Size(40, 40),
              anchor: AnchorPos.align(AnchorAlign.center),
              fitBoundsOptions: const FitBoundsOptions(
                padding: EdgeInsets.all(50),
                maxZoom: 15,
              ),
              markers: _markers,
              builder: (context, markers) {
                return Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.blue),
                  child: Center(
                    child: Text(
                      markers.length.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
          CurrentLocationLayer(
              centerOnLocationUpdate: CenterOnLocationUpdate.always),
        ],
      ),
    );
  }

  void permsAndGPS() async {
    LocationPermission permission = await Geolocator.checkPermission();
    switch (permission) {
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        break;
      case LocationPermission.denied:
        permission = await Geolocator.requestPermission();
        break;
      case LocationPermission.deniedForever:
      case LocationPermission.unableToDetermine:
        await Geolocator.openAppSettings();
        break;
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
    }
  }
}
