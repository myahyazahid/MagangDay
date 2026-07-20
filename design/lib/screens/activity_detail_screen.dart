import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/activity_log_model.dart';
import '../services/supabase_service.dart';

class ActivityDetailScreen extends StatefulWidget {
  final ActivityLogModel initialLog;

  const ActivityDetailScreen({super.key, required this.initialLog});

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  late ActivityLogModel _log;
  bool _isDeleting = false;
  bool _isSubmitting = false;

  // Edit Controllers
  final _editFormKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _projectController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _challengesController = TextEditingController();
  final _learningController = TextEditingController();
  final _techController = TextEditingController();
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
    _log = widget.initialLog;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _projectController.dispose();
    _descriptionController.dispose();
    _challengesController.dispose();
    _learningController.dispose();
    _techController.dispose();
    super.dispose();
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

  String _formatDuration(int minutes) {
    final double hours = minutes / 60.0;
    if (hours % 1 == 0) {
      return '${hours.toInt()}h';
    }
    return '${hours.toStringAsFixed(1)}h';
  }

  String _formatTimeStr(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '--:--';
    // Format HH:MM:SS to HH:MM
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }
    return timeStr;
  }

  void _showEditLogSheet() {
    _titleController.text = _log.title;
    _projectController.text = _log.projectName ?? '';
    _descriptionController.text = _log.description ?? '';
    _challengesController.text = _log.challenges ?? '';
    _learningController.text = _log.learning ?? '';
    _techController.text = _log.technologies.join(', ');
    _selectedCategory = _log.category ?? 'Frontend Development';

    // Parse Time
    if (_log.startTime != null) {
      final parts = _log.startTime!.split(':');
      if (parts.length >= 2) {
        _startTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    } else {
      _startTime = null;
    }

    if (_log.endTime != null) {
      final parts = _log.endTime!.split(':');
      if (parts.length >= 2) {
        _endTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    } else {
      _endTime = null;
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
                  key: _editFormKey,
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
                            'Edit Log Aktivitas',
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
                        'Perbarui catatan log aktivitas magang Anda.',
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
                                      initialTime: _startTime ?? const TimeOfDay(hour: 9, minute: 0),
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
                                      initialTime: _endTime ?? const TimeOfDay(hour: 17, minute: 0),
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
                        onPressed: _isSubmitting ? null : () => _submitEditLog(setSheetState),
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
                                'Perbarui Log',
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

  Future<void> _submitEditLog(StateSetter setSheetState) async {
    if (_editFormKey.currentState!.validate()) {
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
      
      try {
        final int startMinutes = _startTime!.hour * 60 + _startTime!.minute;
        final int endMinutes = _endTime!.hour * 60 + _endTime!.minute;
        int duration = endMinutes - startMinutes;
        if (duration < 0) {
          duration += 24 * 60;
        }

        final List<String> techList = _techController.text.trim().isNotEmpty
            ? _techController.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList()
            : [];

        final String startStr = '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}:00';
        final String endStr = '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}:00';

        final updatedLog = _log.copyWith(
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

        await SupabaseService.saveActivityLog(updatedLog);
        
        setState(() {
          _log = updatedLog;
        });

        if (mounted) {
          Navigator.pop(context); // Close sheet
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal memperbarui log: ${e.toString()}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } finally {
        setSheetState(() => _isSubmitting = false);
      }
    }
  }

  void _handleDeleteLog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Hapus Log', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: Text('Apakah Anda yakin ingin menghapus log aktivitas ini?', style: GoogleFonts.inter()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Batal', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              child: Text('Hapus', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirm == true && _log.id != null) {
      setState(() {
        _isDeleting = true;
      });

      try {
        await SupabaseService.deleteActivityLog(_log.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Log berhasil dihapus'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true); // Pop back returning true to refresh list
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isDeleting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus: ${e.toString()}'), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktopWeb = screenWidth > 600;

    Widget detailContent = Container(
      width: isDesktopWeb ? 360 : double.infinity,
      height: isDesktopWeb ? 800 : double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: isDesktopWeb ? BorderRadius.circular(36) : BorderRadius.zero,
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(8, 20, 8, 12),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF1E1E2F)),
                ),
                const SizedBox(width: 4),
                Text(
                  'Activity Detail',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E1E2F),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and status badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _log.title,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E1E2F),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD0FAE5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, color: Color(0xFF007A55), size: 12),
                            const SizedBox(width: 4),
                            Text(
                              _log.status,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF007A55),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Metadata Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildMetaRow(Icons.calendar_month_rounded, 'Date', _formatDateLong(_log.activityDate)),
                        const Divider(height: 20, color: Color(0xFFF1F5F9)),
                        _buildMetaRow(Icons.business_center_rounded, 'Project', _log.projectName ?? 'None'),
                        const Divider(height: 20, color: Color(0xFFF1F5F9)),
                        _buildMetaRow(Icons.assignment_rounded, 'Category', _log.category ?? 'None'),
                        const Divider(height: 20, color: Color(0xFFF1F5F9)),
                        _buildMetaRow(
                          Icons.access_time_filled_rounded, 
                          'Time', 
                          '${_formatTimeStr(_log.startTime)} – ${_formatTimeStr(_log.endTime)} · ${_formatDuration(_log.durationMinutes)}'
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Description
                  _buildSectionHeader('Description'),
                  const SizedBox(height: 6),
                  Text(
                    _log.description ?? '-',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Technologies
                  if (_log.technologies.isNotEmpty) ...[
                    _buildSectionHeader('Technologies Used'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _log.technologies.map((tech) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            tech,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Challenges
                  if (_log.challenges != null && _log.challenges!.trim().isNotEmpty) ...[
                    _buildSectionHeader('Challenges Encountered'),
                    const SizedBox(height: 6),
                    Text(
                      _log.challenges!,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Solution/Learnings
                  if (_log.learning != null && _log.learning!.trim().isNotEmpty) ...[
                    _buildSectionHeader('Solution / Learning'),
                    const SizedBox(height: 6),
                    Text(
                      _log.learning!,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),

          // Bottom Action Row
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: 12 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFE2E8F0), width: 0.8),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _showEditLogSheet,
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: Text(
                      'Edit Activity',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6D00),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: ElevatedButton.icon(
                    onPressed: _isDeleting ? null : _handleDeleteLog,
                    icon: _isDeleting 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.delete_outline_rounded, size: 16),
                    label: Text(
                      'Delete',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
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
            child: SafeArea(
              bottom: false,
              child: detailContent,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: detailContent,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1E1E2F),
      ),
    );
  }

  Widget _buildMetaRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(8),
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
                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 13, 
                  fontWeight: FontWeight.w500, 
                  color: const Color(0xFF1E1E2F)
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

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
