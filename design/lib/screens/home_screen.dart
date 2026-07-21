import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../models/profile_model.dart';
import '../models/internship_model.dart';
import '../models/activity_log_model.dart';
import '../services/supabase_service.dart';
import '../services/report_service.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  ProfileModel? _profile;
  InternshipModel? _activeInternship;
  List<ActivityLogModel> _logs = [];
  
  String? _tempPhotoUrl;
  bool _isUploadingPhoto = false;
  
  bool _isLoadingAll = true;
  bool _isSubmitting = false;

  // Search and Filter States for HistoryScreen
  String _searchQuery = '';
  String _filterCategory = 'All';
  String _filterStatus = 'All';

  // Report range states
  String _reportRangeType = 'This Week'; // 'This Week', 'This Month', 'Custom'
  DateTimeRange? _customReportRange;

  // Form Controllers for Internship Bottom Sheet
  final _internshipFormKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _positionController = TextEditingController();
  final _mentorNameController = TextEditingController();
  final _mentorEmailController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  // Form Controllers for Activity Log Bottom Sheet
  final _logFormKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _projectController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _challengesController = TextEditingController();
  final _learningController = TextEditingController();
  final _techController = TextEditingController(); // Comma-separated input
  String _selectedCategory = 'Frontend Development';
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  // Form Controllers for Profile Edit Bottom Sheet
  final _profileFormKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _nimController = TextEditingController();
  final _universityController = TextEditingController();
  final _studyProgramController = TextEditingController();
  final _semesterController = TextEditingController();

  // Form Controllers for Change Password Bottom Sheet
  final _changePasswordFormKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final List<String> _categories = [
    'Frontend Development',
    'Backend Development',
    'Fullstack Development',
    'Database',
    'UI/UX Design',
    'Testing & QA',
    'Meeting',
    'Documentation',
    'Other'
  ];

  final List<Color> _chartColors = [
    const Color(0xFFFF6D00), // Orange
    const Color(0xFFFF9E00), // Amber
    const Color(0xFF3B82F6), // Blue
    const Color(0xFF10B981), // Green
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFFEC4899), // Pink
    const Color(0xFF64748B), // Slate
  ];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _companyController.dispose();
    _positionController.dispose();
    _mentorNameController.dispose();
    _mentorEmailController.dispose();
    
    _titleController.dispose();
    _projectController.dispose();
    _descriptionController.dispose();
    _challengesController.dispose();
    _learningController.dispose();
    _techController.dispose();

    _fullNameController.dispose();
    _nimController.dispose();
    _universityController.dispose();
    _studyProgramController.dispose();
    _semesterController.dispose();

    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- Premium Top Notification Overlay Helper ---
  void _showTopNotification(String message, {bool isError = false}) {
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isError ? const Color(0xFFFEE2E2) : const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isError ? Colors.redAccent : const Color(0xFFFF6D00),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                Icon(
                  isError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
                  color: isError ? Colors.redAccent : const Color(0xFFFF6D00),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isError ? const Color(0xFF991B1B) : const Color(0xFF9A3412),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    if (overlayEntry.mounted) {
                      overlayEntry.remove();
                    }
                  },
                  child: Icon(
                    Icons.close_rounded, 
                    size: 16, 
                    color: isError ? const Color(0xFF991B1B) : const Color(0xFF9A3412)
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    // Auto dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingAll = true;
    });

    final user = SupabaseService.currentUser;
    if (user != null) {
      try {
        // 1. Load Profile
        var profile = await SupabaseService.getProfile(user.id);
        if (profile == null) {
          final fullNameMetadata = user.userMetadata?['full_name'] ?? 
                                   user.userMetadata?['name'] ?? 
                                   'Mahasiswa Magang';
          profile = ProfileModel(
            id: user.id,
            email: user.email ?? '',
            fullName: fullNameMetadata.toString(),
            nim: '',
            university: '',
            studyProgram: '',
            semester: 1,
          );
          await SupabaseService.saveProfile(profile);
        }
        
        // 2. Load Active Internship
        final internship = await SupabaseService.getActiveInternship(user.id);
        
        // 3. Load Activity Logs if internship exists
        List<ActivityLogModel> logs = [];
        if (internship != null && internship.id != null) {
          logs = await SupabaseService.getActivityLogs(internship.id!);
        }

        if (mounted) {
          setState(() {
            _profile = profile;
            _activeInternship = internship;
            _logs = logs;
            _isLoadingAll = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoadingAll = false;
          });
          _showTopNotification('Gagal memuat data: ${e.toString()}', isError: true);
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoadingAll = false;
        });
      }
    }
  }

  void _handleLogout() async {
    await SupabaseService.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // --- Date Formatter Helpers ---
  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatDateLong(DateTime date) {
    final weekdays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    final String dayName = weekdays[date.weekday % 7];
    final String monthName = months[date.month - 1];
    
    return '$dayName, $monthName ${date.day}, ${date.year}';
  }

  // --- Statistics Calculation Helpers ---
  int _calculateWorkingDays() {
    final distinctDates = _logs.map((log) => log.activityDate.toIso8601String().split('T')[0]).toSet();
    return distinctDates.length;
  }

  String _calculateWorkingHours() {
    final totalMinutes = _logs.fold<int>(0, (sum, log) => sum + log.durationMinutes);
    final double hours = totalMinutes / 60.0;
    if (hours % 1 == 0) {
      return '${hours.toInt()}h';
    }
    return '${hours.toStringAsFixed(1)}h';
  }

  double _calculateInternshipProgress(InternshipModel internship) {
    final totalDays = internship.endDate.difference(internship.startDate).inDays;
    if (totalDays <= 0) return 0.0;
    
    final elapsedDays = DateTime.now().difference(internship.startDate).inDays;
    return (elapsedDays / totalDays).clamp(0.0, 1.0);
  }

  // --- Show Bottom Sheets ---
  void _showAddInternshipSheet() {
    if (_activeInternship != null) {
      _companyController.text = _activeInternship!.companyName;
      _positionController.text = _activeInternship!.position;
      _mentorNameController.text = _activeInternship!.mentorName ?? '';
      _mentorEmailController.text = _activeInternship!.mentorEmail ?? '';
      _startDate = _activeInternship!.startDate;
      _endDate = _activeInternship!.endDate;
    } else {
      _companyController.clear();
      _positionController.clear();
      _mentorNameController.clear();
      _mentorEmailController.clear();
      _startDate = null;
      _endDate = null;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _internshipFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _activeInternship != null ? 'Edit Informasi Magang' : 'Mulai Magang Baru',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E1E2F),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded, color: Color(0xFF9E9E9E)),
                            splashRadius: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Masukkan informasi tempat Anda melakukan kerja magang.',
                        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF757575)),
                      ),
                      const SizedBox(height: 20),

                      // Company Name
                      _buildFieldLabel('NAMA PERUSAHAAN *'),
                      TextFormField(
                        controller: _companyController,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13),
                        decoration: _inputDecoration(hintText: 'TechNova Software House'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Nama perusahaan wajib diisi' : null,
                      ),
                      const SizedBox(height: 14),

                      // Position
                      _buildFieldLabel('POSISI MAGANG *'),
                      TextFormField(
                        controller: _positionController,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13),
                        decoration: _inputDecoration(hintText: 'Full Stack Developer Intern'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Posisi magang wajib diisi' : null,
                      ),
                      const SizedBox(height: 14),

                      // Dates Selectors
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('TANGGAL MULAI *'),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _startDate ?? DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2030),
                                    );
                                    if (picked != null) {
                                      setSheetState(() => _startDate = picked);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9F9FB),
                                      border: Border.all(color: const Color(0xFFE5E5E9)),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _startDate == null ? 'Pilih Mulai' : _formatDate(_startDate!),
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            color: _startDate == null ? const Color(0xFF9E9E9E) : const Color(0xFF1E1E2F),
                                          ),
                                        ),
                                        const Icon(Icons.calendar_today, size: 16, color: Color(0xFF9E9E9E)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('TANGGAL SELESAI *'),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _endDate ?? _startDate ?? DateTime.now(),
                                      firstDate: _startDate ?? DateTime.now(),
                                      lastDate: DateTime(2030),
                                    );
                                    if (picked != null) {
                                      setSheetState(() => _endDate = picked);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9F9FB),
                                      border: Border.all(color: const Color(0xFFE5E5E9)),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _endDate == null ? 'Pilih Selesai' : _formatDate(_endDate!),
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            color: _endDate == null ? const Color(0xFF9E9E9E) : const Color(0xFF1E1E2F),
                                          ),
                                        ),
                                        const Icon(Icons.calendar_today, size: 16, color: Color(0xFF9E9E9E)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Mentor Name
                      _buildFieldLabel('NAMA MENTOR'),
                      TextFormField(
                        controller: _mentorNameController,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13),
                        decoration: _inputDecoration(hintText: 'Budi Santoso'),
                      ),
                      const SizedBox(height: 14),

                      // Mentor Email
                      _buildFieldLabel('EMAIL MENTOR'),
                      TextFormField(
                        controller: _mentorEmailController,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13),
                        decoration: _inputDecoration(hintText: 'budi@company.com'),
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : () => _submitInternship(setSheetState),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6D00),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                'Simpan Magang',
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitInternship(StateSetter setSheetState) async {
    if (_internshipFormKey.currentState!.validate()) {
      if (_startDate == null || _endDate == null) {
        _showTopNotification('Tanggal mulai dan selesai wajib dipilih', isError: true);
        return;
      }
      if (_startDate!.isAfter(_endDate!)) {
        _showTopNotification('Tanggal mulai tidak boleh setelah tanggal selesai', isError: true);
        return;
      }

      setSheetState(() => _isSubmitting = true);
      final user = SupabaseService.currentUser;
      if (user != null) {
        try {
          final internship = InternshipModel(
            id: _activeInternship?.id,
            userId: user.id,
            companyName: _companyController.text.trim(),
            position: _positionController.text.trim(),
            mentorName: _mentorNameController.text.trim().isEmpty ? null : _mentorNameController.text.trim(),
            mentorEmail: _mentorEmailController.text.trim().isEmpty ? null : _mentorEmailController.text.trim(),
            startDate: _startDate!,
            endDate: _endDate!,
          );

          await SupabaseService.saveInternship(internship);
          
          if (mounted) {
            Navigator.pop(context); // Close Bottom Sheet
            _loadAllData(); // Reload main dashboard
          }
        } catch (e) {
          if (mounted) {
            _showTopNotification('Gagal menyimpan: ${e.toString()}', isError: true);
          }
        } finally {
          if (mounted) {
            setSheetState(() => _isSubmitting = false);
          }
        }
      }
    }
  }

  void _showEditProfileSheet() {
    _tempPhotoUrl = _profile?.profilePhotoUrl;
    _isUploadingPhoto = false;
    if (_profile != null) {
      _fullNameController.text = _profile!.fullName;
      _nimController.text = _profile!.nim;
      _universityController.text = _profile!.university;
      _studyProgramController.text = _profile!.studyProgram;
      _semesterController.text = _profile!.semester.toString();
    } else {
      _fullNameController.clear();
      _nimController.clear();
      _universityController.clear();
      _studyProgramController.clear();
      _semesterController.text = '1';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _profileFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Edit Profil Mahasiswa',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E1E2F),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded, color: Color(0xFF9E9E9E)),
                            splashRadius: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ubah data diri dan informasi akademik Anda.',
                        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF757575)),
                      ),
                      const SizedBox(height: 20),

                      // Profile Photo Upload Section
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFFF6D00), width: 2),
                                color: const Color(0xFFFFEDD5),
                                image: (_tempPhotoUrl != null && _tempPhotoUrl!.isNotEmpty)
                                    ? DecorationImage(
                                        image: NetworkImage(_tempPhotoUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: (_tempPhotoUrl != null && _tempPhotoUrl!.isNotEmpty)
                                  ? null
                                  : Text(
                                      _fullNameController.text.isNotEmpty
                                          ? _fullNameController.text[0].toUpperCase()
                                          : 'M',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 34,
                                        color: const Color(0xFFFF6D00),
                                      ),
                                    ),
                            ),
                            if (_isUploadingPhoto)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black.withValues(alpha: 0.4),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _isUploadingPhoto ? null : () => _pickAndUploadImage(setSheetState),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFFF6D00),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Full Name
                      _buildFieldLabel('NAMA LENGKAP *'),
                      TextFormField(
                        controller: _fullNameController,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13),
                        decoration: _inputDecoration(hintText: 'Nama Lengkap'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Nama lengkap wajib diisi' : null,
                      ),
                      const SizedBox(height: 14),

                      // NIM
                      _buildFieldLabel('NIM *'),
                      TextFormField(
                        controller: _nimController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13),
                        decoration: _inputDecoration(hintText: 'NIM'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'NIM wajib diisi' : null,
                      ),
                      const SizedBox(height: 14),

                      // University
                      _buildFieldLabel('UNIVERSITAS *'),
                      TextFormField(
                        controller: _universityController,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13),
                        decoration: _inputDecoration(hintText: 'Nama Universitas'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Nama universitas wajib diisi' : null,
                      ),
                      const SizedBox(height: 14),

                      // Study Program
                      _buildFieldLabel('PROGRAM STUDI *'),
                      TextFormField(
                        controller: _studyProgramController,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13),
                        decoration: _inputDecoration(hintText: 'Nama Program Studi'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Program studi wajib diisi' : null,
                      ),
                      const SizedBox(height: 14),

                      // Semester Dropdown
                      _buildFieldLabel('SEMESTER *'),
                      DropdownButtonFormField<String>(
                        initialValue: _semesterController.text.isEmpty ? '1' : _semesterController.text,
                        dropdownColor: Colors.white,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF1E1E2F)),
                        decoration: _inputDecoration(hintText: 'Pilih Semester'),
                        items: List.generate(12, (index) => (index + 1).toString()).map((sem) {
                          return DropdownMenuItem<String>(
                            value: sem,
                            child: Text('Semester $sem'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setSheetState(() => _semesterController.text = val);
                          }
                        },
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : () => _submitProfile(setSheetState),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6D00),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                'Simpan Perubahan',
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitProfile(StateSetter setSheetState) async {
    if (_profileFormKey.currentState!.validate()) {
      setSheetState(() => _isSubmitting = true);
      final user = SupabaseService.currentUser;
      if (user != null) {
        try {
          final updatedProfile = ProfileModel(
            id: user.id,
            email: _profile?.email ?? user.email ?? '',
            fullName: _fullNameController.text.trim(),
            nim: _nimController.text.trim(),
            university: _universityController.text.trim(),
            studyProgram: _studyProgramController.text.trim(),
            semester: int.tryParse(_semesterController.text) ?? 1,
            profilePhotoUrl: _tempPhotoUrl,
          );

          await SupabaseService.saveProfile(updatedProfile);
          
          if (mounted) {
            Navigator.pop(context); // Close Bottom Sheet
            _loadAllData(); // Reload main dashboard
          }
        } catch (e) {
          if (mounted) {
            _showTopNotification('Gagal menyimpan: ${e.toString()}', isError: true);
          }
        } finally {
          if (mounted) {
            setSheetState(() => _isSubmitting = false);
          }
        }
      }
    }
  }

  Future<void> _pickAndUploadImage(StateSetter setSheetState) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );

      if (image == null) return;

      setSheetState(() {
        _isUploadingPhoto = true;
      });

      final bytes = await image.readAsBytes();
      final extension = image.path.split('.').last.toLowerCase();
      final user = SupabaseService.currentUser;

      if (user == null) throw Exception('User tidak ditemukan.');

      final String publicUrl = await SupabaseService.uploadAvatar(
        userId: user.id,
        fileBytes: bytes,
        extension: extension,
      );

      setSheetState(() {
        _tempPhotoUrl = publicUrl;
        _isUploadingPhoto = false;
      });
    } catch (e) {
      setSheetState(() {
        _isUploadingPhoto = false;
      });
      if (mounted) {
        _showTopNotification('Gagal mengupload foto: ${e.toString()}', isError: true);
      }
    }
  }

  void _showChangePasswordSheet() {
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _changePasswordFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Ubah Kata Sandi',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E1E2F),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded, color: Color(0xFF9E9E9E)),
                            splashRadius: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Masukkan kata sandi baru Anda.',
                        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF757575)),
                      ),
                      const SizedBox(height: 20),

                      // New Password
                      _buildFieldLabel('KATA SANDI BARU *'),
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: true,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13),
                        decoration: _inputDecoration(hintText: 'Masukkan kata sandi baru'),
                        validator: (v) => v == null || v.length < 6 ? 'Kata sandi minimal 6 karakter' : null,
                      ),
                      const SizedBox(height: 14),

                      // Confirm Password
                      _buildFieldLabel('KONFIRMASI KATA SANDI BARU *'),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13),
                        decoration: _inputDecoration(hintText: 'Konfirmasi kata sandi baru'),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Konfirmasi kata sandi wajib diisi';
                          if (v != _newPasswordController.text) return 'Kata sandi tidak cocok';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : () => _submitChangePassword(setSheetState),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6D00),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                'Simpan Kata Sandi',
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitChangePassword(StateSetter setSheetState) async {
    if (_changePasswordFormKey.currentState!.validate()) {
      setSheetState(() => _isSubmitting = true);
      try {
        await SupabaseService.updatePassword(_newPasswordController.text.trim());
        if (mounted) {
          Navigator.pop(context); // Close Bottom Sheet
          _showTopNotification('Kata sandi berhasil diperbarui!', isError: false);
        }
      } catch (e) {
        if (mounted) {
          _showTopNotification('Gagal memperbarui sandi: ${e.toString()}', isError: true);
        }
      } finally {
        if (mounted) {
          setSheetState(() => _isSubmitting = false);
        }
      }
    }
  }

  void _showHelpSupportSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: 24 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bantuan & Dukungan',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E1E2F),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF9E9E9E)),
                    splashRadius: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Email Support Box
              _buildContactSupportCard(
                icon: Icons.email_rounded,
                title: 'Email Developer',
                value: 'myahyazahid11@gmail.com',
                onCopy: () {
                  Clipboard.setData(const ClipboardData(text: 'myahyazahid11@gmail.com'));
                  Navigator.pop(context);
                  _showTopNotification('Email berhasil disalin!', isError: false);
                },
              ),
              const SizedBox(height: 12),

              // WhatsApp Support Box
              _buildContactSupportCard(
                icon: Icons.chat_rounded,
                title: 'WhatsApp Developer',
                value: '081216771939',
                onCopy: () {
                  Clipboard.setData(const ClipboardData(text: '081216771939'));
                  Navigator.pop(context);
                  _showTopNotification('Nomor WhatsApp berhasil disalin!', isError: false);
                },
              ),
              const SizedBox(height: 20),

              // Additional footer instruction text
              Text(
                'Hubungi developer untuk memperoleh bantuan lebih lanjut',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleDownloadPdf(List<ActivityLogModel> filteredLogs) async {
    if (_profile == null) {
      _showTopNotification('Data profil mahasiswa belum dimuat.', isError: true);
      return;
    }
    _showTopNotification('Menyiapkan laporan PDF...', isError: false);
    try {
      await ReportService.generatePdfReport(
        profile: _profile!,
        internship: _activeInternship,
        logs: filteredLogs,
      );
    } catch (e) {
      _showTopNotification('Gagal membuat PDF: ${e.toString()}', isError: true);
    }
  }

  Future<void> _handleDownloadExcel(List<ActivityLogModel> filteredLogs) async {
    if (_profile == null) {
      _showTopNotification('Data profil mahasiswa belum dimuat.', isError: true);
      return;
    }
    _showTopNotification('Menyiapkan laporan Excel...', isError: false);
    try {
      await ReportService.generateExcelReport(
        profile: _profile!,
        internship: _activeInternship,
        logs: filteredLogs,
      );
    } catch (e) {
      _showTopNotification('Gagal membuat Excel: ${e.toString()}', isError: true);
    }
  }


  Widget _buildContactSupportCard({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onCopy,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFFFEDD5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFFFF6D00), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1E1E2F)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCopy,
            icon: const Icon(Icons.copy_rounded, color: Color(0xFFFF6D00), size: 18),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  void _showAddLogSheet() {
    if (_activeInternship == null || _activeInternship!.id == null) {
      _showTopNotification('Tambahkan data magang terlebih dahulu', isError: true);
      return;
    }

    _titleController.clear();
    _projectController.clear();
    _descriptionController.clear();
    _challengesController.clear();
    _learningController.clear();
    _techController.clear();
    _startTime = null;
    _endTime = null;
    _selectedCategory = 'Frontend Development';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _logFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Catat Log Aktivitas',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E1E2F),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded, color: Color(0xFF9E9E9E)),
                            splashRadius: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tuliskan log pekerjaan dan detail pencapaian magang Anda hari ini.',
                        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF757575)),
                      ),
                      const SizedBox(height: 20),

                      // Title
                      _buildFieldLabel('JUDUL AKTIVITAS *'),
                      TextFormField(
                        controller: _titleController,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13),
                        decoration: _inputDecoration(hintText: 'Build authentication flow'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Judul aktivitas wajib diisi' : null,
                      ),
                      const SizedBox(height: 14),

                      // Project Name
                      _buildFieldLabel('NAMA PROYEK / FITUR'),
                      TextFormField(
                        controller: _projectController,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13),
                        decoration: _inputDecoration(hintText: 'TechNova CRM'),
                      ),
                      const SizedBox(height: 14),

                      // Category Dropdown
                      _buildFieldLabel('KATEGORI AKTIVITAS *'),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        dropdownColor: Colors.white,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF1E1E2F)),
                        decoration: _inputDecoration(hintText: 'Pilih Kategori'),
                        items: _categories.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat,
                            child: Text(cat),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setSheetState(() => _selectedCategory = val);
                          }
                        },
                      ),
                      const SizedBox(height: 14),

                      // Time Selectors
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('JAM MULAI *'),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showTimePicker(
                                      context: context,
                                      initialTime: const TimeOfDay(hour: 9, minute: 0),
                                    );
                                    if (picked != null) {
                                      setSheetState(() => _startTime = picked);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9F9FB),
                                      border: Border.all(color: const Color(0xFFE5E5E9)),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _startTime == null ? 'Jam Mulai' : _startTime!.format(context),
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            color: _startTime == null ? const Color(0xFF9E9E9E) : const Color(0xFF1E1E2F),
                                          ),
                                        ),
                                        const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF9E9E9E)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('JAM SELESAI *'),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showTimePicker(
                                      context: context,
                                      initialTime: _startTime ?? const TimeOfDay(hour: 17, minute: 0),
                                    );
                                    if (picked != null) {
                                      setSheetState(() => _endTime = picked);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9F9FB),
                                      border: Border.all(color: const Color(0xFFE5E5E9)),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _endTime == null ? 'Jam Selesai' : _endTime!.format(context),
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            color: _endTime == null ? const Color(0xFF9E9E9E) : const Color(0xFF1E1E2F),
                                          ),
                                        ),
                                        const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF9E9E9E)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Description
                      _buildFieldLabel('DESKRIPSI PEKERJAAN *'),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13),
                        decoration: _inputDecoration(hintText: 'Menyusun validasi form dan menghubungkan service API Auth...'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Deskripsi pekerjaan wajib diisi' : null,
                      ),
                      const SizedBox(height: 14),

                      // Technologies Used
                      _buildFieldLabel('TEKNOLOGI YANG DIGUNAKAN (Pisahkan dengan koma)'),
                      TextFormField(
                        controller: _techController,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13),
                        decoration: _inputDecoration(hintText: 'Flutter, Supabase, Dart'),
                      ),
                      const SizedBox(height: 14),

                      // Challenges
                      _buildFieldLabel('TANTANGAN & MASALAH (OPSIONAL)'),
                      TextFormField(
                        controller: _challengesController,
                        maxLines: 2,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13),
                        decoration: _inputDecoration(hintText: 'Ada sedikit error CORS saat integrasi API Auth.'),
                      ),
                      const SizedBox(height: 14),

                      // Learning Outcomes
                      _buildFieldLabel('PELAJARAN YANG DIPEROLEH (OPSIONAL)'),
                      TextFormField(
                        controller: _learningController,
                        maxLines: 2,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13),
                        decoration: _inputDecoration(hintText: 'Memahami flow integrasi OAuth di client side.'),
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : () => _submitLog(setSheetState),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6D00),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                'Simpan Log Aktivitas',
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitLog(StateSetter setSheetState) async {
    if (_logFormKey.currentState!.validate()) {
      if (_startTime == null || _endTime == null) {
        _showTopNotification('Jam mulai dan selesai wajib dipilih', isError: true);
        return;
      }

      setSheetState(() => _isSubmitting = true);
      final user = SupabaseService.currentUser;
      
      if (user != null && _activeInternship != null && _activeInternship!.id != null) {
        try {
          // Calculate duration minutes
          final int startMinutes = _startTime!.hour * 60 + _startTime!.minute;
          final int endMinutes = _endTime!.hour * 60 + _endTime!.minute;
          int duration = endMinutes - startMinutes;
          if (duration < 0) {
            duration += 24 * 60;
          }

          // Parse technologies
          final List<String> techList = _techController.text.trim().isNotEmpty
              ? _techController.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList()
              : [];

          // Format Time for PostgreSQL (HH:MM:SS)
          final String startStr = '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}:00';
          final String endStr = '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}:00';

          final log = ActivityLogModel(
            internshipId: _activeInternship!.id!,
            userId: user.id,
            activityDate: DateTime.now(),
            title: _titleController.text.trim(),
            projectName: _projectController.text.trim().isEmpty ? null : _projectController.text.trim(),
            category: _selectedCategory,
            description: _descriptionController.text.trim(),
            startTime: startStr,
            endTime: endStr,
            durationMinutes: duration,
            technologies: techList,
            challenges: _challengesController.text.trim().isEmpty ? null : _challengesController.text.trim(),
            learning: _learningController.text.trim().isEmpty ? null : _learningController.text.trim(),
          );

          await SupabaseService.saveActivityLog(log);
          
          if (mounted) {
            Navigator.pop(context); // Close Bottom Sheet
            _loadAllData(); // Reload main dashboard
          }
        } catch (e) {
          if (mounted) {
            _showTopNotification('Gagal menyimpan log: ${e.toString()}', isError: true);
          }
        } finally {
          if (mounted) {
            setSheetState(() => _isSubmitting = false);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktopWeb = screenWidth > 600;

    Widget mainContent = Container(
      width: isDesktopWeb ? 360 : double.infinity,
      height: isDesktopWeb ? 800 : double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: isDesktopWeb ? BorderRadius.circular(36) : BorderRadius.zero,
      ),
      child: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: ClipRRect(
                borderRadius: isDesktopWeb 
                    ? const BorderRadius.vertical(top: Radius.circular(36)) 
                    : BorderRadius.zero,
                child: _isLoadingAll
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFFF6D00),
                        ),
                      )
                    : _currentIndex == 3
                        ? _buildProfileView()
                        : _currentIndex == 1
                            ? _buildHistoryView()
                            : _currentIndex == 2
                                ? _buildReportsView()
                                : RefreshIndicator(
                                    color: const Color(0xFFFF6D00),
                                    onRefresh: _loadAllData,
                                    child: _buildHomeView(),
                                  ),
              ),
            ),
          ),

          // Bottom Navigation Bar
          SafeArea(
            top: false,
            bottom: true,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                border: const Border(
                  top: BorderSide(
                    color: Color(0xFFE2E8F0),
                    width: 0.8,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.home_rounded, 'Home'),
                  _buildNavItem(1, Icons.assignment_outlined, 'Log Activity'),
                  _buildNavItem(2, Icons.bar_chart_rounded, 'Reports'),
                  _buildNavItem(3, Icons.person_rounded, 'Profile'),
                ],
              ),
            ),
          ),
        ],
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
            child: mainContent,
          ),
        ),
        floatingActionButton: _currentIndex == 1 && _activeInternship != null
            ? FloatingActionButton(
                onPressed: _showAddLogSheet,
                backgroundColor: const Color(0xFFFF6D00),
                foregroundColor: Colors.white,
                child: const Icon(Icons.add_rounded),
              )
            : null,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: mainContent,
      floatingActionButton: _currentIndex == 1 && _activeInternship != null
          ? Padding(
              padding: EdgeInsets.only(
                bottom: 72.0 + MediaQuery.of(context).padding.bottom,
              ),
              child: FloatingActionButton(
                onPressed: _showAddLogSheet,
                backgroundColor: const Color(0xFFFF6D00),
                foregroundColor: Colors.white,
                child: const Icon(Icons.add_rounded),
              ),
            )
          : null,
    );
  }

  // --- Home Tab View ---
  Widget _buildHomeView() {
    final String studentName = _profile?.fullName ?? 'Mahasiswa!';
    final String initial = studentName.isNotEmpty ? studentName[0].toUpperCase() : 'M';

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          
          // --- Header Row ---
          Row(
            children: [
              // Profile Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    )
                  ],
                  color: const Color(0xFFFFE0B2),
                  image: (_profile?.profilePhotoUrl != null && _profile!.profilePhotoUrl!.isNotEmpty)
                      ? DecorationImage(
                          image: NetworkImage(_profile!.profilePhotoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: (_profile?.profilePhotoUrl != null && _profile!.profilePhotoUrl!.isNotEmpty)
                    ? null
                    : Text(
                        initial,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: const Color(0xFFFF6D00),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              // Greeting Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good Evening,',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    Text(
                      studentName,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        color: const Color(0xFF0A0A0A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.8, vertical: 4.0),
                decoration: BoxDecoration(
                  color: _activeInternship != null ? const Color(0xFFD0FAE5) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _activeInternship != null ? const Color(0xFF00BC7D) : const Color(0xFF94A3B8),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _activeInternship != null ? 'Active Internship' : 'No Internship',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _activeInternship != null ? const Color(0xFF007A55) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // --- Current Internship Card ---
          _activeInternship != null 
              ? _buildActiveInternshipCard(_activeInternship!)
              : _buildEmptyInternshipCard(),
          const SizedBox(height: 20),

          // --- Stat Cards Row ---
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.calendar_today_rounded,
                  value: _activeInternship != null ? _calculateWorkingDays().toString() : '0',
                  title: 'Working Days',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.assignment_rounded,
                  value: _activeInternship != null ? _logs.length.toString() : '0',
                  title: 'Activities',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.access_time_rounded,
                  value: _activeInternship != null ? _calculateWorkingHours() : '0h',
                  title: 'Working Hours',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // --- Today's Activity Section ---
          Text(
            "Today's Activity",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0A0A0A),
            ),
          ),
          const SizedBox(height: 8),
          CustomPaint(
            painter: DashedRectPainter(
              color: const Color(0xFFCAD5E2),
              strokeWidth: 1.0,
              gap: 4.0,
            ),
            child: Container(
              padding: const EdgeInsets.all(20.8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _logs.any((l) => l.activityDate.toIso8601String().split('T')[0] == DateTime.now().toIso8601String().split('T')[0])
                        ? "You have logged activity for today!"
                        : "You haven't added today's activity yet.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _activeInternship == null ? null : _showAddLogSheet,
                    icon: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                    label: Text(
                      "Add Today's Log",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEA580C),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // --- Recent Activities Section ---
          Text(
            "Recent Activities",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0A0A0A),
            ),
          ),
          const SizedBox(height: 8),
          _logs.isEmpty
              ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  alignment: Alignment.center,
                  child: Text(
                    'Belum ada log aktivitas. Tambahkan di atas.',
                    style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _logs.length > 3 ? 3 : _logs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    return _buildActivityCard(log);
                  },
                ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // --- Activity History Tab View ---
  Widget _buildHistoryView() {
    final filteredLogs = _logs.where((log) {
      final matchesQuery = log.title.toLowerCase().contains(_searchQuery) ||
          (log.description != null && log.description!.toLowerCase().contains(_searchQuery)) ||
          (log.projectName != null && log.projectName!.toLowerCase().contains(_searchQuery));
          
      final matchesCategory = _filterCategory == 'All' || log.category == _filterCategory;
      final matchesStatus = _filterStatus == 'All' || log.status == _filterStatus;
      
      return matchesQuery && matchesCategory && matchesStatus;
    }).toList();

    // Grouping by date long string
    final Map<String, List<ActivityLogModel>> groupedLogs = {};
    for (var log in filteredLogs) {
      final dateKey = _formatDateLong(log.activityDate);
      if (!groupedLogs.containsKey(dateKey)) {
        groupedLogs[dateKey] = [];
      }
      groupedLogs[dateKey]!.add(log);
    }

    final dateKeys = groupedLogs.keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Card
        Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Activity History',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E1E2F),
                ),
              ),
              const SizedBox(height: 14),
              // Search input
              Container(
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim().toLowerCase();
                    });
                  },
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1E1E2F)),
                  decoration: InputDecoration(
                    hintText: 'Search activities...',
                    hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Filters Row
              Row(
                children: [
                  Expanded(
                    child: PopupMenuButton<String>(
                      onSelected: (val) {
                        setState(() {
                          _filterCategory = val;
                        });
                      },
                      itemBuilder: (context) {
                        return ['All', ..._categories].map((cat) {
                          return PopupMenuItem<String>(
                            value: cat,
                            child: Text(cat),
                          );
                        }).toList();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _filterCategory == 'All' ? 'All Categories' : _filterCategory,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF1E1E2F)),
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF9E9E9E)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PopupMenuButton<String>(
                      onSelected: (val) {
                        setState(() {
                          _filterStatus = val;
                        });
                      },
                      itemBuilder: (context) {
                        return ['All', 'Completed', 'In Progress', 'Pending'].map((st) {
                          return PopupMenuItem<String>(
                            value: st,
                            child: Text(st),
                          );
                        }).toList();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _filterStatus == 'All' ? 'All Status' : _filterStatus,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF1E1E2F)),
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF9E9E9E)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),

        // Grouped activities list
        Expanded(
          child: RefreshIndicator(
            color: const Color(0xFFFF6D00),
            onRefresh: _loadAllData,
            child: filteredLogs.isEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: Text(
                        'Tidak ada log aktivitas ditemukan.',
                        style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13),
                      ),
                    ),
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: dateKeys.length,
                    itemBuilder: (context, index) {
                      final dateKey = dateKeys[index];
                      final logsForDay = groupedLogs[dateKey]!;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                            child: Text(
                              dateKey,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          ...logsForDay.map((log) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: _buildActivityCard(log),
                            );
                          }),
                        ],
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  // --- Reports Tab View ---
  Widget _buildReportsView() {
    // 1. Get filtered logs based on selected range type
    final now = DateTime.now();
    DateTime startLimit;
    DateTime endLimit = DateTime(now.year, now.month, now.day, 23, 59, 59);

    if (_reportRangeType == 'This Week') {
      final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
      startLimit = monday;
    } else if (_reportRangeType == 'This Month') {
      startLimit = DateTime(now.year, now.month, 1);
    } else {
      // Custom Range
      if (_customReportRange != null) {
        startLimit = DateTime(_customReportRange!.start.year, _customReportRange!.start.month, _customReportRange!.start.day);
        endLimit = DateTime(_customReportRange!.end.year, _customReportRange!.end.month, _customReportRange!.end.day, 23, 59, 59);
      } else {
        startLimit = DateTime(now.year, now.month, 1); // Fallback
      }
    }

    final filteredLogs = _logs.where((log) {
      return log.activityDate.isAfter(startLimit.subtract(const Duration(seconds: 1))) &&
          log.activityDate.isBefore(endLimit.add(const Duration(seconds: 1)));
    }).toList();

    // 2. Calculate dynamic stats
    final int totalDays = filteredLogs.map((log) => log.activityDate.toIso8601String().split('T')[0]).toSet().length;
    final int totalMinutes = filteredLogs.fold<int>(0, (sum, log) => sum + log.durationMinutes);
    final double totalHours = totalMinutes / 60.0;
    final int completedCount = filteredLogs.where((log) => log.status == 'Completed').length;

    // 3. Category distribution data
    final Map<String, int> categoryCounts = {};
    for (var log in filteredLogs) {
      final cat = log.category ?? 'Other';
      categoryCounts[cat] = (categoryCounts[cat] ?? 0) + 1;
    }

    // 4. Daily logs & hours count (Mon - Sun)
    final List<int> dailyActivities = List.filled(7, 0);
    final List<double> dailyHours = List.filled(7, 0.0);

    for (var log in filteredLogs) {
      // weekday is 1 for Mon, 7 for Sun. Convert to index 0 - 6
      final idx = log.activityDate.weekday - 1;
      if (idx >= 0 && idx < 7) {
        dailyActivities[idx]++;
        dailyHours[idx] += log.durationMinutes / 60.0;
      }
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          // Heading
          Text(
            'Reports',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E1E2F),
            ),
          ),
          const SizedBox(height: 14),

          // Range Selector Buttons
          Row(
            children: [
              _buildRangeButton('This Week', () {
                setState(() {
                  _reportRangeType = 'This Week';
                });
              }),
              const SizedBox(width: 8),
              _buildRangeButton('This Month', () {
                setState(() {
                  _reportRangeType = 'This Month';
                });
              }),
              const SizedBox(width: 8),
              _buildRangeButton(
                _reportRangeType == 'Custom' && _customReportRange != null
                    ? '${_formatDate(_customReportRange!.start)} - ${_formatDate(_customReportRange!.end)}'
                    : 'Custom Range', 
                () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    initialDateRange: _customReportRange,
                  );
                  if (picked != null) {
                    setState(() {
                      _reportRangeType = 'Custom';
                      _customReportRange = picked;
                    });
                  }
                },
                isCustom: true,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildReportStatCard(
                  icon: Icons.calendar_month_rounded,
                  value: totalDays.toString(),
                  label: 'Internship Days',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildReportStatCard(
                  icon: Icons.access_time_filled_rounded,
                  value: totalHours % 1 == 0 ? '${totalHours.toInt()}h' : '${totalHours.toStringAsFixed(1)}h',
                  label: 'Working Hours',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildReportStatCard(
                  icon: Icons.check_circle_rounded,
                  value: completedCount.toString(),
                  label: 'Completed',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Donut Chart - Categories Breakdown
          _buildChartCard(
            title: 'Activity Categories',
            child: Row(
              children: [
                SizedBox(
                  width: 110,
                  height: 110,
                  child: CustomPaint(
                    painter: DonutChartPainter(data: categoryCounts, colors: _chartColors),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: categoryCounts.isEmpty
                      ? Center(
                          child: Text(
                            'No category data available.',
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: categoryCounts.entries.map((entry) {
                            final idx = categoryCounts.keys.toList().indexOf(entry.key);
                            final color = _chartColors[idx % _chartColors.length];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      entry.key,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                                    ),
                                  ),
                                  Text(
                                    entry.value.toString(),
                                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF1E1E2F)),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Bar Chart - Daily Activities
          _buildChartCard(
            title: 'Activities per Week',
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SizedBox(
                  width: constraints.maxWidth,
                  height: 180,
                  child: CustomPaint(
                    painter: BarChartPainter(values: dailyActivities),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Line Chart - Working Hours per Week
          _buildChartCard(
            title: 'Working Hours per Week',
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SizedBox(
                  width: constraints.maxWidth,
                  height: 180,
                  child: CustomPaint(
                    painter: LineChartPainter(values: dailyHours),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Report Actions Footer Buttons
          ElevatedButton.icon(
            onPressed: () => _handleDownloadPdf(filteredLogs),
            icon: const Icon(Icons.document_scanner_rounded, size: 16),
            label: Text(
              'Generate Internship Report',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6D00),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handleDownloadPdf(filteredLogs),
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                  label: Text('PDF', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF6D00),
                    side: const BorderSide(color: Color(0xFFFF6D00)),
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handleDownloadExcel(filteredLogs),
                  icon: const Icon(Icons.table_chart_rounded, size: 16),
                  label: Text('Excel', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF6D00),
                    side: const BorderSide(color: Color(0xFFFF6D00)),
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRangeButton(String label, VoidCallback onTap, {bool isCustom = false}) {
    final bool isActive = (isCustom && _reportRangeType == 'Custom') || 
        (!isCustom && _reportRangeType == label);
        
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6.8),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFFFEAD5) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isActive ? const Color(0xFFFF6D00) : Colors.transparent),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isActive ? const Color(0xFFFF6D00) : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportStatCard({required IconData icon, required String value, required String label}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 3,
          )
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFFFEDD5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFFFF6D00), size: 16),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E1E2F)),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 5,
          )
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1E1E2F)),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  // --- Active Internship Card Widget ---
  Widget _buildActiveInternshipCard(InternshipModel internship) {
    final progress = _calculateInternshipProgress(internship);
    final progressPercent = '${(progress * 100).toInt()}%';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF6900),
            Color(0xFFFF8904),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 7.5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.business_center_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      internship.companyName,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      internship.position,
                      style: GoogleFonts.inter(
                        color: const Color(0xFFFFF7ED),
                        fontWeight: FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Date Row
          Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                color: Color(0xFFFFF7ED),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                '${_formatDate(internship.startDate)} – ${_formatDate(internship.endDate)}',
                style: GoogleFonts.inter(
                  color: const Color(0xFFFFF7ED),
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Internship progress',
                style: GoogleFonts.inter(
                  color: const Color(0xFFFFF7ED),
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
              Text(
                progressPercent,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Custom Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFEA580C),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Empty Internship Card Widget ---
  Widget _buildEmptyInternshipCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 7.5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEDD5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.business_center_rounded,
                  color: Color(0xFFFF6D00),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Magang Aktif',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: const Color(0xFF1E1E2F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada magang aktif yang terdaftar. Tambahkan informasi magang Anda untuk mulai mencatat log aktivitas.',
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B), height: 1.4),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _showAddInternshipSheet,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6D00),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              '+ Mulai Magang Baru',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // --- Profile Tab View ---
  Widget _buildProfileView() {
    final String name = _profile?.fullName ?? 'Belum ada nama';
    final String nim = _profile?.nim ?? '-';
    final String university = _profile?.university ?? '-';
    final String studyProgram = _profile?.studyProgram ?? '-';
    final String semester = _profile?.semester.toString() ?? '1';
    
    final String userUuid = SupabaseService.currentUser?.id ?? '';
    final String truncatedUuid = userUuid.length > 8 ? userUuid.substring(0, 8) : userUuid;
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : 'Y';

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          // --- Profile Header ---
          Center(
            child: Column(
              children: [
                // Avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                    color: const Color(0xFFFFEDD5),
                    image: (_profile?.profilePhotoUrl != null && _profile!.profilePhotoUrl!.isNotEmpty)
                        ? DecorationImage(
                            image: NetworkImage(_profile!.profilePhotoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: (_profile?.profilePhotoUrl != null && _profile!.profilePhotoUrl!.isNotEmpty)
                      ? null
                      : Text(
                          initial,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                            color: const Color(0xFFFF6D00),
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                // Name
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E1E2F),
                  ),
                ),
                const SizedBox(height: 6),
                // User UUID Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.vpn_key_rounded, size: 12, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        truncatedUuid,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- Student Information Card ---
          _buildInfoCardGroup(
            title: 'Student Information',
            children: [
              _buildInfoRow(Icons.person_rounded, 'Full Name', name),
              _buildInfoRow(Icons.badge_rounded, 'Student ID / NIM', nim),
              _buildInfoRow(Icons.school_rounded, 'University', university),
              _buildInfoRow(Icons.book_rounded, 'Study Program', studyProgram),
              _buildInfoRow(Icons.calendar_month_rounded, 'Semester', 'Semester $semester'),
            ],
          ),
          const SizedBox(height: 16),

          // --- Internship Information Card ---
          _buildInfoCardGroup(
            title: 'Internship Information',
            children: _activeInternship != null
                ? [
                    _buildInfoRow(Icons.business_center_rounded, 'Company', _activeInternship!.companyName),
                    _buildInfoRow(Icons.work_rounded, 'Position', _activeInternship!.position),
                    _buildInfoRow(Icons.person_pin_rounded, 'Supervisor / Mentor', _activeInternship!.mentorName ?? '-'),
                    _buildInfoRow(Icons.date_range_rounded, 'Start Date', _formatDate(_activeInternship!.startDate)),
                    _buildInfoRow(Icons.date_range_rounded, 'End Date', _formatDate(_activeInternship!.endDate)),
                  ]
                : [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Belum ada data magang terdaftar.',
                        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B), fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
          ),
          const SizedBox(height: 16),

          // --- Actions Menu Card ---
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 5,
                )
              ],
            ),
            child: Column(
              children: [
                _buildMenuRow(Icons.edit_rounded, 'Edit Profile', _showEditProfileSheet),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _buildMenuRow(Icons.business_center_rounded, 'Internship Information', _showAddInternshipSheet),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _buildMenuRow(Icons.notifications_rounded, 'Notification Settings', () {
                  _showTopNotification('Notification Settings (Fitur masih dalam pengembangan)', isError: false);
                }),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _buildMenuRow(Icons.lock_rounded, 'Change Password', _showChangePasswordSheet),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _buildMenuRow(Icons.help_outline_rounded, 'Help & Support', _showHelpSupportSheet),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _buildMenuRow(Icons.logout_rounded, 'Logout', _handleLogout, isDanger: true),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- App Version ---
          Center(
            child: Text(
              'MagangDay v1.0.0',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInfoCardGroup({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 5,
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E1E2F),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF7ED),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFFFF6D00), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1E1E2F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuRow(IconData icon, String title, VoidCallback onTap, {bool isDanger = false}) {
    final color = isDanger ? Colors.redAccent : const Color(0xFF1E1E2F);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDanger ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isDanger ? Colors.redAccent : const Color(0xFF64748B), size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            if (!isDanger)
              const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  // Helper builder for Nav Item
  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isActive = _currentIndex == index;
    final Color itemColor = isActive ? const Color(0xFFEA580C) : const Color(0xFF64748B);

    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: itemColor, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: itemColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper builder for Statistic Card
  Widget _buildStatCard({required IconData icon, required String value, required String title}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12.8),
      child: Column(
        children: [
          // Orange circular background icon
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFFFEDD5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFFFF6D00), size: 18),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0A0A0A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // Helper builder for Activity Card
  Widget _buildActivityCard(ActivityLogModel log) {
    // Format duration in minutes to hours
    final double hours = log.durationMinutes / 60.0;
    final String durationText = hours % 1 == 0 ? '${hours.toInt()}h' : '${hours.toStringAsFixed(1)}h';

    return InkWell(
      onTap: () async {
        await Navigator.pushNamed(
          context,
          '/activity-detail',
          arguments: log,
        );
        _loadAllData();
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16.8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date & Completed Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(log.activityDate),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.8, vertical: 2.8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD0FAE5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF007A55),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        log.status,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF007A55),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Title
            Text(
              log.title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0A0A0A),
              ),
            ),
            const SizedBox(height: 6),
            // Description
            if (log.description != null && log.description!.isNotEmpty)
              Text(
                log.description!,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            const SizedBox(height: 12),
            // Tag indicators footer
            Wrap(
              spacing: 12.0,
              runSpacing: 6.0,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Project Tag
                if (log.projectName != null && log.projectName!.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.business_center_rounded, color: Color(0xFF64748B), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        log.projectName!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                // Hour Tag
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time_rounded, color: Color(0xFF64748B), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      durationText,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                // Category tag
                if (log.category != null && log.category!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      log.category!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF9A3412),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- UI Elements Helpers ---
  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, top: 4.0),
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

  InputDecoration _inputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        color: const Color(0xFF9E9E9E),
      ),
      filled: true,
      fillColor: const Color(0xFFF9F9FB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFE5E5E9),
          width: 1.0,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFE5E5E9),
          width: 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFFF6D00),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.0,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
        ),
      ),
    );
  }
}

// Custom Painter for Donut Chart
class DonutChartPainter extends CustomPainter {
  final Map<String, int> data;
  final List<Color> colors;
  
  DonutChartPainter({required this.data, required this.colors});
  
  @override
  void paint(Canvas canvas, Size size) {
    final double total = data.values.fold(0.0, (sum, item) => sum + item);
    if (total == 0) {
      final paint = Paint()
        ..color = const Color(0xFFE2E8F0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14;
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 2 - 10, paint);
      return;
    }
    
    double startAngle = -3.14159265 / 2; // Start from top
    final rect = Rect.fromLTWH(10, 10, size.width - 20, size.height - 20);
    
    int i = 0;
    data.forEach((key, val) {
      final sweepAngle = (val / total) * 2 * 3.14159265;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.butt;
        
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
      i++;
    });
  }
  
  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) => true;
}

// Custom Painter for Bar Chart (Activities)
class BarChartPainter extends CustomPainter {
  final List<int> values;
  final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  
  BarChartPainter({required this.values});
  
  @override
  void paint(Canvas canvas, Size size) {
    final int maxValue = values.fold<int>(4, (max, val) => val > max ? val : max);
    
    final double chartWidth = size.width - 40;
    final double chartHeight = size.height - 30;
    
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0;
      
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    for (int i = 0; i <= 4; i++) {
      final double y = chartHeight - (i / 4.0) * chartHeight + 10;
      final double fraction = i / 4.0;
      final int labelVal = (fraction * maxValue).round();
      
      canvas.drawLine(Offset(30, y), Offset(size.width - 10, y), gridPaint);
      
      textPainter.text = TextSpan(
        text: labelVal.toString(),
        style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8)),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(5, y - 6));
    }
    
    final double barWidth = 18.0;
    final double colWidth = chartWidth / 7;
    
    final barPaint = Paint()
      ..color = const Color(0xFFFF6D00)
      ..style = PaintingStyle.fill;
      
    for (int i = 0; i < 7; i++) {
      final double x = 30 + i * colWidth + (colWidth - barWidth) / 2;
      final double valHeight = maxValue == 0 ? 0.0 : (values[i] / maxValue) * chartHeight;
      final double y = chartHeight + 10 - valHeight;
      
      if (valHeight > 0) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, valHeight),
          const Radius.circular(4),
        );
        canvas.drawRRect(rect, barPaint);
      }
      
      textPainter.text = TextSpan(
        text: days[i],
        style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B)),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(30 + i * colWidth + (colWidth - textPainter.width) / 2, chartHeight + 14));
    }
  }
  
  @override
  bool shouldRepaint(covariant BarChartPainter oldDelegate) => true;
}

