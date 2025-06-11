import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'technician_landing_screen.dart';
import 'farm_worker_landing_screen.dart';

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
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
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
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => _roleType == 'technician'
              ? const TechnicianLandingScreen()
              : const FarmWorkerLandingScreen(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _roleType,
                decoration: InputDecoration(labelText: "Role"),
                items: [
                  DropdownMenuItem(
                      value: "technician", child: Text("Technician")),
                  DropdownMenuItem(
                      value: "farm_worker", child: Text("Farm Worker")),
                ],
                onChanged: (v) => setState(() {
                  _roleType = v!;
                }),
              ),
              TextFormField(
                controller: _loginController,
                decoration: InputDecoration(
                  labelText: (_roleType == "technician")
                      ? "Email Address"
                      : "Phone Number",
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? "Please enter a value."
                    : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: "Password"),
                obscureText: true,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? "Please enter a password."
                    : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading ? CircularProgressIndicator() : Text("Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
