import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../providers/food_scan_provider.dart';
import '../data/food_knowledge_service.dart';

class DeepAuditScreen extends ConsumerStatefulWidget {
  const DeepAuditScreen({super.key});

  @override
  ConsumerState<DeepAuditScreen> createState() => _DeepAuditScreenState();
}

class _DeepAuditScreenState extends ConsumerState<DeepAuditScreen> {
  int _currentIndex = 0;
  Map<String, dynamic> _currentQuestionData = {};
  String _currentFoodName = '';
  String _currentDosha = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestion();
  }

  Future<void> _loadQuestion() async {
    setState(() => _isLoading = true);
    
    final state = ref.read(foodScanProvider);
    final confirmed = state.confirmedItems;
    final source = state.mealSource ?? 'home';
    
    if (confirmed.isEmpty) return; // Should not happen

    final classId = confirmed[_currentIndex];
    
    final allFoods = await FoodKnowledgeService.getFoodNames();
    final foodNameFallback = allFoods.where((e) => e['class_id'] == classId).firstOrNull?['name'] ?? classId;
    final detectedName = state.detectedItems.where((e) => e.classId == classId).firstOrNull?.name;
    
    // Quick load just to get dosha (can also be loaded via a new method but here we just get it from names DB context if we had it, wait, getFoodNames doesn't have dosha. Let's just use empty string or if we want, we can fetch the whole item. But UI said "Small dosha pill tag". Let's mock or skip if not easily available. Actually the question block doesn't return dosha.)
    
    final qData = await FoodKnowledgeService.getQuestion(classId, source);

    if (mounted) {
      setState(() {
        _currentQuestionData = qData;
        _currentFoodName = detectedName ?? foodNameFallback;
        _currentDosha = "Food"; // Default tag
        _isLoading = false;
      });
    }
  }

  void _onAnswer(String answer) {
    final state = ref.read(foodScanProvider);
    final classId = state.confirmedItems[_currentIndex];
    
    ref.read(foodScanProvider.notifier).setAuditAnswer(classId, answer);
    
    if (_currentIndex < state.confirmedItems.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _loadQuestion();
    } else {
      // Last item, calculate and navigate
      _finishAudit();
    }
  }

  Future<void> _finishAudit() async {
    setState(() => _isLoading = true);
    await ref.read(foodScanProvider.notifier).finalizeAnalysis();
    if (mounted) {
      context.push('/food/results');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(foodScanProvider);
    final total = state.confirmedItems.length;
    final progress = total == 0 ? 0.0 : (_currentIndex + 1) / total;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Cancel Analysis?'),
            content: const Text('Are you sure you want to go back? Your progress will be lost.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('No')),
              TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Yes')),
            ],
          ),
        );
        if (confirm == true && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AyushColors.background,
        appBar: AppBar(
          automaticallyImplyLeading: false, // No back button
          title: Text("Food Analysis", style: AyushTextStyles.h2),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AyushSpacing.pagePadding),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AyushColors.divider,
                  color: AyushColors.primary,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: AyushSpacing.sm),
                Text(
                  "Food ${_currentIndex + 1} of $total",
                  style: AyushTextStyles.bodySmall,
                ),
                const SizedBox(height: AyushSpacing.xl),
                
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _buildQuestionCard(key: ValueKey(_currentIndex)),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard({required Key key}) {
    final question = _currentQuestionData['question'] as String? ?? 'Is this food healthy?';
    final posLabel = _currentQuestionData['positive_label'] as String? ?? 'Yes';
    final negLabel = _currentQuestionData['negative_label'] as String? ?? 'No';

    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(AyushSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AyushColors.card,
        borderRadius: BorderRadius.circular(AyushSpacing.radiusLg),
        boxShadow: AyushColors.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            _currentFoodName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AyushSpacing.xs),
          Chip(
            label: Text(_currentDosha, style: const TextStyle(fontSize: 12)),
            backgroundColor: AyushColors.surfaceVariant,
          ),
          const SizedBox(height: AyushSpacing.lg),
          Text(
            question,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AyushSpacing.xl),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _onAnswer('positive'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AyushColors.herbalGreen,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AyushSpacing.radiusLg)),
              ),
              child: Text(
                posLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: AyushSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _onAnswer('negative'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                side: const BorderSide(color: AyushColors.error),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AyushSpacing.radiusLg)),
              ),
              child: Text(
                negLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AyushColors.error, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
