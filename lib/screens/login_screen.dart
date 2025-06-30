import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'technician_landing_screen.dart';
import 'farm_worker_landing_screen.dart';
import 'schedule_page.dart';

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
              ? TechnicianLandingScreen(token: user.token ?? '')
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Login"),
        backgroundColor: Color(0xFF27AE60), // Green
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
                decoration: InputDecoration(
                  labelText: "Role",
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF27AE60)),
                  ),
                  border: OutlineInputBorder(),
                ),
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
              SizedBox(height: 16),
              TextFormField(
                controller: _loginController,
                decoration: InputDecoration(
                  labelText: (_roleType == "technician")
                      ? "Email Address"
                      : "Phone Number",
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF27AE60)),
                  ),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? "Please enter a value."
                    : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
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
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF27AE60), // Green
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Login", style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
