import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pawtrack/components/custom_button.dart';
import 'package:pawtrack/auth/access_mode.dart';
import 'package:provider/provider.dart';
import 'package:pawtrack/theme/theme_provider.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  void navigateToAccessMode(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AccessMode()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SvgPicture.asset(
                Theme.of(context).brightness == Brightness.dark
                    ? 'assets/images/paw_heart_dark_logo.svg'
                    : 'assets/images/paw_heart_light_logo.svg',
                height: 120,
                width: 120,
              ),
              Text(
                'PawTrack',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                'Where they roam, hearts rhythm, paws known, worries flown',
                style: Theme.of(context).textTheme.bodyMedium, // Use theme default (black in light, white in dark)
                textAlign: TextAlign.center,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Light",
                    style: Theme.of(context).textTheme.bodyMedium, // Use theme default (black in light, white in dark)
                  ),
                  Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.toggleTheme();
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                  Text(
                    "Dark",
                    style: Theme.of(context).textTheme.bodyMedium, // Use theme default (black in light, white in dark)
                  ),
                ],
              ),
              CustomButton(
                text: "Get Started",
                onTap: () => navigateToAccessMode(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}