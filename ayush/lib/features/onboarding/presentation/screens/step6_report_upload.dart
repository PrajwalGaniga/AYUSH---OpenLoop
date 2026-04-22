import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../screens/onboarding_shell.dart';
import '../../../../features/auth/presentation/widgets/ayush_button.dart';

class _UploadedFile {
  final String reportId;
  final String fileName;
  final double fileSizeMb;
  final bool isAnalyzing;
  final Map<String, dynamic>? extracted;
  bool userConfirmed;

  _UploadedFile({
    required this.reportId,
    required this.fileName,
    required this.fileSizeMb,
    this.isAnalyzing = false,
    this.extracted,
    this.userConfirmed = false,
  });

  _UploadedFile copyWith({
    bool? isAnalyzing,
    Map<String, dynamic>? extracted,
    bool? userConfirmed,
  }) {
    return _UploadedFile(
      reportId: reportId,
      fileName: fileName,
      fileSizeMb: fileSizeMb,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      extracted: extracted ?? this.extracted,
      userConfirmed: userConfirmed ?? this.userConfirmed,
    );
  }
}

class Step6ReportUpload extends ConsumerStatefulWidget {
  const Step6ReportUpload({super.key});

  @override
  ConsumerState<Step6ReportUpload> createState() => _Step6ReportUploadState();
}

