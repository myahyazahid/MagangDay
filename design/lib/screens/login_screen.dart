import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        if (mounted && ModalRoute.of(context)?.isCurrent == true) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    });
  }

  Future<void> _handleSocialLogin(Future<void> Function() loginMethod) async {
    setState(() {
      _isLoading = true;
    });
    try {
      await loginMethod();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Text(
              e is AuthException ? e.message : e.toString(),
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        );
      }
    }
  }

  // Google SVG Icon (Light Theme Color Version)
  final String _googleSvg = '''
<svg viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M15.68 8.18C15.68 7.61 15.63 7.07 15.54 6.54H8V9.64H12.3C12.2099 10.129 12.0217 10.5946 11.7467 11.0088C11.4717 11.423 11.1157 11.7772 10.7 12.05V14.05H13.29C14.81 12.65 15.68 10.59 15.68 8.18Z" fill="#4285F4"/>
  <path d="M8 16C10.16 16 11.97 15.28 13.3 14.06L10.7 12.06C10.0891 12.4522 9.3967 12.6997 8.67563 12.7838C7.95456 12.8678 7.22381 12.7862 6.53906 12.5451C5.85431 12.304 5.23363 11.9097 4.7243 11.3924C4.21498 10.8751 3.83044 10.2484 3.6 9.56H1V11.63C1.65954 12.9257 2.65972 14.0173 3.89306 14.7872C5.1264 15.5572 6.54625 15.9765 8 16Z" fill="#34A853"/>
  <path d="M3.6 9.56C3.36825 8.7224 3.36825 7.8376 3.6 7H1V9.07C1.22649 10.8405 2.03854 12.4843 3.30698 13.7401C4.57541 14.9958 6.22735 15.7913 8 16" fill="#34A853"/>
  <path d="M3.6 9.56C3.43447 9.05681 3.35337 8.52968 3.36 8C3.35337 7.47032 3.43447 6.94319 3.6 6.44V4.38H1C0.384143 5.49022 0.041365 6.73108 0 8C0 9.29 0.31 10.5 0.86 11.57L3.6 9.56Z" fill="#FBBC05"/>
  <path d="M8 3.2C9.13827 3.18118 10.238 3.61243 11.06 4.4L13.34 2.12C11.9019 0.748164 9.98744 -0.0118833 8 0C6.54521 0.0244967 5.12465 0.445279 3.89122 1.21706C2.65778 1.98884 1.65818 3.08238 1 4.38L3.6 6.44C3.91317 5.51424 4.50314 4.70702 5.29009 4.12753C6.07705 3.54805 7.02301 3.22427 8 3.2Z" fill="#EA4335"/>
</svg>
''';

  // Apple SVG Icon (Black Version for Light Theme)
  /*
  final String _appleSvg = '''
<svg viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M11.18 8.01C11.16 6.05 12.78 5.11 12.85 5.06C11.94 3.73 10.52 3.55 10.01 3.53C8.8 3.41 7.65 4.24 7.03 4.24C6.41 4.24 5.45 3.55 4.43 3.57C3.09 3.59 1.85 4.35 1.16 5.55C-0.24 7.97 0.8 11.56 2.16 13.52C2.83 14.48 3.62 15.56 4.66 15.52C5.67 15.48 6.05 14.87 7.26 14.87C8.48 14.87 8.83 15.52 9.89 15.5C10.97 15.48 11.65 14.52 12.31 13.55C13.07 12.44 13.39 11.36 13.41 11.3C13.39 11.3 11.18 10.45 11.18 8.01Z" fill="#000000"/>
  <path d="M9.3 2.2C9.85 1.54 10.22 0.62 10.1 -0.3C9.3 -0.26 8.33 0.23 7.76 0.89C7.24 1.47 6.79 2.41 6.91 3.3C7.8 3.37 8.71 2.84 9.3 2.2Z" fill="#000000"/>
</svg>
''';
*/

  // Eye Icon (Visible) - Orange/Grey stroke
  final String _eyeSvg = '''
<svg viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M1.37467 7.768C1.31911 7.91768 1.31911 8.08232 1.37467 8.232C1.9158 9.5441 2.83434 10.666 4.01385 11.4554C5.19335 12.2448 6.5807 12.6663 8 12.6663C9.4193 12.6663 10.8066 12.2448 11.9862 11.4554C13.1657 10.666 14.0842 9.5441 14.6253 8.232C14.6809 8.08232 14.6809 7.91768 14.6253 7.768C14.0842 6.4559 13.1657 5.33403 11.9862 4.5446C10.8066 3.75517 9.4193 3.33374 8 3.33374C6.5807 3.33374 5.19335 3.75517 4.01385 4.5446C2.83434 5.33403 1.9158 6.4559 1.37467 7.768Z" stroke="#757575" stroke-width="1.33333" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M8 10C9.10457 10 10 9.10457 10 8C10 6.89543 9.10457 6 8 6C6.89543 6 6 6.89543 6 8C6 9.10457 6.89543 10 8 10Z" stroke="#757575" stroke-width="1.33333" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

  // Eye Icon (Obscured) - Orange/Grey stroke
  final String _eyeCrossedSvg = '''
