import 'package:flutter/material.dart';
import 'package:pawtrack/components/custom_button.dart';
import 'package:pawtrack/components/custom_text_field.dart';



class LoginPage extends StatelessWidget {

  // controllers for text fields
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // login logic
  void login(){}

  LoginPage({super.key});

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

              // login button
              CustomButton(
                text: "Login",
                onTap: login,
              ),

              const SizedBox(height: 25),

              // dont have an account signup button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account?",
                    style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary,),),
                  GestureDetector(
                      onTap: (){},
                      child: const Text(" Register Here!", style: TextStyle(fontWeight: FontWeight.bold,))),
                ],
              )

            ],


          ),
        ),
      ),
    );
  }
}
