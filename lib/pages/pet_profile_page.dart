import 'package:flutter/material.dart';
import 'package:pawtrack/models/pet.dart';
import 'package:pawtrack/pages/edit_pet_details_page.dart';
import 'package:pawtrack/pages/recent_locations_page.dart';
import 'package:pawtrack/pages/heart_rate_page.dart';
import 'package:pawtrack/pages/activity_tracker_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PetProfilePage extends StatefulWidget {
  final Pet pet;

  const PetProfilePage({super.key, required this.pet});

  @override
  State<PetProfilePage> createState() => _PetProfilePageState();
}

class _PetProfilePageState extends State<PetProfilePage> {
  late Pet _pet;
  final GlobalKey _imageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _pet = widget.pet;
  }

  void _updatePet(Pet updatedPet) {
    setState(() {
      _pet = updatedPet;
      if (_pet.imageUrl != null) {
        CachedNetworkImage.evictFromCache(_pet.imageUrl!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: false,
            pinned: true,
            expandedHeight: 200.0,
            backgroundColor: Theme.of(context).colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 56),
                    CircleAvatar(
                      key: _imageKey,
                      radius: 60,
                      backgroundColor: Colors.white,
                      child: _pet.imageUrl != null
                          ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: _pet.imageUrl!,
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                          placeholder: (context, url) => const CircularProgressIndicator(),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.pets,
                            size: 60,
                            color: Colors.grey,
                          ),
                        ),
                      )
                          : const Icon(
                        Icons.pets,
                        size: 60,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${_pet.name}'s Profile",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        shadows: const [
                          Shadow(
                            color: Colors.black45,
                            offset: Offset(1, 1),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () async {
                  final updatedPet = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditPetDetailsPage(pet: _pet),
                    ),
                  );
                  if (updatedPet != null) {
                    _updatePet(updatedPet);
                  }
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Theme.of(context).colorScheme.secondary,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Details',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(context, 'Name', _pet.name),
                          _buildDetailRow(context, 'Bluetooth Device', _pet.bluetoothDeviceId),
                          if (_pet.age != null)
                            _buildDetailRow(context, 'Age', '${_pet.age} years'),
                          if (_pet.breed != null)
                            _buildDetailRow(context, 'Breed', _pet.breed!),
                          if (_pet.weight != null)
                            _buildDetailRow(context, 'Weight', '${_pet.weight} kg'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 0),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 3 / 2,
                    children: [
                      _buildActionButton(
                        context,
                        'Recent Locations',
                        Icons.location_on,
                        Theme.of(context).colorScheme.primary,
                            () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RecentLocationsPage(petId: _pet.id),
                          ),
                        ),
                      ),
                      _buildActionButton(
                        context,
                        'Heart Rate',
                        Icons.favorite,
                        Theme.of(context).colorScheme.primary,
                            () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HeartRatePage(petName: _pet.name),
                          ),
                        ),
                      ),
                      _buildActionButton(
                        context,
                        'Activity',
                        Icons.pets,
                        Theme.of(context).colorScheme.primary,
                            () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ActivityTrackerPage(petId: _pet.id),
                          ),
                        ),
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

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.inversePrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w400,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context,
      String label,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 24),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        elevation: 4,
      ),
    );
  }
}