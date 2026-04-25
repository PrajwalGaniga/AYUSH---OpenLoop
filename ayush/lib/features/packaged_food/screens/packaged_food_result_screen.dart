import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/packaged_food_provider.dart';
import '../models/packaged_food_result.dart';

class PackagedFoodResultScreen extends ConsumerWidget {
  const PackagedFoodResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(packagedFoodProvider).result;

    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Result')),
        body: const Center(child: Text('No result available')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, ref, result),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _RecommendationBanner(result: result),
                const SizedBox(height: 16),
                _ScoreCard(result: result),
                const SizedBox(height: 16),
                if (result.ingredients.isNotEmpty) ...[
                  _SectionHeader(title: '🧪 Ingredients Analysis'),
                  const SizedBox(height: 10),
                  _IngredientsCard(ingredients: result.ingredients),
                  const SizedBox(height: 16),
                ],
                _PosNegCard(
                  positives: result.positives,
                  negatives: result.negatives,
                ),
                const SizedBox(height: 16),
                if (result.ayurvedicNote.isNotEmpty) ...[
                  _AyurvedicNoteCard(note: result.ayurvedicNote),
                  const SizedBox(height: 16),
                ],
                if (result.allergenFlags.isNotEmpty) ...[
                  _AllergenCard(flags: result.allergenFlags),
                  const SizedBox(height: 16),
                ],
                if (result.servingTip.isNotEmpty) ...[
                  _ServingTipCard(tip: result.servingTip),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.document_scanner_outlined),
                    label: const Text('Scan Another',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A1B9A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      ref.read(packagedFoodProvider.notifier).reset();
                      context.pop();
                    },
                  ),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(
      BuildContext context, WidgetRef ref, PackagedFoodResult result) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: const Color(0xFF6A1B9A),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 90, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                result.productName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                result.brand,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Recommendation Banner ────────────────────────────────────────────────────

class _RecommendationBanner extends StatelessWidget {
  final PackagedFoodResult result;
  const _RecommendationBanner({required this.result});

  @override
  Widget build(BuildContext context) {
    final isBuy = result.recommendation == 'buy';
    final isSkip = result.recommendation == 'skip';
    final color = isBuy
        ? const Color(0xFF2E7D32)
        : isSkip
            ? const Color(0xFFC62828)
            : const Color(0xFFE65100);
    final bgColor = isBuy
        ? const Color(0xFFE8F5E9)
        : isSkip
            ? const Color(0xFFFFEBEE)
            : const Color(0xFFFFF3E0);
    final emoji = isBuy ? '✅' : isSkip ? '🚫' : '⚠️';
    final label = isBuy ? 'BUY THIS' : isSkip ? 'SKIP THIS' : 'MODERATE USE';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(
                  result.recommendationReason,
                  style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Score Card ───────────────────────────────────────────────────────────────

class _ScoreCard extends StatelessWidget {
  final PackagedFoodResult result;
  const _ScoreCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final score = result.overallScore;
    final color = score >= 70
        ? const Color(0xFF2E7D32)
        : score >= 45
            ? const Color(0xFFE65100)
            : const Color(0xFFC62828);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 7,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
                Text('$score',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: color)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Health Score',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87)),
                const SizedBox(height: 4),
                Text(
                  score >= 70
                      ? 'Good choice for your body type'
                      : score >= 45
                          ? 'Consume in moderation'
                          : 'Not ideal for your constitution',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ingredients Card ─────────────────────────────────────────────────────────

class _IngredientsCard extends StatelessWidget {
  final List<PackagedFoodIngredient> ingredients;
  const _IngredientsCard({required this.ingredients});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: ingredients.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: Colors.grey.shade100),
        itemBuilder: (_, i) {
          final ing = ingredients[i];
          return ListTile(
            leading: Icon(
              ing.isConcerning ? Icons.warning_amber_rounded : Icons.check_circle_outline,
              color: ing.isConcerning ? Colors.orange : Colors.green,
              size: 22,
            ),
            title: Text(ing.name,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text(ing.reason,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          );
        },
      ),
    );
  }
}

// ── Positives / Negatives ────────────────────────────────────────────────────

class _PosNegCard extends StatelessWidget {
  final List<String> positives;
  final List<String> negatives;
  const _PosNegCard({required this.positives, required this.negatives});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('✅ Positives',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                        fontSize: 13)),
                const SizedBox(height: 8),
                ...positives.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $p',
                          style: const TextStyle(fontSize: 12, height: 1.4)),
                    )),
                if (positives.isEmpty)
                  const Text('None identified',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Container(width: 1, color: Colors.grey.shade200, margin: const EdgeInsets.symmetric(horizontal: 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('❌ Negatives',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFC62828),
                        fontSize: 13)),
                const SizedBox(height: 8),
                ...negatives.map((n) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $n',
                          style: const TextStyle(fontSize: 12, height: 1.4)),
                    )),
                if (negatives.isEmpty)
                  const Text('None identified',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ayurvedic Note ───────────────────────────────────────────────────────────

class _AyurvedicNoteCard extends StatelessWidget {
  final String note;
  const _AyurvedicNoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCE93D8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🌿', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ayurvedic Perspective',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6A1B9A),
                        fontSize: 13)),
                const SizedBox(height: 4),
                Text(note,
                    style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Allergen Card ────────────────────────────────────────────────────────────

class _AllergenCard extends StatelessWidget {
  final List<String> flags;
  const _AllergenCard({required this.flags});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⚠️ Allergen Flags',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: flags
                .map((f) => Chip(
                      label: Text(f,
                          style: TextStyle(
                              fontSize: 12, color: Colors.orange.shade900)),
                      backgroundColor: Colors.orange.shade100,
                      side: BorderSide(color: Colors.orange.shade300),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ── Serving Tip Card ─────────────────────────────────────────────────────────

class _ServingTipCard extends StatelessWidget {
  final String tip;
  const _ServingTipCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Serving Tip',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Text(tip, style: const TextStyle(fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87));
  }
}
