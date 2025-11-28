import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'signup_page.dart';
import '../screens/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // ✅ MOBILE GOOGLE SIGN-IN (iOS/Android)
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // ✅ This works AUTOMATICALLY on mobile with GoogleService-Info.plist
  );
  
  bool loading = false;

  Future<void> _loginWithEmail() async {
    try {
      setState(() => loading = true);

      await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Login Successful! Redirecting..."),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
      }

    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        String errorMessage = "Login failed";
        switch (e.code) {
          case 'user-not-found':
            errorMessage = "No user found for that email.";
            break;
          case 'wrong-password':
            errorMessage = "Wrong password provided.";
            break;
          case 'invalid-email':
            errorMessage = "The email address is not valid.";
            break;
          default:
            errorMessage = e.message ?? "Login failed";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ✅ FIXED: Mobile Google Sign-In
  Future<void> _loginWithGoogle() async {
    try {
      print("🔥 MOBILE GOOGLE SIGN-IN STARTED 🔥");
      setState(() => loading = true);
      
      // Clear previous session
      await _googleSignIn.signOut();
      print("✅ Google Sign-Out completed");
      
      // iOS Native Sign-In
      print("🚀 Starting iOS Google Sign-In...");
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      print("👤 Google User: $googleUser");
      
      if (googleUser == null) {
        print("❌ User cancelled sign-in");
        if (mounted) setState(() => loading = false);
        return;
      }
      
      print("✅ Getting authentication tokens...");
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      print("🔑 Access Token: ${googleAuth.accessToken != null}");
      print("🔑 ID Token: ${googleAuth.idToken != null}");
      
      if (googleAuth.idToken == null) {
        throw Exception('Failed to get Google ID token');
      }
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      print("🔥 Authenticating with Firebase...");
      await _auth.signInWithCredential(credential);
      print("✅ FIREBASE AUTH SUCCESSFUL!");
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Google Login Successful!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
      }
    } catch (e, stackTrace) {
      print("💥 GOOGLE SIGN-IN ERROR: $e");
      print("📍 Stack Trace: $stackTrace");
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Google Sign-In Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.child_care, size: 80, color: Colors.blue),
              const SizedBox(height: 16),
              const Text(
                "Baby Beacon",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              const SizedBox(height: 8),
              Text(
                "Welcome back! Please sign in to continue",
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 40),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: loading ? null : _loginWithEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          "Sign In with Email",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: loading ? null : _loginWithGoogle,
                  icon: const Icon(Icons.login, color: Colors.red, size: 20),
                  label: const Text(
                    "Continue with Google",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? ", style: TextStyle(color: Colors.grey[600])),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignupPage()),
                      );
                    },
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}