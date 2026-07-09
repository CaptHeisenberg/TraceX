import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/theme.dart';
import '../providers/alerts_provider.dart';
import '../../../models/defect.dart';

class AlertDetailsScreen extends ConsumerStatefulWidget {
  final String defectId;

  const AlertDetailsScreen({super.key, required this.defectId});

  @override
  ConsumerState<AlertDetailsScreen> createState() => _AlertDetailsScreenState();
}

class _AlertDetailsScreenState extends ConsumerState<AlertDetailsScreen> {
  Map<String, dynamic>? _aiData;
  bool _loadingAi = false;
  String? _aiError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAiAnalysis();
    });
  }

  void _loadAiAnalysis() async {
    final alerts = ref.read(alertsProvider).value;
    if (alerts == null) return;
    final defect = alerts.firstWhere((d) => d.id == widget.defectId);

    setState(() {
      _loadingAi = true;
      _aiError = null;
    });

    final res = await ref.read(alertsProvider.notifier).fetchAiRecommendation(
      defect.boardId,
      defect.component,
      defect.defect,
      defect.confidence,
    );

    if (mounted) {
      setState(() {
        _loadingAi = false;
        if (res != null) {
          _aiData = res;
        } else {
          _aiError = 'Ollama AI engine unreachable.';
        }
      });
    }
  }

  void _assignReworkSheet(Defect defect) {
    final nameController = TextEditingController();
    final remarksController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ASSIGN REWORK ORDER',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'OPERATOR NAME / ASSIGNEE',
                  hintText: 'e.g. Operator Dave',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: remarksController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'REWORK INSTRUCTIONS',
                  hintText: 'e.g. Desolder bridge on pin 4, check thermal pads',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final remarks = remarksController.text.trim();
                  if (name.isEmpty) return;

                  final ok = await ref.read(alertsProvider.notifier).resolveAlert(
                    defect.boardId,
                    '$remarks (Assigned to $name)',
                    'In Progress',
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    if (ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Rework order assigned to $name successfully.'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                      context.pop();
                    }
                  }
                },
                child: const Text('DISPATCH ORDER'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _resolveDirectly(Defect defect) async {
    final ok = await ref.read(alertsProvider.notifier).resolveAlert(
      defect.boardId,
      'Directly resolved and cleared via inspection console.',
      'Resolved',
    );
    if (mounted && ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alert resolved. Board yield marked as Passed.'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final alertsState = ref.watch(alertsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'INSPECTION REPORT',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: alertsState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => const Center(child: Text('Error loading alert details')),
        data: (alerts) {
          final defectIndex = alerts.indexWhere((d) => d.id == widget.defectId);
          if (defectIndex == -1) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, color: AppColors.success, size: 48),
                  const SizedBox(height: 16),
                  const Text('Alert has been resolved.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('RETURN TO FEED'),
                  ),
                ],
              ),
            );
          }

          final defect = alerts[defectIndex];

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // PCB graphic visualizer
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Stack(
                    children: [
                      // Schematic PCB Canvas Drawing
                      Positioned.fill(
                        child: CustomPaint(
                          painter: PCBSchematicPainter(),
                        ),
                      ),
                      // Overlay Bounding Box defect highlighter
                      Positioned(
                        left: (defect.boundingBox.x / 100.0) * 320,
                        top: (defect.boundingBox.y / 100.0) * 220,
                        width: (defect.boundingBox.width / 100.0) * 320 + 20,
                        height: (defect.boundingBox.height / 100.0) * 220 + 20,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.critical, width: 2),
                            color: AppColors.critical.withOpacity(0.12),
                          ),
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: Container(
                              color: AppColors.critical,
                              padding: const EdgeInsets.all(2),
                              child: Text(
                                defect.component,
                                style: const TextStyle(fontSize: 8, color: Colors.black, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            'AOI DETECTED REGION OVERLAY',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Defect metrics metadata
                Text(
                  'INSPECTION SUMMARY',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8,
                  ),
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
                      _buildMetricRow('Board ID', defect.boardId),
                      const Divider(color: AppColors.border, height: 20),
                      _buildMetricRow('Component', defect.component),
                      const Divider(color: AppColors.border, height: 20),
                      _buildMetricRow('Defect Class', defect.defect),
                      const Divider(color: AppColors.border, height: 20),
                      _buildMetricRow('AI Confidence', '${(defect.confidence * 100).toStringAsFixed(1)}%'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // AI Expert Explanation Card
                Text(
                  'QWEN3:8B MANUFACTURING INSIGHTS',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12),
                _buildAiExplanationWidget(),
                const SizedBox(height: 32),

                 // Operational Action Buttons
                ElevatedButton.icon(
                  onPressed: () {
                    final contextStr = '${defect.defect} on ${defect.component} (Board: ${defect.boardId})';
                    final initMsg = 'Analyze this defect for me: Solder joint failure class [${defect.defect}] found on component reference [${defect.component}]. What are the immediate corrective actions?';
                    context.push('/chat?context=${Uri.encodeComponent(contextStr)}&initialMessage=${Uri.encodeComponent(initMsg)}');
                  },
                  icon: const Icon(Icons.psychology_outlined, color: Colors.black, size: 20),
                  label: const Text('DISCUSS WITH AI CO-PILOT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _resolveDirectly(defect),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.success),
                          foregroundColor: AppColors.success,
                        ),
                        child: const Text('RESOLVE'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _assignReworkSheet(defect),
                        child: const Text('ASSIGN REWORK'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text),
        ),
      ],
    );
  }

  Widget _buildAiExplanationWidget() {
    if (_loadingAi) {
      return Container(
        height: 140,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Running local Qwen3:8B LLM agent...',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_aiError != null || _aiData == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Text(
            _aiError ?? 'No engineering recommendations available.',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.critical),
          ),
        ),
      );
    }

    final analysis = _aiData!['analysis'] as List<dynamic>? ?? [];
    if (analysis.isEmpty) {
      return const Text('Analysis format mismatch');
    }

    final item = analysis.first as Map<String, dynamic>;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInsightSection('POSSIBLE MANUFACTURING CAUSE', item['possible_cause'] ?? 'Unlisted mechanical trace anomaly.'),
          const SizedBox(height: 16),
          _buildInsightSection('ELECTRICAL IMPACT', item['electrical_impact'] ?? 'Signal instability or open circuit paths.'),
          const SizedBox(height: 16),
          _buildInsightSection('OPERATOR MITIGATION ACTION', item['operator_action'] ?? 'Perform high-magnification rework alignment.'),
          const SizedBox(height: 16),
          _buildInsightSection('PRODUCTION LINE PREVENTATIVE ROUTINE', item['preventive_action'] ?? 'Check SMT pick-and-place calibration matrices.'),
        ],
      ),
    );
  }

  Widget _buildInsightSection(String title, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          body,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.text,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

// Custom Painter to draw stylized industrial PCB circuits on background
class PCBSchematicPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF0F1612);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final linePaint = Paint()
      ..color = const Color(0xFF1B2E24)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final busPaint = Paint()
      ..color = const Color(0xFF1E3A2B)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // Draw some layout circuits grid lines
    for (double i = 20; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), linePaint);
    }
    for (double i = 20; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), linePaint);
    }

    // Draw copper buses
    final path1 = Path()
      ..moveTo(30, 30)
      ..lineTo(100, 30)
      ..lineTo(140, 70)
      ..lineTo(140, 150)
      ..lineTo(220, 150);
    canvas.drawPath(path1, busPaint);

    final path2 = Path()
      ..moveTo(size.width - 30, size.height - 30)
      ..lineTo(size.width - 100, size.height - 30)
      ..lineTo(size.width - 140, size.height - 70)
      ..lineTo(size.width - 140, 100);
    canvas.drawPath(path2, busPaint);
    
    // Draw some component pads
    final padPaint = Paint()..color = const Color(0xFF386641);
    canvas.drawRect(const Rect.fromLTWH(80, 20, 12, 20), padPaint);
    canvas.drawRect(const Rect.fromLTWH(110, 20, 12, 20), padPaint);
    canvas.drawRect(const Rect.fromLTWH(140, 20, 12, 20), padPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
