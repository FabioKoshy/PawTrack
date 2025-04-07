import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pawtrack/services/pet_service.dart';
import 'package:pawtrack/models/pet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pawtrack/pages/recent_locations_page.dart';
import 'package:pawtrack/pages/gps_setup_page.dart';
import 'package:pawtrack/components/custom_button.dart';
import 'package:pawtrack/services/geofence_service.dart';

class LocationTrackerPage extends StatefulWidget {
  final String petId;
  const LocationTrackerPage({super.key, required this.petId});

  @override
  State<LocationTrackerPage> createState() => _LocationTrackerPageState();
}

class _LocationTrackerPageState extends State<LocationTrackerPage> {
  final PetService _petService = PetService();
  Map<String, dynamic>? gpsData;
  bool isLoadingPetData = true;
  bool isLoadingGpsData = true;
  bool isLoadingUserLocation = true;
  Position? userPosition;
  double? distanceToPet;
  Pet? pet;
  LatLng? geofenceCenter;
  double geofenceRadius = 1000.0; // Default radius in meters (1 km)
  bool geofenceEnabled = false;
  MapController mapController = MapController();
  String? lastTimestamp;
  DateTime? lastLoggedTime;
  late GeofenceService _geofenceService;

  @override
  void initState() {
    super.initState();
    _geofenceService = GeofenceService();
    // Fetch pet data first
    _fetchPetData();
    _getUserLocation();
    _loadGeofenceSettings();
  }

  @override
  void dispose() {
    mapController.dispose();
    _geofenceService.stop();
    super.dispose();
  }

  Future<void> _fetchPetData() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(_petService.userId)
        .collection('pets')
        .doc(widget.petId)
        .get();

