import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../services/supabase_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _nimController = TextEditingController();
  final _universityController = TextEditingController();
  final _studyProgramController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  String? _selectedSemester;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final List<String> _semesters = List.generate(14, (index) => (index + 1).toString());

  // Eye Icon SVG (same as login)
  final String _eyeSvg = '''
<svg viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M1.37467 7.768C1.31911 7.91768 1.31911 8.08232 1.37467 8.232C1.9158 9.5441 2.83434 10.666 4.01385 11.4554C5.19335 12.2448 6.5807 12.6663 8 12.6663C9.4193 12.6663 10.8066 12.2448 11.9862 11.4554C13.1657 10.666 14.0842 9.5441 14.6253 8.232C14.6809 8.08232 14.6809 7.91768 14.6253 7.768C14.0842 6.4559 13.1657 5.33403 11.9862 4.5446C10.8066 3.75517 9.4193 3.33374 8 3.33374C6.5807 3.33374 5.19335 3.75517 4.01385 4.5446C2.83434 5.33403 1.9158 6.4559 1.37467 7.768Z" stroke="#757575" stroke-width="1.33333" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M8 10C9.10457 10 10 9.10457 10 8C10 6.89543 9.10457 6 8 6C6.89543 6 6 6.89543 6 8C6 9.10457 6.89543 10 8 10Z" stroke="#757575" stroke-width="1.33333" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

  final String _eyeCrossedSvg = '''
