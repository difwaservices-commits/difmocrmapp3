import 'package:flutter/material.dart';
import 'package:flutter_application_difmo/pages/location_page.dart';
import 'package:geolocator/geolocator.dart';

class LocationPopup extends StatefulWidget {
  final VoidCallback onClose;
  final Function(Position position)? onPermissionGranted;
  final bool isCheckIn;
  final String? employeeId;
  final String? attendanceId;

  const LocationPopup({
    super.key,
    required this.onClose,
    this.onPermissionGranted,
    required this.isCheckIn,
    this.employeeId,
    this.attendanceId,
  });

  @override
  State<LocationPopup> createState() => _LocationPopupState();
}

class _LocationPopupState extends State<LocationPopup> {
  Future<void> _requestLocation() async {
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
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location permission denied")),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Location permission permanently denied. Enable in settings.",
            ),
          ),
        );
      }
      return;
    }

    // Permission granted
    Position position = await Geolocator.getCurrentPosition();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Location Enabled: ${position.latitude}, ${position.longitude}",
        ),
      ),
    );

    widget.onPermissionGranted?.call(position);

    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LocationConfirmPage(
            isCheckIn: widget.isCheckIn,
            employeeId: widget.employeeId,
            attendanceId: widget.attendanceId,
          ),
        ),
      );

      widget.onClose(); // Hide popup and refresh dashboard after returning
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: InkWell(
                onTap: widget.onClose,
                child: const Icon(Icons.close, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 10),
            Image.network(
              'https://cdn-icons-png.flaticon.com/512/854/854878.png',
              height: 120,
            ),
            const SizedBox(height: 20),
            const Text(
              "Enable Location for Seamless Attendance",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: _requestLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                "Turn On Location",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
