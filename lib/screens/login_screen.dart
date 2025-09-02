import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'farm_worker_landing_screen.dart';
import 'schedule_page.dart';
import 'technician_landing_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _roleType = 'technician'; // default role (technician or farm_worker)
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  // NEW ETO FORGOT PASSWORD CONTROLLER
  final TextEditingController _forgotPasswordEmailController =
      TextEditingController();
  bool _isLoading = false;
  // NEW ETO FORGOT PASSWORD SENDING RESET EMAIL
  bool _isSendingResetEmail = false;
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    // NEW ETO FORGOT PASSWORD CONTROLLER
    _forgotPasswordEmailController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.login(
        _roleType,
        _loginController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      // Navigate to appropriate landing page based on role
      await Future.delayed(const Duration(
          milliseconds: 400)); // Ensure storage and provider are ready
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => _roleType == 'technician'
              ? TechnicianLandingScreen(
                  token: user.token ?? '', technicianId: user.id)
              : FarmWorkerLandingScreen(token: user.token ?? ''),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

// ETO BAGO TO FORGOT PASSWORD
  Future<void> _sendForgotPasswordEmail() async {
    if (_forgotPasswordEmailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address')),
      );
      return;
    }

    setState(() {
      _isSendingResetEmail = true;
    });

    try {
      await _authService
          .forgotPassword(_forgotPasswordEmailController.text.trim());

      if (mounted) {
        setState(() {
          _isSendingResetEmail = false;
        });

        Navigator.of(context).pop(); // Close the dialog

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Password reset email sent. Please check your email.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSendingResetEmail = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
        backgroundColor: const Color(0xFF27AE60), // Green
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _roleType,
                decoration: const InputDecoration(
                  labelText: "Role",
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF27AE60)),
                  ),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                      value: "technician", child: Text("Technician")),
                  DropdownMenuItem(
                      value: "farm_worker", child: Text("Farm Worker")),
                ],
                onChanged: (v) => setState(() {
                  _roleType = v!;
                }),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _loginController,
                decoration: InputDecoration(
                  labelText: (_roleType == "technician")
                      ? "Email Address"
                      : "Phone Number",
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF27AE60)),
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? "Please enter a value."
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: "Password",
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF27AE60)),
                  ),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? "Please enter a password."
                    : null,
              ),
              const SizedBox(height: 16),
              // NEW Forgot Password Link (only show for technicians)
              if (_roleType == 'technician')
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPasswordDialog,
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(
                        color: Color(0xFF27AE60),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27AE60), // Green
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Login", style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // NEW ETO Show forgot password dialog
  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Forgot Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your email address to receive a password reset link.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _forgotPasswordEmailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF27AE60)),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                enabled: !_isSendingResetEmail,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _isSendingResetEmail
                  ? null
                  : () {
                      Navigator.of(context).pop();
                    },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isSendingResetEmail ? null : _sendForgotPasswordEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF27AE60),
              ),
              child: _isSendingResetEmail
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Send Reset Link'),
            ),
          ],
        );
      },
    );
  }
}