    if (snapshot.exists) {
      setState(() {
        pet = Pet.fromFirestore(snapshot);
        isLoadingPetData = false;
      });

      // Only fetch GPS data if GPS is calibrated
      if (pet != null && pet!.isGpsCalibrated) {
        _fetchGpsData();
      }

      _geofenceService.initialize(widget.petId, pet!.name);
    } else {
      setState(() {
        isLoadingPetData = false;
      });
    }
  }

  void _fetchGpsData() {
    final petGpsRef = FirebaseDatabase.instance.ref('gpslocation');
    petGpsRef.onValue.listen((event) async {
      if (event.snapshot.exists) {
        final newGpsData = Map<String, dynamic>.from(event.snapshot.value as Map);
        final petLat = newGpsData['stats']?['latitude']?.toDouble();
        final petLon = newGpsData['stats']?['longitude']?.toDouble();
        final timestamp = newGpsData['stats']?['timestamp']?.toString();

        if (timestamp != null && timestamp != lastTimestamp && petLat != null && petLon != null) {
          final currentTime = DateTime.now();
          if (lastLoggedTime == null || currentTime.difference(lastLoggedTime!).inSeconds >= 300) {
            setState(() {
              gpsData = newGpsData;
              isLoadingGpsData = false;
              _calculateDistance();
            });

            await _saveLocationToFirestore(petLat, petLon, timestamp);
            lastTimestamp = timestamp;
            lastLoggedTime = currentTime;
          }
        } else {
          setState(() {
            gpsData = newGpsData;
            isLoadingGpsData = false;
            _calculateDistance();
          });
        }
      } else {
        setState(() {
          gpsData = null;
          isLoadingGpsData = false;
        });
      }
    }, onError: (error) {
      setState(() {
        isLoadingGpsData = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching GPS data: $error')),
      );
    });
  }

  Future<void> _saveLocationToFirestore(double latitude, double longitude, String timestamp) async {
    try {
      final userId = _petService.userId;
      final locationRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('pets')
          .doc(widget.petId)
          .collection('locations');

      await locationRef.add({
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final querySnapshot = await locationRef
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      if (querySnapshot.docs.length > 5) {
        final oldestDocs = await locationRef
            .orderBy('createdAt', descending: true)
            .get();
        for (var i = 5; i < oldestDocs.docs.length; i++) {
          await oldestDocs.docs[i].reference.delete();
        }
      }
    } catch (e) {
      print("Error saving location to Firestore for pet ${widget.petId}: $e");
    }
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled. Please enable them in settings.')),
      );
      setState(() {
        userPosition = null;
        isLoadingUserLocation = false;
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied.')),
        );
        setState(() {
          userPosition = null;
          isLoadingUserLocation = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permissions are permanently denied.')),
      );
      setState(() {
        userPosition = null;
        isLoadingUserLocation = false;
      });
      return;
    }

    try {
      userPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        isLoadingUserLocation = false;
        _calculateDistance();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting user location: $e')),
      );
      setState(() {
        userPosition = null;
        isLoadingUserLocation = false;
      });
    }
  }

  void _calculateDistance() {
    if (userPosition == null || gpsData == null) {
      distanceToPet = null;
      return;
    }

    final petLat = gpsData!['stats']?['latitude']?.toDouble();
    final petLon = gpsData!['stats']?['longitude']?.toDouble();

    if (petLat == null || petLon == null) {
      distanceToPet = null;
      return;
    }

    try {
      distanceToPet = Geolocator.distanceBetween(
        userPosition!.latitude,
        userPosition!.longitude,
        petLat,
        petLon,
      );
    } catch (e) {
      distanceToPet = null;
    }
    setState(() {});
  }

  Future<void> _loadGeofenceSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      geofenceEnabled = prefs.getBool('geofenceEnabled_${widget.petId}') ?? false;
      final centerLat = prefs.getDouble('geofenceCenterLat_${widget.petId}');
      final centerLon = prefs.getDouble('geofenceCenterLon_${widget.petId}');
      if (centerLat != null && centerLon != null) {
        geofenceCenter = LatLng(centerLat, centerLon);
      }
      geofenceRadius = prefs.getDouble('geofenceRadius_${widget.petId}') ?? 1000.0;
    });
  }

  Future<void> _saveGeofenceSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('geofenceEnabled_${widget.petId}', geofenceEnabled);
    if (geofenceCenter != null) {
      await prefs.setDouble('geofenceCenterLat_${widget.petId}', geofenceCenter!.latitude);
      await prefs.setDouble('geofenceCenterLon_${widget.petId}', geofenceCenter!.longitude);
    } else {
      await prefs.remove('geofenceCenterLat_${widget.petId}');
      await prefs.remove('geofenceCenterLon_${widget.petId}');
    }
    await prefs.setDouble('geofenceRadius_${widget.petId}', geofenceRadius);
  }

  Future<void> _setGeofence() async {
    final radius = await showDialog<double>(
      context: context,
      builder: (context) {
        double tempRadius = geofenceRadius;
        return AlertDialog(
          title: const Text("Set Geofence Radius"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Enter the radius (in meters) for the geofence:"),
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Radius (meters)"),
                onChanged: (value) {
                  tempRadius = double.tryParse(value) ?? geofenceRadius;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, tempRadius),
              child: const Text("Set"),
            ),
          ],
        );
      },
    );

    if (radius != null) {
      setState(() {
        geofenceRadius = radius;
      });

      if (gpsData != null) {
        final petLat = gpsData!['stats']?['latitude']?.toDouble();
        final petLon = gpsData!['stats']?['longitude']?.toDouble();
        if (petLat != null && petLon != null) {
          mapController.move(LatLng(petLat, petLon), 16.0);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tap on the map to set the geofence center")),
      );
    }
  }

  void _onMapTap(LatLng tappedPoint) {
    if (geofenceRadius > 0 && !geofenceEnabled) {
      setState(() {
        geofenceCenter = tappedPoint;
        geofenceEnabled = true;
      });
      _saveGeofenceSettings();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Geofence set with radius $geofenceRadius meters at ${tappedPoint.latitude}, ${tappedPoint.longitude}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pet != null ? "${pet!.name}'s Location" : "Location Tracker"),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecentLocationsPage(petId: widget.petId),
                ),
              );
            },
            tooltip: "View Recent Locations",
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: isLoadingPetData
              ? const Center(child: CircularProgressIndicator(value: null, semanticsLabel: "Loading pet data..."))
              : pet == null
              ? const Center(child: Text("Pet data not found"))
              : !pet!.isGpsCalibrated
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.gps_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  "GPS not calibrated",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "The GPS sensor needs to be calibrated before location tracking is available.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: "Calibrate GPS",
                  icon: Icons.settings,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GpsSetupPage(pet: pet!),
                      ),
                    ).then((_) {
                      // Refresh pet data when returning from GPS setup
                      _fetchPetData();
                    });
                  },
                ),
              ],
            ),
          )
              : isLoadingGpsData
              ? const Center(child: CircularProgressIndicator(value: null, semanticsLabel: "Loading GPS data..."))
              : gpsData == null
              ? const Center(child: Text("No GPS data available"))
              : Column(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  margin: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildMap(),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Distance to Pet",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                isLoadingUserLocation
                                    ? const CircularProgressIndicator(value: null, semanticsLabel: "Calculating distance...")
                                    : Text(
                                  distanceToPet != null
                                      ? "${(distanceToPet! / 1000).toStringAsFixed(2)} km"
                                      : "Unable to calculate",
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: distanceToPet != null
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: CustomButton(
                                text: "Set Geofence",
                                icon: Icons.fence,
                                color: Theme.of(context).colorScheme.primary,
                                onTap: _setGeofence,
                              ),
                            ),
                          ),
                          if (geofenceEnabled)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: CustomButton(
                                  text: "Disable Geofence",
                                  icon: Icons.cancel,
                                  color: Colors.grey,
                                  onTap: () {
                                    setState(() {
                                      geofenceEnabled = false;
                                      geofenceCenter = null;
                                    });
                                    _saveGeofenceSettings();
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (geofenceEnabled)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Text(
                            "Geofence set with radius ${geofenceRadius.toStringAsFixed(0)} meters\n(Note: Geofence notifications work only when the app is open or in the background)",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMap() {
    final petLat = gpsData!['stats']?['latitude']?.toDouble();
    final petLon = gpsData!['stats']?['longitude']?.toDouble();

    if (petLat == null || petLon == null) {
      return const Center(child: Text("Location data unavailable"));
    }

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: LatLng(petLat, petLon),
        initialZoom: 13.0,
        onTap: (tapPosition, point) => _onMapTap(point),
      ),
      children: [
        TileLayer(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: LatLng(petLat, petLon),
              child: const Icon(
                Icons.pets,
                color: Colors.red,
                size: 40,
              ),
            ),
            if (userPosition != null)
              Marker(
                point: LatLng(userPosition!.latitude, userPosition!.longitude),
                child: const Icon(
                  Icons.person_pin_circle,
                  color: Colors.blue,
                  size: 40,
                ),
              ),
          ],
        ),
        if (geofenceEnabled && geofenceCenter != null)
          CircleLayer(
            circles: [
              CircleMarker(
                point: geofenceCenter!,
                radius: geofenceRadius,
                useRadiusInMeter: true,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                borderStrokeWidth: 2,
                borderColor: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
      ],
    );
  }
}