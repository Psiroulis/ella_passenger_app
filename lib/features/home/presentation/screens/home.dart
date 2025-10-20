import 'dart:async';

import 'package:ella_passenger/features/auth/presentation/notifiers/phone_auth_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Completer<GoogleMapController> _controller = Completer();

  String _currentAddressLine1 = "Αναζήτηση";
  String _currentAddressLine2 = "τοποθεσιας...";
  String _currentAddress = "Αναζήτηση";

  LatLng? _cameraTarget;
  LatLng? _gpsLatLng;
  bool _isGeocoding = false;

  String? _mapStyle;

  static const LatLng _athens = LatLng(37.9838, 23.7275);

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _initLocationFlow();
  }

  Future<void> _loadMapStyle() async {
    _mapStyle = await rootBundle.loadString('assets/map_style.json');
    setState(() {});
  }

  Future<void> _initLocationFlow() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      _showSnack('Ενεργοποίησε το GPS για να δούμε την τοποθεσία σου.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      _showSnack('Δεν δόθηκε άδεια τοποθεσίας.');
      return;
    }
    if (permission == LocationPermission.deniedForever) {
      _showSnack(
        'Η άδεια τοποθεσίας είναι μόνιμα απορριφθείσα. Άλλαξέ το από Ρυθμίσεις.',
      );
      return;
    }

    Position? lastPos = await Geolocator.getLastKnownPosition();

    if (lastPos != null) {
      _cameraTarget = LatLng(lastPos.latitude, lastPos.longitude);
      setState(() {});

      await _reverseGeocodeAt(_cameraTarget!);
    } else {
      _cameraTarget = _athens;
    }

    final LocationSettings locationSetting = LocationSettings(
      accuracy: LocationAccuracy.high,
    );

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: locationSetting,
    );

    _gpsLatLng = LatLng(pos.latitude, pos.longitude);

    _cameraTarget = _gpsLatLng;

    setState(() {});

    final map = await _controller.future;

    await map.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _cameraTarget!, zoom: 16),
      ),
    );

    await _reverseGeocodeAt(_cameraTarget!);
  }

  Future<void> _reverseGeocodeAt(LatLng point) async {
    if (_isGeocoding) return;
    _isGeocoding = true;
    try {
      final placemarks = await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;

        print("address: $p");
        final street = [
          p.street,
          p.subThoroughfare,
        ].where((x) => (x ?? '').isNotEmpty).join(' ');
        final locality = p.locality?.isNotEmpty == true
            ? p.locality
            : p.subAdministrativeArea;
        final parts = [
          street.trim(),
          locality?.trim(),
          p.country?.trim(),
        ].where((x) => (x ?? '').isNotEmpty).toList();

        final parts2 = [
          p.thoroughfare?.trim(),
          p.subThoroughfare?.trim(),
          p.locality?.trim(),
        ].where((x) => (x ?? '').isNotEmpty).toList();

        setState(() {
          if (parts2.isNotEmpty) {
            _currentAddressLine1 = "${parts2[0]!} ${parts2[1]!}";
            _currentAddressLine2 = parts2[2]!;
          }

          _currentAddress = parts.isEmpty
              ? "Χωρίς διαθέσιμη διεύθυνση"
              : parts2.join(', ');
        });
      } else {
        setState(() => _currentAddress = "Χωρίς διαθέσιμη διεύθυνση");
      }
    } catch (e) {
      print(e.toString());
      setState(() => _currentAddress = "Αδυναμία ανάγνωσης διεύθυνσης");
    } finally {
      print("tofnaly trexei");
      _isGeocoding = false;
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _goToMyLocation() async {
    if (_gpsLatLng == null) {
      final pos = await Geolocator.getCurrentPosition();
      _gpsLatLng = LatLng(pos.latitude, pos.longitude);
    }
    _cameraTarget = _gpsLatLng;

    final map = await _controller.future;

    await map.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _cameraTarget!, zoom: 16),
      ),
    );

    await _reverseGeocodeAt(_cameraTarget!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: Column(
          children: [
            Text(
              _currentAddressLine1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15,fontWeight: FontWeight.bold),
            ),
            Text(
              _currentAddressLine2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: AlignmentGeometry.topCenter,
              end: AlignmentGeometry.bottomCenter,
              colors: [
                Color(0xFFFFFFFF), // λευκό
                Color(0x88FFFFFF),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  // style: _mapStyle,
                  initialCameraPosition: const CameraPosition(
                    target: _athens,
                    zoom: 12,
                  ),
                  onMapCreated: (controller) async =>
                      _controller.complete(controller),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  compassEnabled: false,
                  zoomControlsEnabled: false,
                  onCameraMove: (pos) => _cameraTarget = pos.target,
                  onCameraIdle: () {
                    print("camera idle");
                    if (_cameraTarget != null) {
                      _reverseGeocodeAt(_cameraTarget!);
                    }
                  },
                ),
                IgnorePointer(
                  child: Center(
                    child: Icon(
                      Icons.location_pin,
                      size: 42,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: FloatingActionButton(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blueAccent,
                    shape: const CircleBorder(),
                    elevation: 6,
                    onPressed: _goToMyLocation,
                    child: const Icon(Icons.my_location, size: 28),
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: () {
              context.read<PhoneAuthNotifier>().signOut();
            },
            child: Text("LogOut"),
          ),
        ],
      ),
    );
  }
}
