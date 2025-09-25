// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:cafe/constants/api_constants.dart';
// import 'package:http/http.dart' as http;
// import 'login_screen.dart';
// import 'home_screen.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart';
// import 'dart:ui'; // for ImageFilter

// class SignupScreen extends StatefulWidget {
//   const SignupScreen({super.key});

//   @override
//   State<SignupScreen> createState() => _SignupScreenState();
// }

// class _SignupScreenState extends State<SignupScreen> {
//   final nameController = TextEditingController();
//   final emailController = TextEditingController();
//   final phoneController = TextEditingController();
//   final addressController = TextEditingController();
//   final passwordController = TextEditingController();
//   final confirmPasswordController = TextEditingController();
//   String selectedRole = "client"; // default role

//   bool isLoading = false;
//   Future<void> fetchCurrentAddress() async {
//     bool serviceEnabled;
//     LocationPermission permission;

//     // Check if location service is enabled
//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Location services are disabled.')),
//       );
//       return;
//     }

//     // Check permission
//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Location permissions are denied')),
//         );
//         return;
//       }
//     }

//     if (permission == LocationPermission.deniedForever) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Location permissions are permanently denied'),
//         ),
//       );
//       return;
//     }

//     // Get current position
//     Position position = await Geolocator.getCurrentPosition(
//       desiredAccuracy: LocationAccuracy.high,
//     );

//     // Convert coordinates to address
//     List<Placemark> placemarks = await placemarkFromCoordinates(
//       position.latitude,
//       position.longitude,
//     );
//     if (placemarks.isNotEmpty) {
//       Placemark place = placemarks.first;
//       String address =
//           "${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}";
//       setState(() {
//         addressController.text = address;
//       });
//     }
//   }

//   Future<void> signup() async {
//     if (passwordController.text != confirmPasswordController.text) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
//       return;
//     }

//     setState(() {
//       isLoading = true;
//     });

//     final url = Uri.parse(ApiConstants.signup);
//     final body = jsonEncode({
//       "name": nameController.text.trim(),
//       "email": emailController.text.trim(),
//       "phone": phoneController.text.trim(),
//       "address": addressController.text.trim(),
//       "role": selectedRole,
//       "password": passwordController.text.trim(),
//     });

//     try {
//       final response = await http.post(
//         url,
//         headers: {"Content-Type": "application/json"},
//         body: body,
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(const SnackBar(content: Text("Signup successful!")));

//         // Navigate to HomeScreen after signup
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => const HomeScreen()),
//         );
//       } else {
//         final data = jsonDecode(response.body);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Error: ${data['detail'] ?? 'Unknown error'}"),
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Exception: $e")));
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         title: const Text("Sign Up"),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//       ),
//       body: Stack(
//         children: [
//           // Background image
//           Positioned.fill(
//             child: Image.asset("assets/img1.webp", fit: BoxFit.cover),
//           ),

//           // Dark overlay
//           Positioned.fill(
//             child: Container(color: Colors.black.withOpacity(0.4)),
//           ),

//           // Glassy form card
//           Center(
//             child: SingleChildScrollView(
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(20),
//                 child: BackdropFilter(
//                   filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
//                   child: Container(
//                     width: MediaQuery.of(context).size.width * 0.85,
//                     padding: const EdgeInsets.all(20),
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.2),
//                       borderRadius: BorderRadius.circular(20),
//                       border: Border.all(color: Colors.white.withOpacity(0.3)),
//                     ),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         // Full Name
//                         TextField(
//                           controller: nameController,
//                           decoration: InputDecoration(
//                             labelText: "Full Name",
//                             prefixIcon: const Icon(
//                               Icons.person,
//                               color: Colors.white,
//                             ),
//                             filled: true,
//                             fillColor: Colors.white.withOpacity(0.25),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: BorderSide.none,
//                             ),
//                             labelStyle: const TextStyle(color: Colors.white),
//                           ),
//                           style: const TextStyle(color: Colors.white),
//                         ),
//                         const SizedBox(height: 16),

//                         // Email
//                         TextField(
//                           controller: emailController,
//                           decoration: InputDecoration(
//                             labelText: "Email",
//                             prefixIcon: const Icon(
//                               Icons.email,
//                               color: Colors.white,
//                             ),
//                             filled: true,
//                             fillColor: Colors.white.withOpacity(0.25),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: BorderSide.none,
//                             ),
//                             labelStyle: const TextStyle(color: Colors.white),
//                           ),
//                           style: const TextStyle(color: Colors.white),
//                         ),
//                         const SizedBox(height: 16),

