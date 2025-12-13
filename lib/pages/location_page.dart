import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_difmo/services/api_provider.dart';

const kGoogleApiKey = "YOUR_GOOGLE_MAPS_API_KEY"; // 🔑 Replace with your key
final GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: kGoogleApiKey);

class LocationConfirmPage extends ConsumerStatefulWidget {
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
  ConsumerState<LocationConfirmPage> createState() =>
      _LocationConfirmPageState();
}

class _LocationConfirmPageState extends ConsumerState<LocationConfirmPage> {
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

    if (!mounted) return;

    setState(() {
      currentPosition = LatLng(position.latitude, position.longitude);
      accuracy = position.accuracy;
    });

    await _getAddressFromLatLng(position);
  }

  /// 📍 Convert LatLng to Address
  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      Placemark place = placemarks[0];
      if (!mounted) return;
      setState(() {
        address =
            "${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}";
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        address = "Address not found";
      });
    }
  }

  /// 🔁 Refresh button
  void _refreshLocation() {
    _determinePosition();
  }

  /// ✅ Confirm button
  Future<void> _confirmLocation() async {
    print(
      "DEBUG: Confirm clicked. isCheckIn: ${widget.isCheckIn}, EmployeeID: ${widget.employeeId}, AttendanceID: ${widget.attendanceId}",
    );

    if (currentPosition == null) {
      print("DEBUG: currentPosition is null");
      return;
    }

    if (widget.isCheckIn) {
      if (widget.employeeId == null) {
        print("DEBUG: EmployeeID is null");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: Employee ID not found")),
        );
        return;
      }
      print("DEBUG: Calling checkIn...");
      await ref
          .read(locationActionProvider.notifier)
          .checkIn(
            widget.employeeId!,
            currentPosition!.latitude,
            currentPosition!.longitude,
            address,
            "", // notes
          );
      print("DEBUG: checkIn called");
    } else {
      if (widget.attendanceId == null) {
        print("DEBUG: AttendanceID is null");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: Attendance ID not found")),
        );
        return;
      }
      print("DEBUG: Calling checkOut...");
      await ref
          .read(locationActionProvider.notifier)
          .checkOut(
            widget.attendanceId!,
            currentPosition!.latitude,
            currentPosition!.longitude,
            "", // notes
          );
      print("DEBUG: checkOut called");
    }
  }

  Future<void> _handleSearch() async {
    if (kGoogleApiKey.contains("YOUR_")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please configure Google Maps API Key in location_page.dart",
          ),
        ),
      );
      return;
    }
    Prediction? p = await PlacesAutocomplete.show(
      context: context,
      apiKey: kGoogleApiKey,
      mode: Mode.overlay, // fullScreen also possible
      language: "en",
      components: [Component(Component.country, "in")], // restrict to India
    );

    if (p != null) {
      if (!mounted) return;
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
    // Listen to provider changes for SnackBar feedback and Navigation
    ref.listen<ApiState>(locationActionProvider, (previous, next) {
      if (next.status == ApiStatus.success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.message ?? "Success")));
        Navigator.pop(context);
      } else if (next.status == ApiStatus.error) {
        _showErrorDialog(context, next.message ?? "An error occurred");
      }
    });

    final apiState = ref.watch(locationActionProvider);
    final isLoading = apiState.status == ApiStatus.loading;

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
                        onPressed: isLoading
                            ? null
                            : _refreshLocation, // Disable when loading
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        child: const Text("Refresh"),
                      ),
                      ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : _confirmLocation, // Disable when loading
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text("Confirm"),
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

  void _showErrorDialog(BuildContext context, String rawMessage) {
    String displayMessage = rawMessage;

    // 1. Try to parse if it's JSON inside the exception string
    // Standardize: Remove "Exception: Check-in failed: " prefix first
    String cleanStr = rawMessage
        .replaceAll("Exception: Check-in failed: ", "")
        .replaceAll("Exception: Check-out failed: ", "")
        .replaceAll("Exception: ", "");

    try {
      // Only try to parse if it looks like JSON
      if (cleanStr.trim().startsWith("{")) {
        final Map<String, dynamic> errorJson = jsonDecode(cleanStr);
        if (errorJson.containsKey('message')) {
          displayMessage = errorJson['message'];
        }
      } else {
        displayMessage = cleanStr;
      }
    } catch (_) {
      displayMessage = cleanStr;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.location_off, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text("Location Alert"),
          ],
        ),
        content: Text(displayMessage, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              "OK",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
