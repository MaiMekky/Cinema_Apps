import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:customer_app/pages/home/home_page.dart';
import 'package:customer_app/utils/app_colors.dart';
import 'package:customer_app/widgets/custom_text_field.dart';
import 'package:customer_app/services/auth_service.dart';



class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

 Future<void> registerUser() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => isLoading = true);

  try {
    final auth = AuthService();

    await auth.signup(
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  } on FirebaseAuthException catch (e) {
    String errorMsg = "";

    if (e.code == "email-already-in-use") {
      errorMsg = "This email is already registered.";
    } else if (e.code == "weak-password") {
      errorMsg = "Password is too weak.";
    } else {
      errorMsg = e.message ?? "Registration failed.";
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(errorMsg)));
  } finally {
    setState(() => isLoading = false);
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                Text(
                  "Create Account",
                  style: TextStyle(
                    fontSize: 32,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),

                CustomTextField(
                  label: "Full Name",
                  controller: nameController,
                  validator: (value) =>
                      value == null || value.isEmpty ? "Name is required" : null,
                ),

                const SizedBox(height: 20),

                CustomTextField(
                  label: "Email",
                  controller: emailController,
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Email required";
                    if (!value.contains("@")) return "Enter a valid email";
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                CustomTextField(
                  label: "Password",
                  controller: passwordController,
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Password required";
                    if (value.length < 6) {
                      return "Password must be at least 6 characters";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                CustomTextField(
                  label: "Confirm Password",
                  controller: confirmController,
                  isPassword: true,
                  validator: (value) {
                    if (value != passwordController.text) {
                      return "Passwords do not match";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : registerUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Create Account",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