class _Step6ReportUploadState extends ConsumerState<Step6ReportUpload> {
  final List<_UploadedFile> _files = [];

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result == null || result.files.isEmpty) return;

    final userId = ref.read(authProvider).value?.userId ?? '';

    for (final picked in result.files) {
      final file = picked.path != null ? File(picked.path!) : null;
      if (file == null) continue;

      final fileSizeMb = picked.size / (1024 * 1024);

      // Add placeholder entry
      final placeholder = _UploadedFile(
        reportId: DateTime.now().millisecondsSinceEpoch.toString(),
        fileName: picked.name,
        fileSizeMb: fileSizeMb,
        isAnalyzing: true,
      );
      setState(() => _files.add(placeholder));

      try {
        final dio = ref.read(dioClientProvider);
        final formData = FormData.fromMap({
          'userId': userId,
          'file': await MultipartFile.fromFile(
            file.path,
            filename: picked.name,
          ),
        });

        final response = await dio.post(
          ApiEndpoints.step6UploadReport,
          data: formData,
        );

        final data = response.data['data'];
        setState(() {
          final idx = _files.indexOf(placeholder);
          if (idx >= 0) {
            _files[idx] = _UploadedFile(
              reportId: data['reportId'],
              fileName: picked.name,
              fileSizeMb: fileSizeMb,
              isAnalyzing: false,
              extracted: Map<String, dynamic>.from(data['extractedData'] ?? {}),
            );
          }
        });
      } catch (e) {
        setState(() {
          final idx = _files.indexOf(placeholder);
          if (idx >= 0) {
            _files[idx] = _UploadedFile(
              reportId: placeholder.reportId,
              fileName: picked.name,
              fileSizeMb: fileSizeMb,
              isAnalyzing: false,
              extracted: {'extractionError': 'Upload failed. Please retry.'},
            );
          }
        });
      }
    }
  }

  Future<void> _confirmReport(int index) async {
    final f = _files[index];
    if (f.extracted == null) return;

    final userId = ref.read(authProvider).value?.userId ?? '';
    try {
      final dio = ref.read(dioClientProvider);
      await dio.post(ApiEndpoints.step6ConfirmReport, data: {
        'userId': userId,
        'reportId': f.reportId,
        'confirmedData': f.extracted,
      });
      setState(() => _files[index] = f.copyWith(userConfirmed: true));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to confirm. Please retry.')),
      );
    }
  }

  Future<void> _finalize() async {
    final userId = ref.read(authProvider).value?.userId ?? '';
    try {
      final ojas = await ref.read(onboardingProvider.notifier).calculateAndFinalizeOjas(userId);
      if (mounted) {
        context.go('/ojas-reveal', extra: {'ojasResult': ojas});
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to complete. Please retry.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(onboardingProvider).isLoading;

    return OnboardingShell(
      currentStep: 5,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AyushSpacing.pagePadding, AyushSpacing.lg,
              AyushSpacing.pagePadding, 140,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Upload your\nhealth reports', style: AyushTextStyles.h1)
                    .animate().fadeIn(duration: 500.ms),
                const SizedBox(height: 8),
                Text(
                  'AYUSH reads your reports using AI — no doctor needed',
                  style: AyushTextStyles.bodyMedium,
                ).animate(delay: 100.ms).fadeIn(duration: 500.ms),
                const SizedBox(height: 24),

                // ── Upload zone ─────────────────────────────────────────────
                GestureDetector(
                  onTap: _pickAndUpload,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                    decoration: BoxDecoration(
                      color: AyushColors.primarySurface,
                      borderRadius: BorderRadius.circular(AyushSpacing.radiusXl),
                      border: Border.all(
                        color: AyushColors.primary.withOpacity(0.4),
                        width: 2,
                        // Dashed via custom painter not needed — border radius handles it nicely
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AyushColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.upload_file_outlined,
                            color: AyushColors.primary,
                            size: 36,
                          ),
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 2000.ms),
                        const SizedBox(height: 16),
                        Text(
                          'Tap to upload PDF, JPG, or PNG',
                          style: AyushTextStyles.labelMedium.copyWith(color: AyushColors.primary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Blood reports, prescriptions, lab results',
                          style: AyushTextStyles.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ).animate(delay: 200.ms).fadeIn(duration: 500.ms),

                const SizedBox(height: 24),

                // ── Uploaded files ──────────────────────────────────────────
                ..._files.asMap().entries.map((entry) {
                  final i = entry.key;
                  final f = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildFileCard(f, i),
                  );
                }),
              ],
            ),
          ),

          // ── Bottom buttons ─────────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(AyushSpacing.pagePadding),
              decoration: BoxDecoration(
                color: AyushColors.background,
                border: Border(top: BorderSide(color: AyushColors.divider)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AyushButton(
                    label: 'Complete Onboarding',
                    onPressed: _finalize,
                    isLoading: isLoading,
                    icon: Icons.auto_awesome,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _finalize,
                    child: Text(
                      'Skip for now — I\'ll add later',
                      style: AyushTextStyles.bodyMedium.copyWith(color: AyushColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileCard(_UploadedFile f, int index) {
    return Container(
      decoration: BoxDecoration(
        color: AyushColors.card,
        borderRadius: BorderRadius.circular(AyushSpacing.radiusLg),
        border: Border.all(
          color: f.userConfirmed
              ? AyushColors.herbalGreen
              : f.isAnalyzing
                  ? AyushColors.primary.withOpacity(0.3)
                  : AyushColors.divider,
          width: f.userConfirmed ? 2 : 1,
        ),
        boxShadow: AyushColors.subtleShadow,
      ),
      child: Column(
        children: [
          // File info header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AyushColors.primarySurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.description_outlined, color: AyushColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.fileName, style: AyushTextStyles.labelMedium,
                          overflow: TextOverflow.ellipsis),
                      Text(
                        '${f.fileSizeMb.toStringAsFixed(1)} MB · ${f.isAnalyzing ? 'Analyzing...' : f.userConfirmed ? '✓ Confirmed' : '✓ Extracted'}',
                        style: AyushTextStyles.bodySmall.copyWith(
                          color: f.userConfirmed
                              ? AyushColors.herbalGreen
                              : f.isAnalyzing
                                  ? AyushColors.primary
                                  : AyushColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!f.isAnalyzing && !f.userConfirmed)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: AyushColors.textMuted),
                    onPressed: () => setState(() => _files.removeAt(index)),
                  ),
                if (f.userConfirmed)
                  const Icon(Icons.verified, color: AyushColors.herbalGreen, size: 20),
              ],
            ),
          ),

          // Analyzing shimmer
          if (f.isAnalyzing)
            Shimmer.fromColors(
              baseColor: AyushColors.surfaceVariant,
              highlightColor: AyushColors.primarySurface,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                height: 60,
                decoration: BoxDecoration(
                  color: AyushColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

          // Extraction review
          if (!f.isAnalyzing && f.extracted != null && !f.userConfirmed)
            _buildExtractionReview(f, index),
        ],
      ),
    );
  }

  Widget _buildExtractionReview(_UploadedFile f, int index) {
    final ext = f.extracted!;
    final hasError = ext.containsKey('extractionError');

    return Column(
      children: [
        const Divider(height: 1),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: Text(
              hasError ? '⚠️ Extraction issue' : 'AYUSH found the following',
              style: AyushTextStyles.labelMedium.copyWith(
                color: hasError ? AyushColors.warning : AyushColors.primary,
              ),
            ),
            initiallyExpanded: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasError)
                      Text(ext['extractionError'], style: AyushTextStyles.bodySmall)
                    else ...[
                      _buildExtractSection('Conditions', ext['conditions'] as List? ?? []),
                      _buildExtractSection('Medications', (ext['medications'] as List? ?? [])
                          .map((m) => m['name'] ?? '').toList()),
                      _buildVitals(ext['vitalSigns'] as Map<String, dynamic>? ?? {}),
                      if (ext['doctorNotes'] != null && (ext['doctorNotes'] as String).isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Doctor Notes', style: AyushTextStyles.labelSmall),
                        const SizedBox(height: 4),
                        Text(ext['doctorNotes'], style: AyushTextStyles.bodySmall),
                      ],
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Review and confirm to save',
                            style: AyushTextStyles.bodySmall,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => _confirmReport(index),
                          child: const Text('Confirm & Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExtractSection(String title, List items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(title, style: AyushTextStyles.labelSmall),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: items.whereType<String>()
              .where((s) => s.isNotEmpty)
              .map((s) => Chip(
                    label: Text(s, style: AyushTextStyles.caption),
                    backgroundColor: AyushColors.primarySurface,
                    side: const BorderSide(color: AyushColors.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildVitals(Map<String, dynamic> vitals) {
    final nonEmpty = vitals.entries.where((e) => e.value != null && e.value.toString().isNotEmpty);
    if (nonEmpty.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text('Vitals', style: AyushTextStyles.labelSmall),
        const SizedBox(height: 4),
        ...nonEmpty.map((e) => Text(
          '${e.key}: ${e.value}',
          style: AyushTextStyles.bodySmall,
        )),
      ],
    );
  }
}
