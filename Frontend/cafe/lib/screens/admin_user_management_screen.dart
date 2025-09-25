// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:cafe/constants/api_constants.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class AdminUserManagementScreen extends StatefulWidget {
//   const AdminUserManagementScreen({super.key});

//   @override
//   State<AdminUserManagementScreen> createState() =>
//       _AdminUserManagementScreenState();
// }

// class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController nameController = TextEditingController();
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController phoneController = TextEditingController();
//   final TextEditingController addressController = TextEditingController();
//   final TextEditingController passwordController =
//       TextEditingController(); // added
//   String role = "barista"; // default

//   bool isSubmitting = false;

//   Future<void> addUser() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() => isSubmitting = true);

//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('access_token');
//     if (token == null) return;

//     try {
//       final response = await http.post(
//         Uri.parse("${ApiConstants.baseUrl}/signup"),
//         headers: {
//           "Authorization": "Bearer $token",
//           "Content-Type": "application/json",
//         },
//         body: jsonEncode({
//           "name": nameController.text.trim(),
//           "email": emailController.text.trim(),
//           "phone": phoneController.text.trim(),
//           "address": addressController.text.trim(),
//           "role": role,
//           "password": passwordController.text.trim(), // included
//         }),
//       );

//       if (response.statusCode == 200) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("User added successfully")),
//         );
//         // Clear form
//         nameController.clear();
//         emailController.clear();
//         phoneController.clear();
//         addressController.clear();
//         passwordController.clear(); // clear password
//         setState(() => role = "barista");
//       } else {
//         final body = jsonDecode(response.body);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Failed: ${body['detail'] ?? response.body}")),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Error: $e")));
//     } finally {
//       setState(() => isSubmitting = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Add User"),
//         backgroundColor: Colors.brown,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             children: [
//               TextFormField(
//                 controller: nameController,
//                 decoration: const InputDecoration(labelText: "Name"),
//                 validator: (v) => v!.isEmpty ? "Enter name" : null,
//               ),
//               TextFormField(
//                 controller: emailController,
//                 decoration: const InputDecoration(labelText: "Email"),
//                 validator: (v) => v!.isEmpty ? "Enter email" : null,
//               ),
//               TextFormField(
//                 controller: phoneController,
//                 decoration: const InputDecoration(labelText: "Phone"),
//                 keyboardType: TextInputType.phone,
//               ),
//               TextFormField(
//                 controller: addressController,
//                 decoration: const InputDecoration(labelText: "Address"),
//               ),
//               TextFormField(
//                 controller: passwordController, // new
//                 decoration: const InputDecoration(labelText: "Password"),
//                 obscureText: true,
//                 validator: (v) => v!.isEmpty ? "Enter password" : null,
//               ),
//               const SizedBox(height: 16),
//               DropdownButtonFormField<String>(
//                 value: role,
//                 items: const [
//                   DropdownMenuItem(value: "barista", child: Text("Barista")),
//                   DropdownMenuItem(value: "admin", child: Text("Admin")),
//                 ],
//                 onChanged: (v) => setState(() => role = v ?? "barista"),
//                 decoration: const InputDecoration(labelText: "Role"),
//               ),
//               const SizedBox(height: 24),
//               ElevatedButton(
//                 onPressed: isSubmitting ? null : addUser,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.brown,
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 32,
//                     vertical: 14,
//                   ),
//                 ),
//                 child: isSubmitting
//                     ? const CircularProgressIndicator(color: Colors.white)
//                     : const Text("Add User"),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cafe/constants/api_constants.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String role = "barista"; // default

  bool isSubmitting = false;

  Future<void> addUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSubmitting = true);

    try {
      final response = await http.post(
        Uri.parse("${ApiConstants.baseUrl}/auth/signup"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": nameController.text.trim(),
          "email": emailController.text.trim(),
          "phone": phoneController.text.trim(),
          "address": addressController.text.trim(),
          "role": role,
          "password": passwordController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User added successfully")),
        );
        // Clear form
        nameController.clear();
        emailController.clear();
        phoneController.clear();
        addressController.clear();
        passwordController.clear();
        setState(() => role = "barista");
      } else {
        final body = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: ${body['detail'] ?? response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add User"),
        backgroundColor: Colors.brown,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
                validator: (v) => v!.isEmpty ? "Enter name" : null,
              ),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (v) => v!.isEmpty ? "Enter email" : null,
              ),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: "Phone"),
                keyboardType: TextInputType.phone,
              ),
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(labelText: "Address"),
              ),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
                validator: (v) => v!.isEmpty ? "Enter password" : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: role,
                items: const [
                  DropdownMenuItem(value: "barista", child: Text("Barista")),
                  DropdownMenuItem(value: "admin", child: Text("Admin")),
                ],
                onChanged: (v) => setState(() => role = v ?? "barista"),
                decoration: const InputDecoration(labelText: "Role"),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isSubmitting ? null : addUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                ),
                child: isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Add User"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
