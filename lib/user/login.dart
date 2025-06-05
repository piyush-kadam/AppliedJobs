// Now, let's modify your LoginPage to implement the forgot password functionality

// Modified version of the login.dart file:
import 'package:appliedjobs/auth/authservice.dart';
import 'package:appliedjobs/screens/home.dart';
import 'package:appliedjobs/user/signup.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onTap;

  const LoginPage({super.key, required this.onTap});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController resetEmailController = TextEditingController();

  bool isLoading = false;
  final AuthService authService = AuthService();

  // Login with Email & Password
  Future<void> login() async {
    try {
      setState(() => isLoading = true);

      await authService.signInWithEmailPassword(
        emailController.text.trim(),
        passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? "An error occurred")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Google Sign-In
  Future<void> signInWithGoogle() async {
    try {
      setState(() => isLoading = true);

      // Sign in with Google
      UserCredential? userCredential = await authService.signInWithGoogle();
      User? user = userCredential?.user;

      if (user != null) {
        // Check if the user exists in Firestore
        final userDoc =
            await FirebaseFirestore.instance
                .collection('Users')
                .doc(user.uid)
                .get();

        if (userDoc.exists) {
          // User exists → allow login
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Signed in with Google')),
          );
        } else {
          // New user → Sign out from both Firebase and Google
          await FirebaseAuth.instance.signOut();
          await GoogleSignIn()
              .signOut(); // Force Google account selection next time

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.info_outline, color: Colors.white),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No account found. Please sign up first.',
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
              backgroundColor: Color(0xFF3D47D1), // Blue color
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Forgot Password
  void showForgotPasswordDialog() {
    // Pre-fill with the email from the login field if available
    resetEmailController.text = emailController.text;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              "Reset Password",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Enter your email address and we'll send you a link to reset your password.",
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: resetEmailController,
                  decoration: InputDecoration(
                    labelText: "Email",
                    prefixIcon: const Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel", style: GoogleFonts.poppins()),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    Navigator.pop(context); // Close the dialog

                    // Show loading indicator
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder:
                          (context) =>
                              const Center(child: CircularProgressIndicator()),
                    );

                    await authService.sendPasswordResetEmail(
                      resetEmailController.text.trim(),
                    );

                    // Close loading dialog
                    Navigator.pop(context);

                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Password reset link sent to ${resetEmailController.text}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  } on FirebaseAuthException catch (e) {
                    // Close loading dialog if open
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }

                    // Show error message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                e.message ?? 'An error occurred',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF3D47D1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "Send Reset Link",
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: StreamBuilder<User?>(
        stream: authService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            final user = snapshot.data;
            if (user != null) {
              return const HomePage();
            }
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 50,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipOval(
                        child: Image.asset(
                          'assets/images/ap.png',
                          width: 46,
                          height: 46,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Applied Plus",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3D47D1),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            "Welcome back",
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            "Enter your credentials to sign in to\nyour account",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: isLoading ? null : signInWithGoogle,
                            icon: Image.asset(
                              'assets/images/google.jpg',
                              height: 24,
                            ),
                            label: Text(
                              "Continue with Google",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF3D47D1),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.grey),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey[300])),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: Text(
                                "OR CONTINUE WITH EMAIL",
                                style: GoogleFonts.poppins(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey[300])),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text("Email", style: GoogleFonts.poppins(fontSize: 14)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.email_outlined),
                            hintText: "name@example.com",
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Password",
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: TextButton(
                              onPressed:
                                  showForgotPasswordDialog, // Connect to forgot password function
                              child: Text(
                                "Forgot password?",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Color(0xFF3D47D1),
                                ),
                              ),
                            ),
                            hintText: "••••••••",
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF3D47D1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child:
                                isLoading
                                    ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                    : Text(
                                      "Sign In",
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SignUpPage(onTap: () {}),
                                    ),
                                  );
                                },
                                child: Text(
                                  "Sign up",
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Color(0xFF3D47D1),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
