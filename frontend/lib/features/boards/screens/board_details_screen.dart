import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/theme/theme.dart';
import '../providers/boards_provider.dart';
import '../../alerts/screens/alert_details_screen.dart'; // Import PCB painter

class BoardDetailsScreen extends ConsumerWidget {
  final String boardId;

  const BoardDetailsScreen({super.key, required this.boardId});

  // Action to export complete board history into a professional PDF
  Future<void> _exportPdfReport(BuildContext context, dynamic board) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Title header
                pw.Text('TraceX AOI Inspection & Quality Audit Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Text('SMT Manufacturing Intelligence Analytics Platform', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                pw.Divider(thickness: 1.5, color: PdfColors.black),
                pw.SizedBox(height: 20),

                // Board details
                pw.Text('METRIC PARAMETERS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Bullet(text: 'Board Serial ID: ${board.boardId}'),
                pw.Bullet(text: 'Inspected Batch: ${board.batch}'),
                pw.Bullet(text: 'AOI Inspection Run Time: ${board.inspectionTime.toString()}'),
                pw.Bullet(text: 'Yield Status classification: ${board.status.toUpperCase()}'),
                pw.SizedBox(height: 24),

                // Defect statistics
                pw.Text('DETECTED PCB COMPONENT ANOMALIES', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                if (board.defects.isEmpty)
                  pw.Text('Zero component anomalies flagged by optical scanner.')
                else
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    children: [
                      // Table header
                      pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Component', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Defect', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Severity', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Confidence', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        ],
                      ),
                      // Table rows
                      ...board.defects.map<pw.TableRow>((d) => pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(d.component)),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(d.defect)),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(d.severity)),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${(d.confidence * 100).toStringAsFixed(1)}%')),
                        ],
                      )),
                    ],
                  ),
                pw.SizedBox(height: 24),

                // Rework audit
                pw.Text('REWORK OPERATIONS & ASSIGNMENTS LOG', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                if (board.reworks.isEmpty)
                  pw.Text('No manual repairs assigned or scheduled.')
                else
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: board.reworks.map<pw.Widget>((r) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 8),
                      child: pw.Text('- Status: [${r.status}] | Assignee: ${r.assignedTo} | Remarks: ${r.remarks ?? "None"}'),
                    )).toList(),
                  ),
                pw.Spacer(),
                pw.Divider(color: PdfColors.grey300),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text('Report Generated by TraceX automated daemon on ${DateTime.now().toString()}', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                ),
              ],
            ),
          );
        },
      ),
    );

    try {
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/tracex_report_${board.boardId}.pdf');
      await file.writeAsBytes(await pdf.save());
      
      // Open PDF file using platform handler
      await OpenFile.open(file.path);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to compile PDF: $e'),
            backgroundColor: AppColors.critical,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardState = ref.watch(boardDetailProvider(boardId));
    final dateStr = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'INSPECTION REPORT DETAILS',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: boardState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => Center(child: Text('Operational read failure: $err')),
        data: (board) {
          final isPassed = board.status == 'Passed';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Board summary header card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                board.boardId,
                                style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Batch: ${board.batch}',
                                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isPassed ? AppColors.success.withOpacity(0.08) : AppColors.critical.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isPassed ? AppColors.success.withOpacity(0.3) : AppColors.critical.withOpacity(0.3)),
                            ),
                            child: Text(
                              board.status.toUpperCase(),
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: isPassed ? AppColors.success : AppColors.critical,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Inspected at:',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          Text(
                            dateStr.format(board.inspectionTime),
                            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // PCB overlays graphics
                Text(
                  'OPTICAL DETECTED DEFECT OVERLAYS',
                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: PCBSchematicPainter(),
                        ),
                      ),
                      // Draw overlay rectangles for all board defects
                      ...board.defects.map((def) {
                        return Positioned(
                          left: (def.boundingBox.x / 100.0) * 320,
                          top: (def.boundingBox.y / 100.0) * 200,
                          width: (def.boundingBox.width / 100.0) * 320 + 20,
                          height: (def.boundingBox.height / 100.0) * 200 + 20,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.critical, width: 2),
                              color: AppColors.critical.withOpacity(0.12),
                            ),
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Container(
                                color: AppColors.critical,
                                padding: const EdgeInsets.all(2),
                                child: Text(
                                  '${def.component}: ${def.defect}',
                                  style: const TextStyle(fontSize: 7, color: Colors.black, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      if (board.defects.isEmpty)
                        const Center(
                          child: Text(
                            'No defects detected. Clean inspection run.',
                            style: TextStyle(color: AppColors.success, fontSize: 13),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Historical Timeline
                Text(
                  'INSPECTION & REWORK AUDIT TIMELINE',
                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _buildTimelineRow('Inspection complete. Classified as ${board.status}.', dateStr.format(board.inspectionTime), true),
                      if (board.defects.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ...board.defects.map((d) => _buildTimelineRow('Defect flagged: ${d.defect} on component ${d.component}.', dateStr.format(d.createdAt), false)),
                      ],
                      if (board.reworks.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ...board.reworks.map((r) => _buildTimelineRow('Rework task status updated: ${r.status} (${r.assignedTo}). Remarks: ${r.remarks ?? "None"}', dateStr.format(r.createdAt), false)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // PDF Export button
                ElevatedButton.icon(
                  onPressed: () => _exportPdfReport(context, board),
                  icon: const Icon(Icons.picture_as_pdf, size: 20, color: Colors.black),
                  label: const Text('DOWNLOAD PDF AUDIT REPORT'),
                ),
                const SizedBox(height: 48),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelineRow(String text, String date, bool isHeader) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isHeader ? Icons.radio_button_checked : Icons.radio_button_off,
          color: isHeader ? AppColors.primary : AppColors.textSecondary,
          size: 14,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.text,
                  fontWeight: isHeader ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                date,
                style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
