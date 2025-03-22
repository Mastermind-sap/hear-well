import 'package:echo_aid/core/utils/extensions/list_extension.dart';
import 'package:echo_aid/features/auth/login/widgets/login_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LoginPage extends StatefulWidget {
  //route
  static const String routeName = "/LoginPage";

  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  LoginFormState loginFormState = LoginFormState();

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    double width = size.width;
    double height = size.height;
    double avatarRadius = width * 0.15;
    double gap = height * 0.05;
    double messageFieldWidth = 0.85;

    // return PopScope(
    //   canPop: false,
    //   onPopInvoked: (didPop) async {
    //     if (didPop) {
    //       return;
    //     }
    //     final bool shouldPop = await showExitWarning(context);
    //     if (shouldPop) {
    //       SystemNavigator.pop();
    //     }
    //   },
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
                    child: const LoginForm()),
                ].separate(gap),
              ),
            ),
          ),
            ),
      );
  }
}