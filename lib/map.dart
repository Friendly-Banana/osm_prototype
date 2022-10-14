import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late List<Marker> _markers;
  late CenterOnLocationUpdate _centerOnLocationUpdate;
  late StreamController<double?> _centerCurrentLocationStreamController;

  @override
  void initState() {
    super.initState();
    permsAndGPS();
    _centerOnLocationUpdate = CenterOnLocationUpdate.always;
    _centerCurrentLocationStreamController = StreamController<double?>();
    _markers = [
      LatLng(44.421, 10.404),
      LatLng(45.683, 10.839),
      LatLng(45.246, 5.783),
    ].map(
      (markerPosition) {
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
  void dispose() {
    _centerCurrentLocationStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Open Street Map')),
      body: FlutterMap(
          options: MapOptions(
            center: LatLng(45, 10),
            zoom: 6,
            maxZoom: 15,
            interactiveFlags: InteractiveFlag.all ^ InteractiveFlag.rotate,
            // Stop centering the location marker on the map if user interacted with the map.
            onPositionChanged: (MapPosition position, bool hasGesture) {
              if (hasGesture) {
                setState(
                  () => _centerOnLocationUpdate = CenterOnLocationUpdate.never,
                );
              }
            },
          ),
          // ignore: sort_child_properties_last
          children: <Widget>[
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
              maxZoom: 19,
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
                    builder: (context, markers) => Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.blue),
                          child: Center(
                            child: Text(
                              markers.length.toString(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ))),
            CurrentLocationLayer(
              centerCurrentLocationStream:
                  _centerCurrentLocationStreamController.stream,
              centerOnLocationUpdate: _centerOnLocationUpdate,
            ),
          ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Automatically center the location marker on the map when location updated until user interact with the map.
          setState(
            () => _centerOnLocationUpdate = CenterOnLocationUpdate.always,
          );
          // Center the location marker on the map and zoom the map to level 17.
          _centerCurrentLocationStreamController.add(17);
        },
        child: const Icon(
          Icons.my_location,
          color: Colors.white,
        ),
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

    // fail because user
    permission = await Geolocator.checkPermission();
    if (!(permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) ||
        !await Geolocator.isLocationServiceEnabled()) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Enable GPS and give permission"),
        duration: Duration(seconds: 5),
      ));
    }
  }
}
