import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';


class LocationTrackerPage extends StatefulWidget {
  const LocationTrackerPage({super.key});

  @override
  _LocationTrackerPageState createState() => _LocationTrackerPageState();
}

class _LocationTrackerPageState extends State<LocationTrackerPage> {
  Position? _currentPosition;
  Position? _petPosition;
  double _maxDistance = 100.0; // Maximum allowed distance in meters
  double? _distanceFromOrigin;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _startLocationTracking();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = position;
      _setPetPosition();
    });
  }

  void _startLocationTracking() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
        setState(() {
          _currentPosition = position;
          _setPetPosition();
        });

        if (_petPosition != null) {
          double distance = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            _petPosition!.latitude,
            _petPosition!.longitude,
          );

          setState(() {
            _distanceFromOrigin = distance;
          });
        }
      },
    );
  }

  void _setPetPosition() {
    if (_currentPosition != null) {
      double offsetLatitude = 0.0018; // Roughly 200m difference
      double offsetLongitude = 0.0018;

      setState(() {
        _petPosition = Position(
          latitude: _currentPosition!.latitude + offsetLatitude,
          longitude: _currentPosition!.longitude + offsetLongitude,
          timestamp: DateTime.now(),
          accuracy: 5.0,
          altitude: 0.0,
          heading: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );

        _distanceFromOrigin = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          _petPosition!.latitude,
          _petPosition!.longitude,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Location Tracker"),
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_currentPosition != null)
              Text(
                "Your Location: (${_currentPosition!.latitude}, ${_currentPosition!.longitude})",
              ),
            if (_petPosition != null)
              Text(
                "Pet's Location: (${_petPosition!.latitude}, ${_petPosition!.longitude})",
              ),
            if (_distanceFromOrigin != null)
              Text(
                "Pet is $_distanceFromOrigin meters away",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            if (_distanceFromOrigin != null && _distanceFromOrigin! > _maxDistance)
              const Text(
                "Your pet is out of the allowed range",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }
}