//                         // Phone
//                         TextField(
//                           controller: phoneController,
//                           decoration: InputDecoration(
//                             labelText: "Phone",
//                             prefixIcon: const Icon(
//                               Icons.phone,
//                               color: Colors.white,
//                             ),
//                             filled: true,
//                             fillColor: Colors.white.withOpacity(0.25),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: BorderSide.none,
//                             ),
//                             labelStyle: const TextStyle(color: Colors.white),
//                           ),
//                           style: const TextStyle(color: Colors.white),
//                         ),
//                         const SizedBox(height: 16),

//                         // Address
//                         TextField(
//                           controller: addressController,
//                           decoration: InputDecoration(
//                             labelText: "Address",
//                             prefixIcon: const Icon(
//                               Icons.home,
//                               color: Colors.white,
//                             ),
//                             filled: true,
//                             fillColor: Colors.white.withOpacity(0.25),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: BorderSide.none,
//                             ),
//                             labelStyle: const TextStyle(color: Colors.white),
//                             suffixIcon: IconButton(
//                               icon: const Icon(
//                                 Icons.my_location,
//                                 color: Colors.white,
//                               ),
//                               onPressed: fetchCurrentAddress,
//                             ),
//                           ),
//                           style: const TextStyle(color: Colors.white),
//                         ),
//                         const SizedBox(height: 16),

//                         // Role Dropdown
//                         DropdownButtonFormField<String>(
//                           value: selectedRole,
//                           decoration: InputDecoration(
//                             labelText: "Role",
//                             prefixIcon: const Icon(
//                               Icons.person_outline,
//                               color: Colors.white,
//                             ),
//                             filled: true,
//                             fillColor: Colors.white.withOpacity(0.25),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: BorderSide.none,
//                             ),
//                             labelStyle: const TextStyle(color: Colors.white),
//                           ),
//                           dropdownColor: Colors.black87,
//                           items: const [
//                             DropdownMenuItem(
//                               value: "client",
//                               child: Text(
//                                 "Client",
//                                 style: TextStyle(color: Colors.white),
//                               ),
//                             ),
//                           ],
//                           onChanged: (value) {
//                             if (value != null) {
//                               setState(() {
//                                 selectedRole = value;
//                               });
//                             }
//                           },
//                           style: const TextStyle(color: Colors.white),
//                         ),
//                         const SizedBox(height: 16),

//                         // Password
//                         TextField(
//                           controller: passwordController,
//                           decoration: InputDecoration(
//                             labelText: "Password",
//                             prefixIcon: const Icon(
//                               Icons.lock,
//                               color: Colors.white,
//                             ),
//                             filled: true,
//                             fillColor: Colors.white.withOpacity(0.25),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: BorderSide.none,
//                             ),
//                             labelStyle: const TextStyle(color: Colors.white),
//                           ),
//                           obscureText: true,
//                           style: const TextStyle(color: Colors.white),
//                         ),
//                         const SizedBox(height: 16),

//                         // Confirm Password
//                         TextField(
//                           controller: confirmPasswordController,
//                           decoration: InputDecoration(
//                             labelText: "Confirm Password",
//                             prefixIcon: const Icon(
//                               Icons.lock_outline,
//                               color: Colors.white,
//                             ),
//                             filled: true,
//                             fillColor: Colors.white.withOpacity(0.25),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: BorderSide.none,
//                             ),
//                             labelStyle: const TextStyle(color: Colors.white),
//                           ),
//                           obscureText: true,
//                           style: const TextStyle(color: Colors.white),
//                         ),
//                         const SizedBox(height: 24),

