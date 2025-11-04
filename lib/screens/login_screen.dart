import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/auth_service.dart';
import 'farm_worker_landing_screen.dart';
import 'technician_landing_screen.dart';
import 'coordinator_landing_screen.dart';

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
  // NEW ETO EMAIL VERIFICATION
  bool _isSendingVerificationEmail = false;
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isRoleDropdownExpanded = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    // NEW ETO FORGOT PASSWORD CONTROLLER
    _forgotPasswordEmailController.dispose();
    super.dispose();
  }

// CHANGES STARTS HERE
  Future<void> _loadRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final remembered = prefs.getBool('remember_me') ?? false;
    if (remembered) {
      final email = prefs.getString('remembered_email') ?? '';
      final password = prefs.getString('remembered_password') ?? '';
      final role = prefs.getString('remembered_role') ?? 'technician';

      setState(() {
        _rememberMe = remembered;
        _loginController.text = email;
        _passwordController.text = password;
        _roleType = role;
      });
    }
  }

  Future<void> _saveRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setBool('remember_me', true);
      await prefs.setString('remembered_email', _loginController.text.trim());
      await prefs.setString(
          'remembered_password', _passwordController.text.trim());
      await prefs.setString('remembered_role', _roleType);
    } else {
      await prefs.remove('remember_me');
      await prefs.remove('remembered_email');
      await prefs.remove('remembered_password');
      await prefs.remove('remembered_role');
    }
  }

