import 'package:flutter/material.dart';
import 'package:touchandlist/constants/routes.dart';
import 'package:touchandlist/services/auth/auth_service.dart';

class VeryfyEmailView extends StatefulWidget {
  const VeryfyEmailView({Key? key}) : super(key: key);

  @override
  State<VeryfyEmailView> createState() => _VeryfyEmailViewState();
}

class _VeryfyEmailViewState extends State<VeryfyEmailView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify email"),
      ),
      body: Column(
        children: [
          const Text(
              "We've sent you an email verification. Please open it to verify your account."),
          const Text(
              "If you haven't recivied a verification email yet, please press the button below"),
          TextButton(
            onPressed: () async {
              await AuthService.firebase().sendEmailVerification();
            },
            child: const Text("Send email verification"),
          ),
          TextButton(
            onPressed: () async {
              await AuthService.firebase().logOut();
              Navigator.of(context).pushNamedAndRemoveUntil(
                loginRoute,
                (route) => false,
              );
            },
            child: const Text("Restart"),
          )
        ],
      ),
    );
  }
}