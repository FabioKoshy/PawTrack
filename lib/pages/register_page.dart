import 'package:flutter/material.dart';
import 'package:pawtrack/components/custom_button.dart';
import 'package:pawtrack/components/custom_text_field.dart';



class RegisterPage extends StatelessWidget {

  final void Function()? onTap;




  RegisterPage({super.key,
    required this.onTap});

  // controllers for text fields
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  // register logic
  void register(){}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
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

              const SizedBox(height: 50),

              // username field
              CustomTextField(
                hintText: "Username",
                obscureText: false,
                controller: usernameController,
              ),

              const SizedBox(height: 10),

              // email field
              CustomTextField(
                hintText: "Email",
                obscureText: false,
                controller: emailController,
              ),

              const SizedBox(height: 10),

              // password field
              CustomTextField(
                hintText: "Password",
                obscureText: true,
                controller: passwordController,
              ),

              const SizedBox(height: 10),

              // confirm password field
              CustomTextField(
                hintText: "Confirm Password",
                obscureText: true,
                controller: confirmPasswordController,
              ),

              const SizedBox(height: 10),

              // forgot pass
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text("Forgot Password?",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary,),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // register button
              CustomButton(
                text: "Register",
                onTap: register,
              ),

              const SizedBox(height: 25),

              // dont have an account Login button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Already have an account?",
                    style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary,),),
                  GestureDetector(
                      onTap: onTap,
                      child: const Text(" Login Here!", style: TextStyle(fontWeight: FontWeight.bold,))),
                ],
              )

            ],


          ),
        ),
      ),
    );
  }
}