//CHANGES ENDS HERE
  Future<void> _login() async {
    print('📱 [LOGIN SCREEN] Starting login process...');
    print(
        '📱 [LOGIN SCREEN] Form validation: ${_formKey.currentState?.validate()}');

    if (!_formKey.currentState!.validate()) {
      print('📱 [LOGIN SCREEN] ❌ Form validation failed');
      return;
    }

    print('📱 [LOGIN SCREEN] ✅ Form validation passed');
    print('📱 [LOGIN SCREEN] Setting loading state to true');

    setState(() {
      _isLoading = true;
    });

    try {
      print('📱 [LOGIN SCREEN] Calling AuthService.login...');
      print('📱 [LOGIN SCREEN] Role: $_roleType');
      print('📱 [LOGIN SCREEN] Login: ${_loginController.text.trim()}');
      print(
          '📱 [LOGIN SCREEN] Password length: ${_passwordController.text.trim().length}');

      final user = await _authService.login(
        _roleType,
        _loginController.text.trim(),
        _passwordController.text.trim(),
      );

      print('📱 [LOGIN SCREEN] ✅ AuthService.login completed successfully');
      print('📱 [LOGIN SCREEN] User received: ${user.toString()}');
      print('📱 [LOGIN SCREEN] Checking if widget is mounted...');

      if (!mounted) {
        print('📱 [LOGIN SCREEN] ❌ Widget not mounted, returning');
        return;
      }

      print('📱 [LOGIN SCREEN] ✅ Widget is mounted, proceeding...');

      // SAVE CREDENTAINS IF REMEMBER ME IS CHECKED
      print('📱 [LOGIN SCREEN] Saving remembered credentials...');
      await _saveRememberedCredentials();
      print('📱 [LOGIN SCREEN] ✅ Credentials saved');

      // Navigate to appropriate landing page based on role
      print('📱 [LOGIN SCREEN] Waiting 400ms before navigation...');
      await Future.delayed(const Duration(
          milliseconds: 400)); // Ensure storage and provider are ready

      print('📱 [LOGIN SCREEN] Starting navigation...');
      print(
          '📱 [LOGIN SCREEN] Target screen: ${_roleType == 'technician' ? 'TechnicianLandingScreen' : 'FarmWorkerLandingScreen'}');

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) {
            if (_roleType == 'technician') {
              return TechnicianLandingScreen(
                  token: user.token ?? '', technicianId: user.id);
            } else if (_roleType == 'area_coordinator') {
              return CoordinatorLandingScreen(
                  token: user.token ?? '', coordinatorId: user.id);
            } else {
              return FarmWorkerLandingScreen(token: user.token ?? '');
            }
          },
        ),
      );

      print('📱 [LOGIN SCREEN] ✅ Navigation completed');
    } catch (e) {
      print('📱 [LOGIN SCREEN] ❌ Exception caught: ${e.toString()}');
      print('📱 [LOGIN SCREEN] Exception type: ${e.runtimeType}');

      if (!mounted) {
        print('📱 [LOGIN SCREEN] ❌ Widget not mounted, cannot show error');
        return;
      }

      print('📱 [LOGIN SCREEN] ✅ Widget is mounted, showing error...');

      // Check if this is an email verification required error
      final errorMessage = e.toString();
      print('📱 [LOGIN SCREEN] Error message: $errorMessage');

      if (errorMessage.contains('email_verification_required') ||
          errorMessage.contains('Please verify your email address')) {
        print('📱 [LOGIN SCREEN] Showing email verification dialog...');
        _showEmailVerificationDialog();
      } else {
        print('📱 [LOGIN SCREEN] Showing error snackbar...');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${e.toString()}')),
        );
      }
    } finally {
      print('📱 [LOGIN SCREEN] Finally block - setting loading to false');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        print('📱 [LOGIN SCREEN] ✅ Loading state set to false');
      } else {
        print(
            '📱 [LOGIN SCREEN] ❌ Widget not mounted, cannot update loading state');
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

  // NEW ETO EMAIL VERIFICATION RESEND
  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isSendingVerificationEmail = true;
    });

    try {
      await _authService.resendVerificationEmail(_loginController.text.trim());

      if (mounted) {
        setState(() {
          _isSendingVerificationEmail = false;
        });

        Navigator.of(context).pop(); // Close the dialog

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent. Please check your email.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSendingVerificationEmail = false;
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

  // Build role dropdown option helper method
  Widget _buildRoleDropdownOption({
    required String label,
    required String value,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color:
                        isSelected ? const Color(0xFF2C3E50) : Colors.grey[600],
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.green,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //CHANGES STARTS HERE NA PART HANGANG DULO
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // White Header Section
                      Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(0),
                            bottomRight: Radius.circular(0),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(
                              left: 24, right: 24, top: 20, bottom: 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Main Logo (TRABACCO_LOGO.svg) - smaller size
                              Container(
                                height: 60,
                                child: SvgPicture.asset(
                                  'assets/TRABACCO_LOGO.svg',
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Main Title - left aligned and bigger
                              const Text(
                                'Sign in to your Account',
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  color: Color(0xFF1A1A1A),
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Subtitle - left aligned
                              const Text(
                                'Enter your email and password to log in',
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  color: Color(0xFF666666),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // White Content Section
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Role Dropdown
                                const Text(
                                  'Role',
                                  style: TextStyle(
                                    color: Color(0xFF666666),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Custom Role Dropdown
                                Column(
                                  children: [
                                    // Dropdown Header
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isRoleDropdownExpanded =
                                              !_isRoleDropdownExpanded;
                                        });
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: const Color(0xFFE0E0E0),
                                            width: 1.0,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.05),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 16,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.person_outline,
                                              color: Colors.grey[600],
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                _roleType == 'technician'
                                                    ? 'Technician'
                                                    : _roleType == 'area_coordinator'
                                                        ? 'Area Coordinator'
                                                        : 'Farmer',
                                                style: TextStyle(
                                                  color:
                                                      const Color(0xFF2C3E50),
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            Icon(
                                              _isRoleDropdownExpanded
                                                  ? Icons.keyboard_arrow_up
                                                  : Icons.keyboard_arrow_down,
                                              color: Colors.grey[600],
                                              size: 24,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Dropdown Options
                                    if (_isRoleDropdownExpanded) ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: const Color(0xFFE0E0E0),
                                            width: 1.0,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.05),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          children: [
                                            // Technician Option
                                            _buildRoleDropdownOption(
                                              label: 'Technician',
                                              value: 'technician',
                                              isSelected:
                                                  _roleType == 'technician',
                                              onTap: () {
                                                // Clear input when switching to different role
                                                if (_roleType != 'technician') {
                                                  _loginController.clear();
                                                }
                                                setState(() {
                                                  _roleType = 'technician';
                                                  _isRoleDropdownExpanded =
                                                      false;
                                                });
                                              },
                                            ),
                                            Divider(
                                              height: 1,
                                              color: Colors.grey[200],
                                              thickness: 1,
                                            ),
                                            // Area Coordinator Option
                                            _buildRoleDropdownOption(
                                              label: 'Area Coordinator',
                                              value: 'area_coordinator',
                                              isSelected:
                                                  _roleType == 'area_coordinator',
                                              onTap: () {
                                                // Clear input when switching to different role
                                                if (_roleType !=
                                                    'area_coordinator') {
                                                  _loginController.clear();
                                                }
                                                setState(() {
                                                  _roleType = 'area_coordinator';
                                                  _isRoleDropdownExpanded =
                                                      false;
                                                });
                                              },
                                            ),
                                            Divider(
                                              height: 1,
                                              color: Colors.grey[200],
                                              thickness: 1,
                                            ),
                                            // Farmer Option
                                            _buildRoleDropdownOption(
                                              label: 'Farmer',
                                              value: 'farm_worker',
                                              isSelected:
                                                  _roleType == 'farm_worker',
                                              onTap: () {
                                                // Clear input when switching to different role
                                                if (_roleType !=
                                                    'farm_worker') {
                                                  _loginController.clear();
                                                }
                                                setState(() {
                                                  _roleType = 'farm_worker';
                                                  _isRoleDropdownExpanded =
                                                      false;
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Email/Phone Field
                                Text(
                                  _roleType == 'technician' || _roleType == 'area_coordinator'
                                      ? 'Email'
                                      : 'Phone Number',
                                  style: const TextStyle(
                                    color: Color(0xFF666666),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: const Color(0xFFE0E0E0),
                                        width: 1.5),
                                  ),
                                  child: Focus(
                                    onFocusChange: (hasFocus) {
                                      setState(() {});
                                    },
                                    child: TextFormField(
                                      controller: _loginController,
                                      keyboardType: (_roleType == 'technician' || _roleType == 'area_coordinator')
                                          ? TextInputType.emailAddress
                                          : TextInputType.phone,
                                      decoration: InputDecoration(
                                        hintText: (_roleType == 'technician' || _roleType == 'area_coordinator')
                                            ? "Enter your email address"
                                            : "Enter phone number",
                                        hintStyle: const TextStyle(
                                          color: Color(0xFF999999),
                                          fontSize: 16,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                      style: const TextStyle(
                                        color: Color(0xFF333333),
                                        fontSize: 16,
                                      ),
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) {
                                          return (_roleType == 'technician' || _roleType == 'area_coordinator')
                                              ? "Please enter your email address."
                                              : "Please enter your phone number.";
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Password Field
                                const Text(
                                  'Password',
                                  style: TextStyle(
                                    color: Color(0xFF666666),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: const Color(0xFFE0E0E0),
                                        width: 1.5),
                                  ),
                                  child: Focus(
                                    onFocusChange: (hasFocus) {
                                      setState(() {});
                                    },
                                    child: TextFormField(
                                      controller: _passwordController,
                                      decoration: InputDecoration(
                                        hintText: "********",
                                        hintStyle: const TextStyle(
                                          color: Color(0xFF999999),
                                          fontSize: 16,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide.none,
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: const Color(0xFF999999),
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword =
                                                  !_obscurePassword;
                                            });
                                          },
                                        ),
                                      ),
                                      style: const TextStyle(
                                        color: Color(0xFF333333),
                                        fontSize: 16,
                                      ),
                                      obscureText: _obscurePassword,
                                      validator: (v) =>
                                          (v == null || v.trim().isEmpty)
                                              ? "Please enter a password."
                                              : null,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Remember Me and Forgot Password Row
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Remember Me Checkbox
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: _rememberMe,
                                          onChanged: (value) {
                                            setState(() {
                                              _rememberMe = value ?? false;
                                            });
                                          },
                                          activeColor: const Color(0xFF27AE60),
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        const Text(
                                          'Remember me',
                                          style: TextStyle(
                                            color: Color(0xFF666666),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Forgot Password Link (only show for technicians)
                                    if (_roleType == 'technician')
                                      TextButton(
                                        onPressed: _showForgotPasswordDialog,
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const Text(
                                          'Forgot Password?',
                                          style: TextStyle(
                                            color: Color(0xFF27AE60),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                // Login Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF27AE60),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      elevation: 0,
                                    ),
                                    onPressed: _isLoading ? null : _login,
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text(
                                            'Log In',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
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
                      // Legal Disclaimer Footer at the very bottom
                      const Padding(
                        padding: EdgeInsets.only(
                          left: 20,
                          right: 20,
                          bottom: 20,
                        ),
                        child: Center(
                          child: Text.rich(
                            TextSpan(
                              text: 'By signing up, you agree to the ',
                              style: TextStyle(
                                color: Color(0xFF666666),
                                fontSize: 12,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: TextStyle(
                                    color: Color(0xFF333333),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Data Processing Agreement',
                                  style: TextStyle(
                                    color: Color(0xFF333333),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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

  // NEW ETO EMAIL VERIFICATION DIALOG
  void _showEmailVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(
                Icons.email_outlined,
                color: Color(0xFF27AE60),
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Email Verification Required',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your email address needs to be verified before you can access your account.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                  height: 1.4,
                ),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xFFE9ECEF)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFF27AE60),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Check your email inbox and click the verification link to activate your account.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF495057),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Email: ${_loginController.text.trim()}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _isSendingVerificationEmail
                  ? null
                  : () {
                      Navigator.of(context).pop();
                    },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed:
                  _isSendingVerificationEmail ? null : _resendVerificationEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF27AE60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: _isSendingVerificationEmail
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Resend Email',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}
