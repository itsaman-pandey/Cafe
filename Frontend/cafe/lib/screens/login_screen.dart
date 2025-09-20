import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cafe/constants/api_constants.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> login() async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse(ApiConstants.login);
    final body = {
      "grant_type": "password",
      "username": emailController.text.trim(),
      "password": passwordController.text.trim(),
      "scope": "",
      "client_id": "string",
      "client_secret": "your_secret",
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Save token in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("access_token", data["access_token"]);

        // Decode JWT to get user info
        final payload = jsonDecode(
          ascii.decode(
            base64Url.decode(
              base64Url.normalize(data["access_token"].split(".")[1]),
            ),
          ),
        );

        final role = payload["role"] ?? "client";
        final name = payload["name"] ?? payload["username"] ?? "User";
        final email = payload["email"] ?? emailController.text.trim();
        final address = payload["address"] ?? "No address";

        // Save user details in SharedPreferences
        await prefs.setString("user_role", role);
        await prefs.setString("user_name", name);
        await prefs.setString("user_email", email);
        await prefs.setString("user_address", address);

        // Navigate to HomeScreen with role
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(isLoggedIn: true, userRole: role),
          ),
        );
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${data['detail'] ?? 'Unknown error'}"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Exception: $e")));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Future<void> login() async {
  //   setState(() {
  //     isLoading = true;
  //   });

  //   final url = Uri.parse(ApiConstants.login);
  //   final body = {
  //     "grant_type": "password",
  //     "username": emailController.text.trim(),
  //     "password": passwordController.text.trim(),
  //     "scope": "",
  //     "client_id": "string",
  //     "client_secret": "your_secret",
  //   };

  //   try {
  //     final response = await http.post(
  //       url,
  //       headers: {"Content-Type": "application/x-www-form-urlencoded"},
  //       body: body,
  //     );

  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);

  //       // Save token in SharedPreferences
  //       final prefs = await SharedPreferences.getInstance();
  //       await prefs.setString("access_token", data["access_token"]);

  //       // Decode JWT to get role
  //       final payload = jsonDecode(
  //         ascii.decode(
  //           base64Url.decode(
  //             base64Url.normalize(data["access_token"].split(".")[1]),
  //           ),
  //         ),
  //       );
  //       final role = payload["role"] ?? "client";
  //       await prefs.setString("user_role", role);

  //       // Navigate to HomeScreen with role
  //       Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(
  //           builder: (context) => HomeScreen(isLoggedIn: true, userRole: role),
  //         ),
  //       );
  //     } else {
  //       final data = jsonDecode(response.body);
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text("Error: ${data['detail'] ?? 'Unknown error'}"),
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text("Exception: $e")));
  //   } finally {
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login'), backgroundColor: Colors.brown),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ForgotPasswordScreen(),
                    ),
                  );
                },
                child: const Text("Forgot Password?"),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 32,
                ),
              ),
              onPressed: isLoading ? null : login,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Login', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SignupScreen()),
                );
              },
              child: const Text("Don't have an account? Sign Up"),
            ),
          ],
        ),
      ),
    );
  }
}