<svg viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M2.5 2.5L13.5 13.5" stroke="#757575" stroke-width="1.33333" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M8.5 4.5C9.4193 4.5 10.3066 4.92143 11.4862 5.7108C12.6657 6.5002 13.5842 7.6221 14.1253 8.934C14.1809 9.0837 14.1809 9.2483 14.1253 9.398C13.8 10.187 13.25 10.875 12.5 11.5" stroke="#757575" stroke-width="1.33333" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M9.5 9.5C9.07 9.83 8.57 10 8 10C6.89543 10 6 9.10457 6 8C6 7.43 6.17 6.93 6.5 6.5" stroke="#757575" stroke-width="1.33333" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M5.5 5.5C4.3193 6.0779 3.43434 7.0221 2.89385 8.334C2.83829 8.4837 2.83829 8.6483 2.89385 8.798C3.43498 10.1101 4.35352 11.232 5.53302 12.0214C6.71253 12.8108 8.09988 13.2323 9.51918 13.2323C10.4 13.2323 11.25 13.0623 12 12.7" stroke="#757575" stroke-width="1.33333" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // 1. Sign up user in Auth
        final response = await SupabaseService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        final user = response.user;
        if (user == null) {
          throw Exception('Gagal mendaftarkan user.');
        }

        // 2. Insert Profile data into 'profiles' table
        final profile = ProfileModel(
          id: user.id,
          email: _emailController.text.trim(),
          fullName: _nameController.text.trim(),
          nim: _nimController.text.trim(),
          university: _universityController.text.trim(),
          studyProgram: _studyProgramController.text.trim(),
          semester: int.tryParse(_selectedSemester ?? '1') ?? 1,
        );

        await SupabaseService.saveProfile(profile);

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFFFF6D00), size: 30),
                    const SizedBox(width: 10),
                    Text(
                      'Pendaftaran Berhasil',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: const Color(0xFF1E1E2F),
                      ),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: <Widget>[
                      Text(
                        'Akun MagangDay Anda berhasil dibuat dan disimpan ke database.',
                        style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575)),
                      ),
                      const SizedBox(height: 12),
                      _buildDataSummary('Nama', _nameController.text),
                      _buildDataSummary('Email', _emailController.text),
                      _buildDataSummary('NIM', _nimController.text),
                      _buildDataSummary('Universitas', _universityController.text),
                      _buildDataSummary('Prodi', _studyProgramController.text),
                      _buildDataSummary('Semester', _selectedSemester ?? ''),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text(
                      'Masuk Sekarang',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFF6D00),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(); // Dismiss Dialog
                      Navigator.of(context).pushReplacementNamed('/login'); // Go to Login
                    },
                  ),
                ],
              );
            },
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          String errorMsg = e.toString();
          if (e is AuthException) {
            errorMsg = e.message;
            if (e.message.contains('User already registered')) {
              errorMsg = 'Email ini sudah terdaftar';
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

  Widget _buildDataSummary(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: const Color(0xFF1E1E2F),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF555555),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _nimController.dispose();
    _universityController.dispose();
    _studyProgramController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktopWeb = screenWidth > 600;

    Widget registerContent = Container(
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
            // Decorative Orange Curve in Background
            Positioned(
              right: -50,
              top: -50,
              width: 200,
              height: 200,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFF9E00).withValues(alpha: 0.15),
                      const Color(0xFFFF6D00).withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 16),
                          
                          // Back Button
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E1E2F), size: 20),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                              Text(
                                'Kembali',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: const Color(0xFF1E1E2F),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Heading
                          Text(
                            'Daftar Akun',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E1E2F),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Lengkapi data dirimu untuk memulai log aktivitas magang.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: const Color(0xFF757575),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // --- Nama Lengkap ---
                          _buildLabel('NAMA LENGKAP'),
                          TextFormField(
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF1E1E2F)),
                            decoration: _inputDecoration(hintText: 'Nama lengkap Anda', icon: Icons.person_outline_rounded),
                            validator: (value) => value == null || value.trim().isEmpty ? 'Nama lengkap wajib diisi' : null,
                          ),
                          const SizedBox(height: 14),

                          // --- Email ---
                          _buildLabel('EMAIL'),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF1E1E2F)),
                            decoration: _inputDecoration(hintText: 'email@universitas.ac.id', icon: Icons.mail_outline_rounded),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Email wajib diisi';
                              final emailRegExp = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
                              if (!emailRegExp.hasMatch(value)) return 'Format email tidak valid';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // --- NIM & Semester Row ---
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // NIM
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('NIM'),
                                    TextFormField(
                                      controller: _nimController,
                                      keyboardType: TextInputType.number,
                                      textInputAction: TextInputAction.next,
                                      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF1E1E2F)),
                                      decoration: _inputDecoration(hintText: '12345678', icon: Icons.badge_outlined),
                                      validator: (value) => value == null || value.trim().isEmpty ? 'NIM wajib diisi' : null,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Semester
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('SEMESTER'),
                                    DropdownButtonFormField<String>(
                                      initialValue: _selectedSemester,
                                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF9E9E9E)),
                                      dropdownColor: Colors.white,
                                      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF1E1E2F)),
                                      decoration: _inputDecoration(hintText: 'Pilih'),
                                      items: _semesters.map((String sem) {
                                        return DropdownMenuItem<String>(
                                          value: sem,
                                          child: Text('Smstr $sem'),
                                        );
                                      }).toList(),
                                      onChanged: (String? val) {
                                        setState(() {
                                          _selectedSemester = val;
                                        });
                                      },
                                      validator: (value) => value == null ? 'Pilih' : null,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // --- Universitas ---
                          _buildLabel('UNIVERSITAS / SEKOLAH'),
                          TextFormField(
                            controller: _universityController,
                            textInputAction: TextInputAction.next,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF1E1E2F)),
                            decoration: _inputDecoration(hintText: 'Universitas Indonesia', icon: Icons.school_outlined),
                            validator: (value) => value == null || value.trim().isEmpty ? 'Nama universitas wajib diisi' : null,
                          ),
                          const SizedBox(height: 14),

                          // --- Program Studi ---
                          _buildLabel('PROGRAM STUDI'),
                          TextFormField(
                            controller: _studyProgramController,
                            textInputAction: TextInputAction.next,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF1E1E2F)),
                            decoration: _inputDecoration(hintText: 'Teknik Informatika', icon: Icons.book_outlined),
                            validator: (value) => value == null || value.trim().isEmpty ? 'Program studi wajib diisi' : null,
                          ),
                          const SizedBox(height: 14),

                          // --- Password ---
                          _buildLabel('PASSWORD'),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF1E1E2F)),
                            decoration: _inputDecoration(
                              hintText: 'Minimal 6 karakter',
                              icon: Icons.lock_outline_rounded,
                              suffixIcon: IconButton(
                                icon: SvgPicture.string(_obscurePassword ? _eyeSvg : _eyeCrossedSvg, width: 15, height: 15),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (value) => value == null || value.length < 6 ? 'Password minimal 6 karakter' : null,
                          ),
                          const SizedBox(height: 14),

                          // --- Confirm Password ---
                          _buildLabel('KONFIRMASI PASSWORD'),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            textInputAction: TextInputAction.done,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF1E1E2F)),
                            decoration: _inputDecoration(
                              hintText: 'Ulangi password Anda',
                              icon: Icons.lock_outline_rounded,
                              suffixIcon: IconButton(
                                icon: SvgPicture.string(_obscureConfirmPassword ? _eyeSvg : _eyeCrossedSvg, width: 15, height: 15),
                                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Konfirmasi password wajib diisi';
                              if (value != _passwordController.text) return 'Password tidak cocok';
                              return null;
                            },
                            onFieldSubmitted: (_) => _handleRegister(),
                          ),
                          const SizedBox(height: 24),

                          // --- Submit Button ---
                          Container(
                            height: 50,
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
                              onPressed: _isLoading ? null : _handleRegister,
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
                                      'Daftar Sekarang',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Back to Login Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Sudah memiliki akun? ',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: const Color(0xFF757575),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  'Masuk',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFFF6D00),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                        ],
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
            child: registerContent,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: registerContent,
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFFF6D00),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hintText, IconData? icon, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        color: const Color(0xFF9E9E9E),
      ),
      filled: true,
      fillColor: const Color(0xFFF9F9FB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      prefixIcon: icon != null ? Icon(icon, size: 18, color: const Color(0xFF9E9E9E)) : null,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE5E5E9),
          width: 1.0,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE5E5E9),
          width: 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFFF6D00),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.0,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
        ),
      ),
    );
  }
}
