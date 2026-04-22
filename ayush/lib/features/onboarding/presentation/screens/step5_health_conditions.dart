import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/onboarding_models.dart';
import '../../providers/onboarding_provider.dart';
import '../screens/onboarding_shell.dart';
import '../../../../features/auth/presentation/widgets/ayush_button.dart';

const _conditionCategories = [
  _ConditionCategory('🔴 Metabolic', [
    'Diabetes Type 1', 'Diabetes Type 2', 'Thyroid disorder', 'Obesity', 'PCOS'
  ]),
  _ConditionCategory('❤️ Cardiovascular', [
    'Hypertension', 'Heart disease', 'High cholesterol'
  ]),
  _ConditionCategory('🫁 Respiratory', [
    'Asthma', 'COPD', 'Allergic rhinitis'
  ]),
  _ConditionCategory('🧠 Neurological', [
    'Migraine', 'Epilepsy', "Parkinson's"
  ]),
  _ConditionCategory('🧘 Mental Health', [
    'Anxiety', 'Depression', 'Insomnia', 'Bipolar disorder'
  ]),
  _ConditionCategory('🦴 Musculoskeletal', [
    'Arthritis', 'Back pain', 'Osteoporosis'
  ]),
  _ConditionCategory('💊 Digestive', [
    'IBS', 'GERD/Acid reflux', 'Constipation', 'Ulcers'
  ]),
  _ConditionCategory('🌸 Women\'s Health', [
    'PCOS', 'Endometriosis', 'Menstrual disorders'
  ]),
  _ConditionCategory('🩺 Skin', ['Psoriasis', 'Eczema', 'Acne']),
  _ConditionCategory('🧬 Other', ['Cancer', 'Autoimmune', 'Kidney disease']),
];

class _ConditionCategory {
  final String title;
  final List<String> conditions;
  const _ConditionCategory(this.title, this.conditions);
}

class Step5HealthConditions extends ConsumerStatefulWidget {
  const Step5HealthConditions({super.key});

  @override
  ConsumerState<Step5HealthConditions> createState() => _Step5HealthConditionsState();
}

