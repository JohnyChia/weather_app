import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import '../API/NetworkTile.dart';

class MapScreen extends StatefulWidget {
  final double lat;
  final double lon;

  const MapScreen({
    super.key,
    required this.lat,
    required this.lon,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();

  double? userLat;
  double? userLon;

  String currentLayer = 'clouds_new';
  Set<TileOverlay> _tileOverlays = <TileOverlay>{};
  Marker? userMarker;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    Location location = Location();

    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    final locData = await location.getLocation();
    setState(() {
      userLat = locData.latitude;
      userLon = locData.longitude;

      // Add user blue marker
      if (userLat != null && userLon != null) {
        userMarker = Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(userLat!, userLon!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'You are here'),
        );
      }
    });
  }

  void _addTileOverlay() {

    final overlay = TileOverlay(
      tileOverlayId: TileOverlayId('weather_$currentLayer'),
      tileProvider: NetworkTileProvider(currentLayer),
    );

    setState(() {
      _tileOverlays = {overlay};
    });
  }

  void _changeLayer(String layer) {
    setState(() {
      currentLayer = layer;
      _tileOverlays = {};
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      _addTileOverlay();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (userLat == null || userLon == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Weather Map'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(userLat!, userLon!),
              zoom: 5,
            ),
            markers: userMarker != null ? {userMarker!} : {},
            tileOverlays: _tileOverlays,
            onMapCreated: (controller) {
              _controller.complete(controller);
              _addTileOverlay();
            },
          ),

          // Layer buttons
          Positioned(
            top: 10,
            right: 10,
            child: Column(
              children: [
                _buildLayerButton('clouds_new', 'Clouds'),
                _buildLayerButton('precipitation_new', 'Rain'),
                _buildLayerButton('wind_new', 'Wind'),
                _buildLayerButton('temp_new', 'Temperature'),
              ],
            ),
          ),

          // Dynamic legend
          Positioned(
            bottom: 20,
            left: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _buildLegend(currentLayer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayerButton(String layer, String label) {
    final isActive = currentLayer == layer;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? Colors.blue : Colors.grey.shade700,
        ),
        onPressed: () => _changeLayer(layer),
        child: Text(label),
      ),
    );
  }

  Widget _buildLegend(String layer) {
    switch (layer) {
      case 'clouds_new':
        return const Text('Cloud coverage legend', style: TextStyle(color: Colors.white));
      case 'precipitation_new':
        return const Text('Rainfall legend', style: TextStyle(color: Colors.white));
      case 'wind_new':
        return const Text('Wind speed legend', style: TextStyle(color: Colors.white));
      case 'temp_new':
        return const Text('Temperature legend', style: TextStyle(color: Colors.white));
      default:
        return const Text('Legend', style: TextStyle(color: Colors.white));
    }
  }
}

