import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import '../models/profile_model.dart';
import '../models/internship_model.dart';
import '../models/activity_log_model.dart';

class ReportService {
  static Future<void> shareFile({
    required List<int> bytes,
    required String filename,
    required String mimeType,
  }) async {
    if (kIsWeb) {
      final xFile = XFile.fromData(
        Uint8List.fromList(bytes),
        name: filename,
        mimeType: mimeType,
      );
      // ignore: deprecated_member_use
      await Share.shareXFiles([xFile]);
    } else {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(bytes);
      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(file.path)], text: filename);
    }
  }

  static Future<void> generatePdfReport({
    required ProfileModel profile,
    required InternshipModel? internship,
    required List<ActivityLogModel> logs,
  }) async {
    final pdf = pw.Document();

    // Helper for formatting date
    String formatDate(DateTime date) {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }

    // Calculations
    final int totalDays = logs.map((log) => log.activityDate.toIso8601String().split('T')[0]).toSet().length;
    final int totalMinutes = logs.fold<int>(0, (sum, log) => sum + log.durationMinutes);
    final double totalHours = totalMinutes / 60.0;
    final String hoursStr = totalHours % 1 == 0 ? '${totalHours.toInt()} jam' : '${totalHours.toStringAsFixed(1)} jam';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header Title
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'LAPORAN KEGIATAN MAGANG',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#FF6D00'),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Dibuat secara otomatis melalui MagangDay',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  formatDate(DateTime.now()),
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Divider(thickness: 1, color: PdfColor.fromHex('#E2E8F0')),
            pw.SizedBox(height: 12),

            // Profile & Internship Block
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('INFORMASI MAHASISWA', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1E1E2F'))),
                      pw.SizedBox(height: 6),
                      pw.Text('Nama: ${profile.fullName}', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('NIM: ${profile.nim}', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('Universitas: ${profile.university}', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('Program Studi: ${profile.studyProgram}', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('Semester: ${profile.semester}', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ),
                pw.SizedBox(width: 24),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('INFORMASI MAGANG', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1E1E2F'))),
                      pw.SizedBox(height: 6),
                      if (internship != null) ...[
                        pw.Text('Perusahaan: ${internship.companyName}', style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('Posisi: ${internship.position}', style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('Mentor: ${internship.mentorName ?? "-"}', style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('Periode: ${formatDate(internship.startDate)} - ${formatDate(internship.endDate)}', style: const pw.TextStyle(fontSize: 9)),
                      ] else ...[
                        pw.Text('Belum ada informasi magang terdaftar.', style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // Statistics Block
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#FFF7ED'),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: PdfColor.fromHex('#FF6D00'), width: 0.5),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Text('Total Hari Kerja', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      pw.SizedBox(height: 2),
                      pw.Text('$totalDays Hari', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#9A3412'))),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('Total Jam Kerja', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      pw.SizedBox(height: 2),
                      pw.Text(hoursStr, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#9A3412'))),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('Total Aktivitas', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      pw.SizedBox(height: 2),
                      pw.Text('${logs.length} Log', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#9A3412'))),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Table Header Title
            pw.Text(
              'DAFTAR LOG AKTIVITAS',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1E1E2F')),
            ),
            pw.SizedBox(height: 8),

            // Logs Table
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColor.fromHex('#CBD5E1'), width: 0.5),
              headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#FF6D00')),
              cellStyle: const pw.TextStyle(fontSize: 7.5),
              headers: ['No', 'Tanggal', 'Aktivitas & Kategori', 'Durasi', 'Deskripsi Pekerjaan', 'Tantangan & Pelajaran'],
              data: List<List<dynamic>>.generate(logs.length, (index) {
                final log = logs[index];
                final logHours = log.durationMinutes / 60.0;
                final logHoursStr = logHours % 1 == 0 ? '${logHours.toInt()} jam' : '${logHours.toStringAsFixed(1)} jam';
                final proj = log.projectName != null && log.projectName!.isNotEmpty ? '\nProyek: ${log.projectName}' : '';
                
                final challenges = log.challenges != null && log.challenges!.isNotEmpty ? 'Tantangan: ${log.challenges}\n' : '';
                final learning = log.learning != null && log.learning!.isNotEmpty ? 'Pelajaran: ${log.learning}' : '';
                final outString = '$challenges$learning';

                return [
                  (index + 1).toString(),
                  formatDate(log.activityDate),
                  '${log.title}$proj\nKategori: ${log.category}',
                  logHoursStr,
                  log.description ?? '-',
                  outString.isEmpty ? '-' : outString,
                ];
              }),
            ),
          ];
        },
      ),
    );

    final List<int> bytes = await pdf.save();
    await shareFile(
      bytes: bytes,
      filename: 'Laporan_Magang_${profile.fullName.replaceAll(' ', '_')}.pdf',
      mimeType: 'application/pdf',
    );
  }

  static Future<void> generateExcelReport({
    required ProfileModel profile,
    required InternshipModel? internship,
    required List<ActivityLogModel> logs,
  }) async {
    final excel = Excel.createExcel();
    
    // Sheet 1: Ringkasan
    final Sheet summarySheet = excel['Sheet1'];
    excel.rename('Sheet1', 'Ringkasan');

    // Title Row
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = TextCellValue('LAPORAN RINGKASAN MAGANG');
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2)).value = TextCellValue('INFORMASI MAHASISWA');

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3)).value = TextCellValue('Nama Lengkap');
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3)).value = TextCellValue(profile.fullName);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4)).value = TextCellValue('NIM');
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4)).value = TextCellValue(profile.nim);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5)).value = TextCellValue('Universitas');
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 5)).value = TextCellValue(profile.university);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 6)).value = TextCellValue('Program Studi');
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 6)).value = TextCellValue(profile.studyProgram);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 7)).value = TextCellValue('Semester');
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 7)).value = IntCellValue(profile.semester);

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 9)).value = TextCellValue('INFORMASI MAGANG');

    if (internship != null) {
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 10)).value = TextCellValue('Perusahaan');
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 10)).value = TextCellValue(internship.companyName);
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 11)).value = TextCellValue('Posisi');
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 11)).value = TextCellValue(internship.position);
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 12)).value = TextCellValue('Mentor');
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 12)).value = TextCellValue(internship.mentorName ?? '-');
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 13)).value = TextCellValue('Tanggal Mulai');
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 13)).value = TextCellValue(internship.startDate.toIso8601String().split('T')[0]);
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 14)).value = TextCellValue('Tanggal Selesai');
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 14)).value = TextCellValue(internship.endDate.toIso8601String().split('T')[0]);
    } else {
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 10)).value = TextCellValue('Belum ada magang terdaftar');
    }

    // Sheet 2: Log Aktivitas
    final Sheet logsSheet = excel['Log Aktivitas'];
    
    final List<String> headers = ['No', 'Tanggal', 'Judul Aktivitas', 'Kategori', 'Proyek', 'Durasi (Menit)', 'Deskripsi Pekerjaan', 'Tantangan', 'Pembelajaran'];
    for (int i = 0; i < headers.length; i++) {
      logsSheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value = TextCellValue(headers[i]);
    }

    for (int r = 0; r < logs.length; r++) {
      final log = logs[r];
      logsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r + 1)).value = IntCellValue(r + 1);
      logsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r + 1)).value = TextCellValue(log.activityDate.toIso8601String().split('T')[0]);
      logsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: r + 1)).value = TextCellValue(log.title);
      logsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: r + 1)).value = TextCellValue(log.category ?? 'Other');
      logsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: r + 1)).value = TextCellValue(log.projectName ?? '');
      logsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: r + 1)).value = IntCellValue(log.durationMinutes);
      logsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: r + 1)).value = TextCellValue(log.description ?? '');
      logsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: r + 1)).value = TextCellValue(log.challenges ?? '');
      logsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: r + 1)).value = TextCellValue(log.learning ?? '');
    }

    final List<int>? bytes = excel.encode();
    if (bytes != null) {
      await shareFile(
        bytes: bytes,
        filename: 'Laporan_Magang_${profile.fullName.replaceAll(' ', '_')}.xlsx',
        mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    }
  }
}
