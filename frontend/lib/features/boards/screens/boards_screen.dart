import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/theme.dart';
import '../providers/boards_provider.dart';
import '../../../models/board.dart';

class BoardsScreen extends ConsumerStatefulWidget {
  const BoardsScreen({super.key});

  @override
  ConsumerState<BoardsScreen> createState() => _BoardsScreenState();
}

class _BoardsScreenState extends ConsumerState<BoardsScreen> {
  final _searchController = TextEditingController();
  String _selectedStatus = 'All';
  String _selectedBatch = 'All';
  bool _isScanning = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _triggerSearch() {
    ref.read(boardSearchProvider.notifier).state = _searchController.text.trim();
    ref.read(boardStatusProvider.notifier).state = _selectedStatus;
  }

  // High-fidelity simulated QR scanning overlay
  void _openMockScanner() {
    setState(() {
      _isScanning = true;
    });

    // Simulate scanning after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted && _isScanning) {
        setState(() {
          _isScanning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Simulated QR Code Read: Board #PCB-20391 detected.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.push('/boards/PCB-20391');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final boardsState = ref.watch(boardsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'INSPECTED BOARDS',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
            onPressed: _openMockScanner,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _triggerSearch(),
                  decoration: InputDecoration(
                    hintText: 'Search by Board ID or Batch number...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send, color: AppColors.primary, size: 18),
                      onPressed: _triggerSearch,
                    ),
                  ),
                ),
              ),

              // Filter Selectors Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Row(
                  children: [
                    // Status Filter
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedStatus,
                          dropdownColor: AppColors.card,
                          underline: const SizedBox(),
                          isExpanded: true,
                          style: GoogleFonts.outfit(color: AppColors.text, fontSize: 13),
                          items: ['All', 'Passed', 'Failed'].map((String val) {
                            return DropdownMenuItem<String>(value: val, child: Text('Status: $val'));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedStatus = val;
                              });
                              _triggerSearch();
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Batch Filter
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedBatch,
                          dropdownColor: AppColors.card,
                          underline: const SizedBox(),
                          isExpanded: true,
                          style: GoogleFonts.outfit(color: AppColors.text, fontSize: 13),
                          items: ['All', 'BATCH-A109', 'BATCH-B110'].map((String val) {
                            return DropdownMenuItem<String>(value: val, child: Text(val == 'All' ? 'Batch: All' : val));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedBatch = val;
                              });
                              _triggerSearch();
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Boards List
              Expanded(
                child: boardsState.when(
                  loading: () => _buildShimmerFeed(),
                  error: (err, stack) => _buildErrorState(),
                  data: (boards) => boards.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: () async {
                            _triggerSearch();
                          },
                          color: AppColors.primary,
                          backgroundColor: AppColors.card,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            itemCount: boards.length,
                            itemBuilder: (context, index) {
                              final board = boards[index];
                              return _buildBoardCard(context, board);
                            },
                          ),
                        ),
                ),
              ),
            ],
          ),
          
          // Simulated Scanner HUD Overlay
          if (_isScanning) _buildScannerOverlay(),
        ],
      ),
    );
  }

  Widget _buildBoardCard(BuildContext context, Board board) {
    final isPassed = board.status == 'Passed';
    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(board.inspectionTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => context.push('/boards/${board.boardId}'),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Circle status icon
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: isPassed ? AppColors.success.withOpacity(0.08) : AppColors.critical.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isPassed ? AppColors.success.withOpacity(0.3) : AppColors.critical.withOpacity(0.3)),
                ),
                child: Icon(
                  isPassed ? Icons.check_circle : Icons.error,
                  color: isPassed ? AppColors.success : AppColors.critical,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      board.boardId,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Batch: ${board.batch} | $dateStr',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'AOI BARCODE / QR SCANNER',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Align barcode within the target frame boundaries',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 48),
          
          // Target scanner boundary
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 2),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                // Corner highlighted laser lines
                const Positioned(
                  top: 0,
                  left: 0,
                  child: Icon(Icons.crop_free, size: 36, color: AppColors.primary),
                ),
                // Animated red laser sweep line
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 10, end: 190),
                  duration: const Duration(seconds: 1),
                  builder: (context, val, child) {
                    return Positioned(
                      top: val,
                      left: 10,
                      right: 10,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          color: AppColors.critical,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.critical.withOpacity(0.8),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _isScanning = false;
              });
            },
            child: const Text('CANCEL SCANNING'),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerFeed() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: 4,
      itemBuilder: (context, index) => Container(
        height: 72,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.developer_board_off_outlined, color: AppColors.textMuted, size: 64),
          const SizedBox(height: 16),
          Text(
            'No boards logged',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Check network filters or check scan logs.',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.critical, size: 48),
          const SizedBox(height: 16),
          Text(
            'Failed to read board records',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _triggerSearch,
            child: const Text('RELOAD RECORDS'),
          ),
        ],
      ),
    );
  }
}
