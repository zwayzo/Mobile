import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  Future<void> signInWithGoogle(BuildContext context) async {
  final provider = GoogleAuthProvider();

  await FirebaseAuth.instance.signInWithPopup(provider);

  Navigator.pushReplacementNamed(context, '/home');
}

  Widget HomePage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Diary"),
      ),
      body: const Center(
        child: Text(
          "Welcome to your diary 📖",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Text(
              "Login Page",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () => signInWithGoogle(context),
              child: const Text("Sign in with Google"),
            ),

            ElevatedButton(
              onPressed: () {
                // TODO: GitHub login
              },
              child: const Text("Sign in with GitHub"),
            ),
          ],
        ),
      ),
    );
  }
}