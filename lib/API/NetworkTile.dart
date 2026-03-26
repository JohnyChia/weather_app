import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class NetworkTileProvider implements TileProvider {
  final String layer;

  NetworkTileProvider(this.layer);

  @override
  Future<Tile> getTile(int x, int y, int? zoom) async {
    if (zoom == null) {
      return Tile(256, 256, Uint8List(0));
    }

    final url =
        'https://unstabilising-karena-toric.ngrok-free.dev/api/tiles/$layer/$zoom/$x/$y.png?t=${DateTime.now().millisecondsSinceEpoch}';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "ngrok-skip-browser-warning": "true",
          'User-Agent': 'Mozilla/5.0',
          'Cache-Control': 'no-cache',
          'Pragma' : 'no-cache',
        },
      ).timeout(const Duration(seconds : 5));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return Tile(256, 256, response.bodyBytes);
      }

    } catch (e) {
      print("Tile error: $e");
    }

    return Tile(256, 256, Uint8List(0));
  }
}