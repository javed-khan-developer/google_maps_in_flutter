import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'src/locations.dart' as locations;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Map<String, Marker> _markers = {};
  late GoogleMapController _mapController;
  final TextEditingController _searchController = TextEditingController();
  LatLng? _selectedLocation;
  String _selectedAddress = "";

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    final googleOffices = await locations.getGoogleOffices();
    setState(() {
      _markers.clear();
      for (final office in googleOffices.offices) {
        final marker = Marker(
          markerId: MarkerId(office.name),
          position: LatLng(office.lat, office.lng),
          infoWindow: InfoWindow(
            title: office.name,
            snippet: office.address,
          ),
        );
        _markers[office.name] = marker;
      }
    });
  }

  Future<void> _searchLocation() async {
    String query = _searchController.text;
    if (query.isEmpty) return;
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        Location loc = locations.first;
        LatLng newPosition = LatLng(loc.latitude, loc.longitude);
        _mapController
            .animateCamera(CameraUpdate.newLatLngZoom(newPosition, 10));
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> _onTap(LatLng position) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      String address = placemarks.isNotEmpty
          ? "${placemarks.first.name}, ${placemarks.first.locality}, ${placemarks.first}"
          : "Unknown Location";
      setState(() {
        _selectedLocation = position;
        _selectedAddress = address;
        _markers['Selected Location'] = Marker(
          markerId: MarkerId('Selected Location'),
          position: position,
          infoWindow: InfoWindow(title: "Selected Location", snippet: address),
        );
      });
      _showLocationForm();
    } catch (e) {
      print("Error fetching address: $e");
    }
  }

  void _showLocationForm() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Selected Location",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text("Address: $_selectedAddress"),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Map'),
        elevation: 2,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: SizedBox(
              width: MediaQuery.of(context).size.width / 2,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search location",
                  prefixIcon: IconButton(
                    icon: Icon(Icons.search),
                    onPressed: _searchLocation,
                  ),
                ),
                onSubmitted: (value) => _searchLocation(),
              ),
            ),
          )
        ],
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: const CameraPosition(
          target: LatLng(0, 0),
          zoom: 2,
        ),
        markers: _markers.values.toSet(),
        onTap: _onTap,
      ),
    );
  }
}
