import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {

  // controller for text fields
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //logo
            // ToDO Add a proper logo
            Icon(
                Icons.person,
                size: 80,
                color: Theme.of(context).colorScheme.inversePrimary,
            ),

            const SizedBox(height: 25),

            // app name
            Text(
              'PawTrack',
              style: TextStyle(
                fontSize: 20
                ),
            ),

          ],
          



          // email field


          // password field

          // forgot pass

          // login button

          // dont have an account signup button

        ),
      ),
    );
  }
}
