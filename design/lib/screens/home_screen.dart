import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/profile_model.dart';
import '../models/internship_model.dart';
import '../models/activity_log_model.dart';
import '../services/supabase_service.dart';

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
  
  bool _isLoadingAll = true;
  bool _isSubmitting = false;

  // Search and Filter States for HistoryScreen
  String _searchQuery = '';
  String _filterCategory = 'All';
  String _filterStatus = 'All';

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
    super.dispose();
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
        final profile = await SupabaseService.getProfile(user.id);
        
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal memuat data: ${e.toString()}'),
              backgroundColor: Colors.redAccent,
            ),
          );
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
    _companyController.clear();
    _positionController.clear();
    _mentorNameController.clear();
    _mentorEmailController.clear();
    _startDate = null;
    _endDate = null;

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
                bottom: MediaQuery.of(context).viewInsets.bottom,
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
                      Text(
                        'Mulai Magang Baru',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E1E2F),
                        ),
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
                                      initialDate: DateTime.now(),
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
                                      initialDate: _startDate ?? DateTime.now(),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tanggal mulai dan selesai wajib dipilih'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      if (_startDate!.isAfter(_endDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tanggal mulai tidak boleh setelah tanggal selesai'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      setSheetState(() => _isSubmitting = true);
      final user = SupabaseService.currentUser;
      if (user != null) {
        try {
          final internship = InternshipModel(
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gagal menyimpan: ${e.toString()}'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        } finally {
          if (mounted) {
            setSheetState(() => _isSubmitting = false);
          }
        }
      }
    }
  }

  void _showAddLogSheet() {
    if (_activeInternship == null || _activeInternship!.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tambahkan data magang terlebih dahulu'),
          backgroundColor: Colors.redAccent,
        ),
      );
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
                bottom: MediaQuery.of(context).viewInsets.bottom,
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
                      Text(
                        'Catat Log Aktivitas',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E1E2F),
                        ),
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
                      _buildFieldLabel('TANTANGAN & MASALAH'),
                      TextFormField(
                        controller: _challengesController,
                        maxLines: 2,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13),
                        decoration: _inputDecoration(hintText: 'Ada sedikit error CORS saat integrasi API Auth.'),
                      ),
                      const SizedBox(height: 14),

                      // Learning Outcomes
                      _buildFieldLabel('PELAJARAN YANG DIPEROLEH (LEARNINGS)'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jam mulai dan selesai wajib dipilih'),
            backgroundColor: Colors.redAccent,
          ),
        );
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gagal menyimpan log: ${e.toString()}'),
                backgroundColor: Colors.redAccent,
              ),
            );
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
          // Scrollable Page Content
          Expanded(
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

          // Bottom Navigation Bar
          Container(
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
          ? FloatingActionButton(
              onPressed: _showAddLogSheet,
              backgroundColor: const Color(0xFFFF6D00),
              foregroundColor: Colors.white,
              child: const Icon(Icons.add_rounded),
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
                ),
                alignment: Alignment.center,
                child: Text(
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

  // --- Reports Tab View (Placeholder) ---
  Widget _buildReportsView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bar_chart_rounded, size: 64, color: Color(0xFFFF6D00)),
            const SizedBox(height: 16),
            Text(
              'Laporan Aktivitas',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E1E2F)),
            ),
            const SizedBox(height: 6),
            Text(
              'Fitur grafik ringkasan dan analisis laporan aktivitas magang sedang disiapkan untuk rilis berikutnya.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B), height: 1.4),
            ),
          ],
        ),
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
    final String email = _profile?.email ?? SupabaseService.currentUser?.email ?? '';
    final String nim = _profile?.nim ?? '-';
    final String university = _profile?.university ?? '-';
    final String studyProgram = _profile?.studyProgram ?? '-';
    final String semester = _profile?.semester.toString() ?? '1';
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : 'Y';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          // Large Avatar
          Center(
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
                color: const Color(0xFFFFEDD5),
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 36,
                  color: const Color(0xFFFF6D00),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Name and Email
          Center(
            child: Text(
              name,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0A0A0A),
              ),
            ),
          ),
          Center(
            child: Text(
              email,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          // Profile Details Grid
          Text(
            'Informasi Akademik',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFF6D00),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          _buildProfileDetailRow(Icons.badge_outlined, 'NIM', nim),
          _buildProfileDetailRow(Icons.school_outlined, 'Universitas', university),
          _buildProfileDetailRow(Icons.book_outlined, 'Program Studi', studyProgram),
          _buildProfileDetailRow(Icons.calendar_today_outlined, 'Semester', 'Semester $semester'),
          
          const SizedBox(height: 40),
          // Logout Button
          ElevatedButton.icon(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
            label: Text(
              'Keluar Akun',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProfileDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF64748B), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
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