class _Step5HealthConditionsState extends ConsumerState<Step5HealthConditions> {
  final _searchCtrl = TextEditingController();
  final Set<String> _selectedConditions = {};
  final Set<String> _expandedCategories = {};
  final List<String> _allergies = [];
  final _allergyCtrl = TextEditingController();
  final List<MedicationItem> _medications = [];
  final Set<String> _familyHistory = {};
  bool _showAddMed = false;
  final _medNameCtrl = TextEditingController();
  final _medDosageCtrl = TextEditingController();
  String _medFrequency = 'once';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    _allergyCtrl.dispose();
    _medNameCtrl.dispose();
    _medDosageCtrl.dispose();
    super.dispose();
  }

  List<String> get _filteredConditions {
    if (_searchQuery.isEmpty) return [];
    return _conditionCategories
        .expand((c) => c.conditions)
        .where((c) => c.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Future<void> _submit() async {
    ref.read(onboardingProvider.notifier).updateHealthConditions(
          diagnosedConditions: _selectedConditions.toList(),
          chronicConditions: [],
          allergies: _allergies,
          currentMedications: _medications,
          surgeries: [],
          familyHistory: _familyHistory.toList(),
        );

    final userId = ref.read(authProvider).value?.userId ?? '';
    try {
      await ref.read(onboardingProvider.notifier).submitStep5(userId);
      if (mounted) context.go('/onboarding/5');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save. Please retry.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(onboardingProvider).isLoading;

    return OnboardingShell(
      currentStep: 4,
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AyushSpacing.pagePadding, AyushSpacing.lg,
                  AyushSpacing.pagePadding, 0,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your health\nhistory', style: AyushTextStyles.h1)
                          .animate().fadeIn(duration: 500.ms),
                      const SizedBox(height: 8),
                      Text(
                        'This helps us avoid recommendations that could harm you',
                        style: AyushTextStyles.bodyMedium,
                      ).animate(delay: 100.ms).fadeIn(duration: 500.ms),
                      const SizedBox(height: 24),

                      // ── Search ──────────────────────────────────────────
                      TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: InputDecoration(
                          hintText: 'Search conditions...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                        ),
                      ).animate(delay: 150.ms).fadeIn(duration: 500.ms),

                      // Search results
                      if (_filteredConditions.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _filteredConditions.map((c) {
                            final selected = _selectedConditions.contains(c);
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  if (selected) _selectedConditions.remove(c);
                                  else _selectedConditions.add(c);
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: selected ? AyushColors.primarySurface : AyushColors.card,
                                  borderRadius: BorderRadius.circular(AyushSpacing.radiusFull),
                                  border: Border.all(
                                    color: selected ? AyushColors.primary : AyushColors.border,
                                  ),
                                ),
                                child: Text(
                                  c,
                                  style: AyushTextStyles.labelSmall.copyWith(
                                    color: selected ? AyushColors.primary : AyushColors.textSecondary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      // Selected conditions chips
                      if (_selectedConditions.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text('Selected', style: AyushTextStyles.labelSmall),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedConditions.map((c) => Chip(
                            label: Text(c),
                            backgroundColor: AyushColors.primarySurface,
                            side: const BorderSide(color: AyushColors.primary),
                            deleteIcon: const Icon(Icons.close, size: 14),
                            onDeleted: () => setState(() => _selectedConditions.remove(c)),
                            labelStyle: AyushTextStyles.labelSmall.copyWith(color: AyushColors.primary),
                          )).toList(),
                        ),
                      ],

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // ── Categories accordion ──────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AyushSpacing.pagePadding),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final cat = _conditionCategories[i];
                      final isExpanded = _expandedCategories.contains(cat.title);
                      return _buildCategoryAccordion(cat, isExpanded);
                    },
                    childCount: _conditionCategories.length,
                  ),
                ),
              ),

              // ── Allergies ─────────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AyushSpacing.pagePadding, 24,
                  AyushSpacing.pagePadding, 0,
                ),
                sliver: SliverToBoxAdapter(
                  child: _buildAllergiesSection(),
                ),
              ),

              // ── Medications ───────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AyushSpacing.pagePadding, 24,
                  AyushSpacing.pagePadding, 0,
                ),
                sliver: SliverToBoxAdapter(
                  child: _buildMedicationsSection(),
                ),
              ),

              // ── Family history ────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AyushSpacing.pagePadding, 24,
                  AyushSpacing.pagePadding, 120,
                ),
                sliver: SliverToBoxAdapter(
                  child: _buildFamilyHistorySection(),
                ),
              ),
            ],
          ),

          // ── Buttons ───────────────────────────────────────────────────────
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
                    label: 'Continue',
                    onPressed: _submit,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.go('/onboarding/5'),
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

  Widget _buildCategoryAccordion(_ConditionCategory cat, bool isExpanded) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AyushColors.card,
        borderRadius: BorderRadius.circular(AyushSpacing.radiusMd),
        border: Border.all(color: AyushColors.divider),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(cat.title, style: AyushTextStyles.labelMedium),
            trailing: AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.expand_more, size: 20),
            ),
            onTap: () => setState(() {
              if (isExpanded) _expandedCategories.remove(cat.title);
              else _expandedCategories.add(cat.title);
            }),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: cat.conditions.map((c) {
                  final selected = _selectedConditions.contains(c);
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        if (selected) _selectedConditions.remove(c);
                        else _selectedConditions.add(c);
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AyushColors.primarySurface : AyushColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(AyushSpacing.radiusFull),
                        border: Border.all(
                          color: selected ? AyushColors.primary : AyushColors.border,
                        ),
                      ),
                      child: Text(
                        c,
                        style: AyushTextStyles.labelSmall.copyWith(
                          color: selected ? AyushColors.primary : AyushColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAllergiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Allergies', style: AyushTextStyles.labelMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _allergyCtrl,
                decoration: const InputDecoration(
                  hintText: 'e.g. Peanuts, Penicillin',
                  prefixIcon: Icon(Icons.warning_amber_outlined, size: 18),
                ),
                onSubmitted: (v) {
                  if (v.trim().isNotEmpty) {
                    setState(() {
                      _allergies.add(v.trim());
                      _allergyCtrl.clear();
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                if (_allergyCtrl.text.trim().isNotEmpty) {
                  setState(() {
                    _allergies.add(_allergyCtrl.text.trim());
                    _allergyCtrl.clear();
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(48, 54),
                padding: EdgeInsets.zero,
              ),
              child: const Icon(Icons.add),
            ),
          ],
        ),
        if (_allergies.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allergies.map((a) => Chip(
              label: Text(a),
              backgroundColor: const Color(0xFFFFF3E0),
              side: const BorderSide(color: AyushColors.warning),
              deleteIcon: const Icon(Icons.close, size: 14),
              onDeleted: () => setState(() => _allergies.remove(a)),
              labelStyle: AyushTextStyles.labelSmall.copyWith(color: AyushColors.textPrimary),
            )).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildMedicationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Current Medications', style: AyushTextStyles.labelMedium),
            TextButton.icon(
              onPressed: () => setState(() => _showAddMed = !_showAddMed),
              icon: Icon(_showAddMed ? Icons.close : Icons.add, size: 16),
              label: Text(_showAddMed ? 'Cancel' : 'Add'),
            ),
          ],
        ),

        if (_showAddMed) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AyushColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AyushSpacing.radiusMd),
              border: Border.all(color: AyushColors.border),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _medNameCtrl,
                  decoration: const InputDecoration(hintText: 'Medicine name'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _medDosageCtrl,
                        decoration: const InputDecoration(hintText: 'Dosage (e.g. 500mg)'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _medFrequency,
                      items: const [
                        DropdownMenuItem(value: 'once', child: Text('Once daily')),
                        DropdownMenuItem(value: 'twice', child: Text('Twice daily')),
                        DropdownMenuItem(value: 'thrice', child: Text('Thrice daily')),
                      ],
                      onChanged: (v) => setState(() => _medFrequency = v!),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    if (_medNameCtrl.text.trim().isNotEmpty) {
                      setState(() {
                        _medications.add(MedicationItem(
                          name: _medNameCtrl.text.trim(),
                          dosage: _medDosageCtrl.text.trim(),
                          frequency: _medFrequency,
                        ));
                        _medNameCtrl.clear();
                        _medDosageCtrl.clear();
                        _showAddMed = false;
                      });
                    }
                  },
                  child: const Text('Save Medication'),
                ),
              ],
            ),
          ),
        ],

        if (_medications.isNotEmpty) ...[
          const SizedBox(height: 10),
          ..._medications.map((m) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AyushColors.card,
              borderRadius: BorderRadius.circular(AyushSpacing.radiusMd),
              border: Border.all(color: AyushColors.divider),
            ),
            child: Row(
              children: [
                const Icon(Icons.medication_outlined, size: 18, color: AyushColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.name, style: AyushTextStyles.labelMedium),
                      Text('${m.dosage} · ${m.frequency}', style: AyushTextStyles.bodySmall),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16, color: AyushColors.textMuted),
                  onPressed: () => setState(() => _medications.remove(m)),
                ),
              ],
            ),
          )),
        ],
      ],
    );
  }

  Widget _buildFamilyHistorySection() {
    const options = [
      'Diabetes', 'Heart disease', 'Cancer', 'Hypertension',
      'Mental illness', 'Thyroid', 'None',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Family History', style: AyushTextStyles.labelMedium),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((o) {
            final selected = _familyHistory.contains(o);
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  if (o == 'None') {
                    _familyHistory.clear();
                    _familyHistory.add('None');
                  } else {
                    _familyHistory.remove('None');
                    if (selected) _familyHistory.remove(o);
                    else _familyHistory.add(o);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AyushColors.primarySurface : AyushColors.card,
                  borderRadius: BorderRadius.circular(AyushSpacing.radiusFull),
                  border: Border.all(
                    color: selected ? AyushColors.primary : AyushColors.border,
                  ),
                ),
                child: Text(
                  o,
                  style: AyushTextStyles.labelSmall.copyWith(
                    color: selected ? AyushColors.primary : AyushColors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
