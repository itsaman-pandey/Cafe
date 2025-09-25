import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cafe/constants/api_constants.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';

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

        // ✅ If admin, call API again with fixed credentials
        if (role == "admin") {
          final adminBody = {
            "grant_type": "password",
            "username": "rahul@gmail.com",
            "password": "1234",
            "scope": "",
            "client_id": "string",
            "client_secret": "your_secret",
          };

          final adminResponse = await http.post(
            url,
            headers: {"Content-Type": "application/x-www-form-urlencoded"},
            body: adminBody,
          );

          if (adminResponse.statusCode == 200) {
            final adminData = jsonDecode(adminResponse.body);
            await prefs.setString(
              "access_token_for_api",
              adminData["access_token"],
            );
          } else {
            // Optionally handle failed admin token retrieval
            debugPrint("Failed to get admin token: ${adminResponse.body}");
          }
        }

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
  // for ImageFilter

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // lets background go behind AppBar
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset("assets/img1.webp", fit: BoxFit.cover),
          ),

          // Dark overlay
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.4)),
          ),

          // Glassy login card
          Center(
            child: SingleChildScrollView(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2), // semi-transparent
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Email TextField
                        Text(
                          "Login",
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                        SizedBox(height: 20),
                        TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(
                              Icons.email,
                              color: Colors.white,
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.25),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            labelStyle: const TextStyle(color: Colors.white),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 16),

                        // Password TextField
                        TextField(
                          controller: passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(
                              Icons.lock,
                              color: Colors.white,
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.25),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            labelStyle: const TextStyle(color: Colors.white),
                          ),
                          obscureText: true,
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 12),

                        // Forgot Password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ForgotPasswordScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Login Button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              181,
                              221,
                              161,
                              140,
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 32,
                            ),
                          ),
                          onPressed: isLoading ? null : login,
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Login',
                                  style: TextStyle(fontSize: 18),
                                ),
                        ),
                        const SizedBox(height: 16),

                        // Sign Up
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignupScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            "Don't have an account? Sign Up",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
