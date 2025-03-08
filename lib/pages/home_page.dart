import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pawtrack/components/square_button.dart';
import 'package:pawtrack/pages/add_pet_page.dart';
import 'package:pawtrack/pages/heart_rate_page.dart';
import 'package:pawtrack/pages/location_tracker_page.dart';
import 'package:pawtrack/pages/activity_tracker_page.dart';
import 'package:pawtrack/pages/notifications_page.dart';
import 'package:pawtrack/pages/settings_page.dart';
import 'package:pawtrack/services/auth_service.dart';
import 'package:pawtrack/utils/constants.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> pets = [];
  String? selectedButton;

  void addPet(String petName) {
    setState(() {
      pets.add(petName);
    });
  }

  void openPetSelection(BuildContext context, String buttonType, Widget page) {
    setState(() {
      selectedButton = buttonType;
    });

    if (pets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No pets available. Add a pet first.")),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isDismissible: true,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
        side: BorderSide(color: Colors.pink.shade800, width: 3), // Added border
      ),
      builder: (context) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Navigator.pop(context);
            setState(() => selectedButton = null);
          },
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: pets.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(
                  pets[index],
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  if (page is HeartRatePage) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => HeartRatePage(petName: pets[index])),
                    );
                  } else if (page is LocationTrackerPage) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LocationTrackerPage()),
                    );
                  } else if (page is ActivityTrackerPage) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ActivityTrackerPage()),
                    );
                  }
                },
              );
            },
          ),
        );
      },
    ).whenComplete(() {
      setState(() => selectedButton = null);
    });
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
                      mainAxisAlignment: MainAxisAlignment.center,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: SquareButton(
                          text: "Heart",
                          icon: Icons.favorite,
                          color: Theme.of(context).colorScheme.primary,
                          isSelected: selectedButton == "Heart",
                          onTap: () => openPetSelection(context, "Heart", HeartRatePage(petName: "")),
                        ),
                      ),
                      Expanded(
                        child: SquareButton(
                          text: "Location",
                          icon: Icons.location_on,
                          color: Theme.of(context).colorScheme.secondary,
                          isSelected: selectedButton == "Location",
                          onTap: () =>
                              openPetSelection(context, "Location", const LocationTrackerPage()),
                        ),
                      ),
                      Expanded(
                        child: SquareButton(
                          text: "Activity",
                          icon: Icons.pets,
                          color: Theme.of(context).colorScheme.primary,
                          isSelected: selectedButton == "Activity",
                          onTap: () =>
                              openPetSelection(context, "Activity", const ActivityTrackerPage()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border:
                        Border.all(color: Theme.of(context).colorScheme.secondary, width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: pets.isEmpty
                          ? const Center(child: Text("No pets added yet. Click 'Add Pet' to start!"))
                          : ListView.builder(
                        itemCount: pets.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Text(
                              pets[index],
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink.shade300,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final petName = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddPetPage()),
                      );
                      if (petName != null && petName is String) addPet(petName);
                    },
                    child: const Text("Add Pet"),
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