//                         // Sign Up button
//                         ElevatedButton(
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: const Color.fromARGB(
//                               209,
//                               194,
//                               148,
//                               132,
//                             ),
//                             padding: const EdgeInsets.symmetric(
//                               vertical: 14,
//                               horizontal: 32,
//                             ),
//                           ),
//                           onPressed: isLoading ? null : signup,
//                           child: isLoading
//                               ? const CircularProgressIndicator(
//                                   color: Colors.white,
//                                 )
//                               : const Text(
//                                   "Sign Up",
//                                   style: TextStyle(fontSize: 18),
//                                 ),
//                         ),
//                         const SizedBox(height: 16),

//                         // Already have account
//                         TextButton(
//                           onPressed: () {
//                             Navigator.pushReplacement(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => const LoginScreen(),
//                               ),
//                             );
//                           },
//                           child: const Text(
//                             "Already have an account? Login",
//                             style: TextStyle(color: Colors.white),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cafe/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import 'login_screen.dart';
import 'home_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:ui'; // for ImageFilter

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  String selectedRole = "client"; // default role

  bool isLoading = false;

  // ---------------- Validators ----------------
  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool isValidMobile(String mobile) {
    final mobileRegex = RegExp(r'^[6-9][0-9]{9}$');
    return mobileRegex.hasMatch(mobile);
  }

  bool isValidPassword(String password) {
    final passRegex = RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d).{8,}$');
    return passRegex.hasMatch(password);
  }

  // ---------------- Location ----------------
  Future<void> fetchCurrentAddress() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permissions are permanently denied'),
        ),
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (placemarks.isNotEmpty) {
      Placemark place = placemarks.first;
      String address =
          "${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}";
      setState(() {
        addressController.text = address;
      });
    }
  }

  // ---------------- Signup ----------------
  Future<void> signup() async {
    if (!isValidEmail(emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid email")),
      );
      return;
    }

    if (!isValidMobile(phoneController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter a valid 10-digit mobile starting with 6-9"),
        ),
      );
      return;
    }

    if (!isValidPassword(passwordController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Password must be at least 8 characters, include uppercase, lowercase and a number",
          ),
        ),
      );
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    setState(() {
      isLoading = true;
    });

    final url = Uri.parse(ApiConstants.signup);
    final body = jsonEncode({
      "name": nameController.text.trim(),
      "email": emailController.text.trim(),
      "phone": phoneController.text.trim(),
      "address": addressController.text.trim(),
      "role": selectedRole,
      "password": passwordController.text.trim(),
    });

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Signup successful!")));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
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

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Sign Up"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset("assets/img1.webp", fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.4)),
          ),
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
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Full Name
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: "Full Name",
                            prefixIcon: const Icon(
                              Icons.person,
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

                        // Email
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: "Email",
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

                        // Mobile
                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.number,
                          maxLength: 10,
                          decoration: InputDecoration(
                            counterText: "",
                            labelText: "Mobile",
                            prefixIcon: const Icon(
                              Icons.phone,
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

                        // Address
                        TextField(
                          controller: addressController,
                          decoration: InputDecoration(
                            labelText: "Address",
                            prefixIcon: const Icon(
                              Icons.home,
                              color: Colors.white,
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.25),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            labelStyle: const TextStyle(color: Colors.white),
                            suffixIcon: IconButton(
                              icon: const Icon(
                                Icons.my_location,
                                color: Colors.white,
                              ),
                              onPressed: fetchCurrentAddress,
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 16),

                        // Role Dropdown
                        DropdownButtonFormField<String>(
                          value: selectedRole,
                          decoration: InputDecoration(
                            labelText: "Role",
                            prefixIcon: const Icon(
                              Icons.person_outline,
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
                          dropdownColor: Colors.black87,
                          items: const [
                            DropdownMenuItem(
                              value: "client",
                              child: Text(
                                "Client",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedRole = value;
                              });
                            }
                          },
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 16),

                        // Password
                        TextField(
                          controller: passwordController,
                          keyboardType: TextInputType.visiblePassword,
                          decoration: InputDecoration(
                            labelText: "Password",
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
                        const SizedBox(height: 16),

                        // Confirm Password
                        TextField(
                          controller: confirmPasswordController,
                          keyboardType: TextInputType.visiblePassword,
                          decoration: InputDecoration(
                            labelText: "Confirm Password",
                            prefixIcon: const Icon(
                              Icons.lock_outline,
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
                        const SizedBox(height: 24),

                        // Sign Up button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              209,
                              194,
                              148,
                              132,
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 32,
                            ),
                          ),
                          onPressed: isLoading ? null : signup,
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "Sign Up",
                                  style: TextStyle(fontSize: 18),
                                ),
                        ),
                        const SizedBox(height: 16),

                        // Already have account
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            "Already have an account? Login",
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
