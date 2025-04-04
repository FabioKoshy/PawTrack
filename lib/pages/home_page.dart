import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pawtrack/components/square_button.dart';
import 'package:pawtrack/pages/add_pet_page.dart';
import 'package:pawtrack/pages/heart_rate_page.dart';
import 'package:pawtrack/pages/location_tracker_page.dart';
import 'package:pawtrack/pages/notifications_page.dart';
import 'package:pawtrack/pages/pet_profile_page.dart';
import 'package:pawtrack/pages/settings_page.dart';
import 'package:pawtrack/services/auth_service.dart';
import 'package:pawtrack/services/pet_service.dart';
import 'package:pawtrack/utils/constants.dart';
import 'package:pawtrack/models/pet.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PetService _petService = PetService();
  String? selectedButton;

  void openPetSelection(BuildContext context, String buttonType) {
    setState(() {
      selectedButton = buttonType;
    });

    showModalBottomSheet(
      context: context,
      isDismissible: true,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
        side: BorderSide(color: Colors.pink.shade800, width: 3),
      ),
      builder: (context) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(_petService.userId)
              .collection('pets')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No pets available. Add a pet first."));
            }
            final pets = snapshot.data!.docs.map((doc) => Pet.fromFirestore(doc)).toList();
            return ListView.builder(
              shrinkWrap: true,
              itemCount: pets.length,
              itemBuilder: (context, index) {
                final pet = pets[index];
                return ListTile(
                  title: Text(pet.name),
                  onTap: () {
                    Navigator.pop(context);
                    if (buttonType == "Heart") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HeartRatePage(
                            petName: pet.name,
                            petId: pet.id,
                          ),
                        ),
                      );
                    } else if (buttonType == "Location") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LocationTrackerPage(petId: pet.id),
                        ),
                      );
                    }
                  },
                );
              },
            );
          },
        );
      },
    ).whenComplete(() => setState(() => selectedButton = null));
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser!;
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    String logoPath = isDarkMode
        ? 'assets/images/paw_heart_dark_logo.svg'
        : 'assets/images/paw_heart_light_logo.svg';
    Color iconAndTitleColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          Container(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.notifications, color: iconAndTitleColor),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NotificationsPage()),
                        );
                      },
                    ),
                    Row(
                      children: [
                        SvgPicture.asset(logoPath, height: 40),
                        const SizedBox(width: 10),
                        Text(
                          'PawTrack',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: iconAndTitleColor,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.settings, color: iconAndTitleColor),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsPage()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Divider(color: isDarkMode ? Colors.white : Colors.grey.shade400, thickness: 1.5),
          Expanded(
            child: Padding(
              padding: AppPadding.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Welcome, ${user.displayName ?? user.email}!',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 20),
                  // Center-aligned Heart and Location buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Use Expanded with flex to make both buttons the same size
                      Expanded(
                        flex: 1,
                        child: SquareButton(
                          text: "Heart",
                          icon: Icons.favorite,
                          color: Theme.of(context).colorScheme.primary,
                          isSelected: selectedButton == "Heart",
                          onTap: () => openPetSelection(context, "Heart"),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: SquareButton(
                          text: "Location",
                          icon: Icons.location_on,
                          color: Theme.of(context).colorScheme.secondary,
                          isSelected: selectedButton == "Location",
                          onTap: () => openPetSelection(context, "Location"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(_petService.userId)
                          .collection('pets')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text("No pets added yet."));
                        }
                        final pets = snapshot.data!.docs
                            .map((doc) => Pet.fromFirestore(doc))
                            .toList();
                        return ListView.builder(
                          itemCount: pets.length,
                          itemBuilder: (context, index) {
                            final pet = pets[index];
                            return ListTile(
                              leading: const Icon(Icons.pets),
                              title: Text(pet.name),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PetProfilePage(pet: pet),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink.shade300,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddPetPage()),
                      );
                    },
                    child: const Text("Manage Pets"),
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