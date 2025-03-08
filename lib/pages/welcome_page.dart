import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pawtrack/components/custom_button.dart';
import 'package:pawtrack/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  Future<void> _markWelcomeSeenAndNavigate(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenWelcome', true);
    Navigator.pushReplacementNamed(context, AppRoutes.access);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: AppPadding.pagePadding,
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
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              CustomButton(
                text: "Get Started",
                onTap: () => _markWelcomeSeenAndNavigate(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}