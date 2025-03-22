import 'package:echo_aid/core/utils/extensions/list_extension.dart';
import 'package:echo_aid/features/auth/signup/widgets/signup_form.dart';
import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  SignUpFormState loginFormState = SignUpFormState();

  @override
  Widget build(BuildContext context) {
    //screen height and width
    Size size = MediaQuery.of(context).size;
    double width = size.width;
    double height = size.height;
    //size constants
    double avatarRadius = width * 0.15;
    double gap = height * 0.05;
    double messageFieldWidth = 0.85;

      return SafeArea(
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    radius: avatarRadius,
                    // child: Image.asset(Assets.efficacyUserLogoImagePath),
                    child: const Icon(Icons.person, size: 100),
                  ),
                  
                  Container(
                    padding: EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                            colors: [Colors.purple, Colors.blue],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    ),
                    child: const SignUpForm()),
                ].separate(gap),
              ),
            ),
          ),
            ),
      );
  }
}