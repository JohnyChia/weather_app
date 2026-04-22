import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import '../Services/network_tile.dart';
import '../Services/api_service.dart';
import '../Utils/translator.dart';

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

  final ApiService apiService = ApiService();
  Set<Marker> riskMarkers = {};

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

      if (userLat != null && userLon != null) {
        userMarker = Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(userLat!, userLon!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        );
      }
    });
    _loadNearestRisk();
  }

  Future<void> _loadNearestRisk() async {
    if (userLat == null || userLon == null) return;

    try {
      final result = await apiService.fetchNearestRisk();

      if (result != null && result is List) {
        Set<Marker> markers = {};

        for (var item in result) {
          final lat = item['lat'];
          final lon = item['lon'];
          final risk = item['risk'];

          if (lat == null || lon == null) continue;

          final markerColor = risk == "High"
              ? BitmapDescriptor.hueRed : BitmapDescriptor.hueOrange;

          markers.add(
            Marker(
              markerId: MarkerId(item['id']?.toString() ?? "$lat$lon"),
              position: LatLng(lat, lon),
              icon: BitmapDescriptor.defaultMarkerWithHue(markerColor),

              infoWindow: InfoWindow(
                title: item['city'] ?? 'Unknown City',
                snippet: "Type: ${item['type'] ?? ''} | Risk: ${item['risk'] ?? ''}",
              ),
            ),
          );
        }

        setState(() {
          riskMarkers = markers;
        });
      }
    } catch (e) {
      throw Exception("Risk fetch error: $e");
    }
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
        title: const AutoText('Live Weather Map'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(userLat!, userLon!),
              zoom: 14,
            ),
            markers: {
              ...riskMarkers,
              ...{userMarker}.whereType<Marker>(),
            },
            tileOverlays: _tileOverlays,
            onMapCreated: (controller) {
              _controller.complete(controller);
              _addTileOverlay();
            },
          ),

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
          backgroundColor: isActive ? Colors.blue : Colors.grey,
        ),
        onPressed: () => _changeLayer(layer),
        child: AutoText(label),
      ),
    );
  }

  Widget _buildLegend(String layer) {
    switch (layer) {
      case 'clouds_new':
        return const AutoText('Cloud coverage legend', style: TextStyle(color: Colors.white));
      case 'precipitation_new':
        return const AutoText('Rainfall legend', style: TextStyle(color: Colors.white));
      case 'wind_new':
        return const AutoText('Wind speed legend', style: TextStyle(color: Colors.white));
      case 'temp_new':
        return const AutoText('Temperature legend', style: TextStyle(color: Colors.white));
      default:
        return const AutoText('Legend', style: TextStyle(color: Colors.white));
    }
  }
}