<svg viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M2.5 2.5L13.5 13.5" stroke="#757575" stroke-width="1.33333" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M8.5 4.5C9.4193 4.5 10.3066 4.92143 11.4862 5.7108C12.6657 6.5002 13.5842 7.6221 14.1253 8.934C14.1809 9.0837 14.1809 9.2483 14.1253 9.398C13.8 10.187 13.25 10.875 12.5 11.5" stroke="#757575" stroke-width="1.33333" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M9.5 9.5C9.07 9.83 8.57 10 8 10C6.89543 10 6 9.10457 6 8C6 7.43 6.17 6.93 6.5 6.5" stroke="#757575" stroke-width="1.33333" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M5.5 5.5C4.3193 6.0779 3.43434 7.0221 2.89385 8.334C2.83829 8.4837 2.83829 8.6483 2.89385 8.798C3.43498 10.1101 4.35352 11.232 5.53302 12.0214C6.71253 12.8108 8.09988 13.2323 9.51918 13.2323C10.4 13.2323 11.25 13.0623 12 12.7" stroke="#757575" stroke-width="1.33333" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        await SupabaseService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          Navigator.pushReplacementNamed(context, '/home');
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          String errorMsg = e.toString();
          if (e is AuthException) {
            errorMsg = e.message;
            if (e.message.contains('Invalid login credentials')) {
              errorMsg = 'Email atau password salah';
            }
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              content: Text(
                errorMsg,
                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktopWeb = screenWidth > 600;

    Widget loginContent = Container(
      width: isDesktopWeb ? 360 : double.infinity,
      height: isDesktopWeb ? 800 : double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isDesktopWeb ? BorderRadius.circular(36) : BorderRadius.zero,
      ),
      child: ClipRRect(
        borderRadius: isDesktopWeb ? BorderRadius.circular(36) : BorderRadius.zero,
        child: Stack(
          children: [
            // Decorative Top Gradient Orange Blob
            Positioned(
              left: -40,
              top: -60,
              width: 240,
              height: 240,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFF9E00).withValues(alpha: 0.2),
                      const Color(0xFFFF6D00).withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            // Scrollable main content
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 24),
                              
                              // --- MagangDay Header Brand Logo ---
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.08),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        )
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.asset(
                                        'assets/logo.png',
                                        width: 42,
                                        height: 42,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'MagangDay',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF1E1E2F),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 48),

                              // --- Heading Texts ---
                              Text(
                                'Selamat Datang!',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1E1E2F),
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Catat aktivitas magangmu setiap hari dengan mudah.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal,
                                  color: const Color(0xFF757575),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 36),

                              // --- Email Input ---
                              Text(
                                'EMAIL',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFFF6D00),
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  color: const Color(0xFF1E1E2F),
                                ),
                                decoration: _inputDecoration(
                                  hintText: 'contoh@email.com',
                                  prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Email tidak boleh kosong';
                                  }
                                  final emailRegExp = RegExp(
                                      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
                                  if (!emailRegExp.hasMatch(value)) {
                                    return 'Format email tidak valid';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // --- Password Input ---
                              Text(
                                'PASSWORD',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFFF6D00),
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  color: const Color(0xFF1E1E2F),
                                ),
                                decoration: _inputDecoration(
                                  hintText: 'Masukkan password kamu',
                                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                                  suffixIcon: IconButton(
                                    padding: EdgeInsets.zero,
                                    splashRadius: 20,
                                    icon: SvgPicture.string(
                                      _obscurePassword ? _eyeSvg : _eyeCrossedSvg,
                                      width: 16,
                                      height: 16,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Password tidak boleh kosong';
                                  }
                                  if (value.length < 6) {
                                    return 'Password minimal 6 karakter';
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) => _handleLogin(),
                              ),
                              const SizedBox(height: 16),

                              // --- Remember Me & Forgot Password Row ---
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Custom Checkbox
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _rememberMe = !_rememberMe;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(6),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 18,
                                          height: 18,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(
                                              color: _rememberMe 
                                                  ? const Color(0xFFFF6D00) 
                                                  : const Color(0xFFCCCCCC),
                                              width: _rememberMe ? 2.0 : 1.2,
                                            ),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          alignment: Alignment.center,
                                          child: _rememberMe
                                              ? const Icon(
                                                  Icons.check,
                                                  size: 12,
                                                  color: Color(0xFFFF6D00),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Ingat saya',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF757575),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Forgot Password
                                  TextButton(
                                    onPressed: () {},
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'Lupa password?',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFFFF6D00),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              const SizedBox(height: 24),

                              // --- Main Submit Button ---
                              Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF6D00).withValues(alpha: 0.25),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFFF6D00),
                                      Color(0xFFFF9E00),
                                    ],
                                  ),
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          'Masuk Sekarang',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // --- Divider ---
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 0.8,
                                      color: const Color(0xFFE0E0E0),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      'atau masuk dengan',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: const Color(0xFF9E9E9E),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 0.8,
                                      color: const Color(0xFFE0E0E0),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // --- Google Social Light Button ---
                              _SocialButton(
                                svgIcon: _googleSvg,
                                label: 'Google',
                                onPressed: () => _handleSocialLogin(SupabaseService.signInWithGoogle),
                              ),
                              const SizedBox(height: 24),

                              // --- Redirect to Register ---
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Belum punya akun? ',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.normal,
                                      color: const Color(0xFF757575),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pushNamed(context, '/register');
                                    },
                                    child: Text(
                                      'Daftar Sekarang',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFFF6D00),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (isDesktopWeb) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F0F5),
        body: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 24),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
              border: Border.all(
                color: const Color(0xFFE0E0E8),
                width: 1.5,
              ),
            ),
            child: loginContent,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: loginContent,
    );
  }

  InputDecoration _inputDecoration({required String hintText, Widget? prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: const Color(0xFF9E9E9E),
      ),
      filled: true,
      fillColor: const Color(0xFFF9F9FB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.8, vertical: 14.8),
      prefixIcon: prefixIcon != null 
          ? IconTheme(
              data: const IconThemeData(color: Color(0xFF9E9E9E)),
              child: prefixIcon,
            )
          : null,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFE5E5E9),
          width: 1.0,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFE5E5E9),
          width: 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFFF6D00),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.0,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String svgIcon;
  final String label;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.svgIcon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: const Color(0xFFE5E5E9),
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.string(
              svgIcon,
              width: 16,
              height: 16,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E1E2F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