// Custom Painter for Line Chart (Working Hours)
class LineChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  
  LineChartPainter({required this.values});
  
  @override
  void paint(Canvas canvas, Size size) {
    final double maxValue = values.fold<double>(8.0, (max, val) => val > max ? val : max);
    
    final double chartWidth = size.width - 40;
    final double chartHeight = size.height - 30;
    
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0;
      
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    for (int i = 0; i <= 4; i++) {
      final double y = chartHeight - (i / 4.0) * chartHeight + 10;
      final double labelVal = (i / 4.0) * maxValue;
      
      canvas.drawLine(Offset(30, y), Offset(size.width - 10, y), gridPaint);
      
      textPainter.text = TextSpan(
        text: labelVal.toStringAsFixed(labelVal % 1 == 0 ? 0 : 1),
        style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8)),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(5, y - 6));
    }
    
    final double colWidth = chartWidth / 7;
    final points = <Offset>[];
    
    for (int i = 0; i < 7; i++) {
      final double x = 30 + i * colWidth + colWidth / 2;
      final double valHeight = maxValue == 0 ? 0.0 : (values[i] / maxValue) * chartHeight;
      final double y = chartHeight + 10 - valHeight;
      points.add(Offset(x, y));
    }
    
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < 7; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    
    final linePaint = Paint()
      ..color = const Color(0xFFFF6D00)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
      
    canvas.drawPath(path, linePaint);
    
    final dotPaint = Paint()
      ..color = const Color(0xFFFF6D00)
      ..style = PaintingStyle.fill;
    final dotStroke = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
      
    for (var pt in points) {
      canvas.drawCircle(pt, 5.0, dotPaint);
      canvas.drawCircle(pt, 5.0, dotStroke);
    }
    
    for (int i = 0; i < 7; i++) {
      textPainter.text = TextSpan(
        text: days[i],
        style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B)),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(30 + i * colWidth + (colWidth - textPainter.width) / 2, chartHeight + 14));
    }
  }
  
  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) => true;
}

// Simple custom painter to draw the dashed border for today's activity card
class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedRectPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(18),
    );

    final Path path = Path()..addRRect(rrect);
    final Path dashPath = Path();

    double distance = 0.0;
    bool draw = true;

    for (final PathMetric measurePath in path.computeMetrics()) {
      while (distance < measurePath.length) {
        final double len = draw ? gap * 1.5 : gap;
        if (draw) {
          dashPath.addPath(
            measurePath.extractPath(distance, distance + len),
            Offset.zero,
          );
        }
        distance += len;
        draw = !draw;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap;
  }
}
