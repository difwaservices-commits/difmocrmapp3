import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:flutter_application_difmo/services/api_service.dart';

const kGoogleApiKey = "YOUR_GOOGLE_MAPS_API_KEY"; // 🔑 Replace with your key
final GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: kGoogleApiKey);

class LocationConfirmPage extends StatefulWidget {
  final bool isCheckIn;
  final String? employeeId;
  final String? attendanceId;

  const LocationConfirmPage({
    super.key,
    required this.isCheckIn,
    this.employeeId,
    this.attendanceId,
  });

  @override
  State<LocationConfirmPage> createState() => _LocationConfirmPageState();
}

class _LocationConfirmPageState extends State<LocationConfirmPage> {
  GoogleMapController? mapController;
  LatLng? currentPosition;
  String address = "Fetching address...";
  double accuracy = 0.0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  /// 🧭 Get user location
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      currentPosition = LatLng(position.latitude, position.longitude);
      accuracy = position.accuracy;
    });

    await _getAddressFromLatLng(position);
  }

  /// 📍 Convert LatLng to Address
  Future<void> _getAddressFromLatLng(Position position) async {
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    Placemark place = placemarks[0];
    setState(() {
      address =
          "${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}";
    });
  }

  /// 🔁 Refresh button
  void _refreshLocation() {
    _determinePosition();
  }

  /// ✅ Confirm button
  /// ✅ Confirm button
  Future<void> _confirmLocation() async {
    if (currentPosition == null) return;

    try {
      if (widget.isCheckIn) {
        if (widget.employeeId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error: Employee ID not found")),
          );
          return;
        }
        await ApiService.checkIn(
          widget.employeeId!,
          currentPosition!.latitude,
          currentPosition!.longitude,
          address,
          "", // notes
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Checked In Successfully!")),
          );
          Navigator.pop(context); // Close location page
          // Navigator.pop(context); // Close popup (already closed in previous screen but good to be safe if flow changes)
        }
      } else {
        if (widget.attendanceId == null) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error: Attendance ID not found")),
          );
          return;
        }
        await ApiService.checkOut(
          widget.attendanceId!,
          currentPosition!.latitude,
          currentPosition!.longitude,
          "", // notes
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Checked Out Successfully!")),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  /// 🔍 Search for places using Google Places API
  Future<void> _handleSearch() async {
    Prediction? p = await PlacesAutocomplete.show(
      context: context,
      apiKey: kGoogleApiKey,
      mode: Mode.overlay, // fullScreen also possible
      language: "en",
      components: [Component(Component.country, "in")], // restrict to India
    );

    if (p != null) {
      PlacesDetailsResponse detail = await _places.getDetailsByPlaceId(
        p.placeId!,
      );
      final lat = detail.result.geometry!.location.lat;
      final lng = detail.result.geometry!.location.lng;

      setState(() {
        currentPosition = LatLng(lat, lng);
        address = detail.result.formattedAddress ?? "No address found";
      });

      mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(lat, lng), zoom: 16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          currentPosition == null
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: currentPosition!,
                    zoom: 15,
                  ),
                  zoomGesturesEnabled: true,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  onMapCreated: (controller) => mapController = controller,
                ),

          // 🔍 Search bar
          SafeArea(
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: _handleSearch,
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: "Search location",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 🏠 Bottom Confirm Card
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Confirm Address",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Accurate to ${accuracy.toStringAsFixed(1)} m",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(address, style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: _refreshLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        child: const Text("Refresh"),
                      ),
                      ElevatedButton(
                        onPressed: _confirmLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        child: const Text("Confirm"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
