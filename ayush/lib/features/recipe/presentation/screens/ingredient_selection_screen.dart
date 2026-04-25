import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/ingredient_data.dart';
import '../../providers/recipe_provider.dart';

class IngredientSelectionScreen extends ConsumerStatefulWidget {
  const IngredientSelectionScreen({super.key});

  @override
  ConsumerState<IngredientSelectionScreen> createState() =>
      _IngredientSelectionScreenState();
}

class _IngredientSelectionScreenState
    extends ConsumerState<IngredientSelectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: kIngredientCategories.length,
      vsync: this,
    );
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase().trim());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Ingredient> _filteredIngredients(IngredientCategory cat) {
    if (_searchQuery.isEmpty) return cat.ingredients;
    return cat.ingredients
        .where((i) => i.name.toLowerCase().contains(_searchQuery))
        .toList();
  }

  bool _isSearching() => _searchQuery.isNotEmpty;

  List<Ingredient> _allFiltered() {
    return kIngredientCategories
        .expand((c) => c.ingredients)
        .where((i) => i.name.toLowerCase().contains(_searchQuery))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recipeProvider);
    final selected = {
      ...state.primaryIngredients,
      ...state.spices,
    };
    final totalSelected = selected.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Select Ingredients',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_outlined, color: Colors.black54),
            onPressed: () => context.push('/recipe/history'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade100),
        ),
      ),
      body: Column(
        children: [
          // ── Search Bar ──────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search ingredients...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ── Category Tabs (hidden during search) ────────────────────────
          if (!_isSearching())
            Container(
              color: Colors.white,
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                itemCount: kIngredientCategories.length,
                itemBuilder: (_, i) {
                  final cat = kIngredientCategories[i];
                  return AnimatedBuilder(
                    animation: _tabController,
                    builder: (_, __) {
                      final isActive = _tabController.index == i;
                      return GestureDetector(
                        onTap: () => setState(() => _tabController.index = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: isActive ? cat.color : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isActive ? cat.color : Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            '${cat.emoji} ${cat.name}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                              color: isActive ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

          // ── Divider ────────────────────────────────────────────────────
          Container(height: 1, color: Colors.grey.shade100),

          // ── Chip Grid ──────────────────────────────────────────────────
          Expanded(
            child: _isSearching()
                ? _buildChipWrap(
                    _allFiltered(),
                    const Color(0xFF5C6BC0),
                    selected,
                  )
                : TabBarView(
                    controller: _tabController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: kIngredientCategories.map((cat) {
                      return _buildChipWrap(
                        _filteredIngredients(cat),
                        cat.color,
                        selected,
                      );
                    }).toList(),
                  ),
          ),

          // ── Bottom Bar ─────────────────────────────────────────────────
          _BottomBar(
            count: totalSelected,
            isLoading: state.isLoading,
            canGenerate: state.primaryIngredients.isNotEmpty,
            onGenerate: () async {
              final messenger = ScaffoldMessenger.of(context);
              final router = GoRouter.of(context);
              await ref.read(recipeProvider.notifier).generateRecipe();
              if (!mounted) return;
              if (ref.read(recipeProvider).error == null) {
                router.push('/recipe/display');
              } else {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(ref.read(recipeProvider).error ?? 'Error'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChipWrap(
    List<Ingredient> items,
    Color accentColor,
    Set<String> selected,
  ) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text('No ingredients found',
                style: TextStyle(color: Colors.grey.shade400)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 10,
        children: items.map((ingredient) {
          final isSelected = selected.contains(ingredient.name);
          final label = ingredient.emoji.isNotEmpty
              ? '${ingredient.emoji} ${ingredient.name}'
              : ingredient.name;

          // find category color if searching
          Color chipColor = accentColor;
          if (_isSearching()) {
            try {
              chipColor = kIngredientCategories
                  .firstWhere((c) => c.name == ingredient.category)
                  .color;
            } catch (_) {}
          }

          return _IngredientChip(
            label: label,
            isSelected: isSelected,
            accentColor: chipColor,
            onTap: () {
              final notifier = ref.read(recipeProvider.notifier);
              try {
                // Spice categories go to spices list
                final isSpiceCat = ingredient.category == 'Whole Spices' ||
                    ingredient.category == 'Spice Powders';
                if (isSpiceCat) {
                  notifier.toggleSpice(ingredient.name);
                } else {
                  notifier.togglePrimary(ingredient.name);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            },
          );
        }).toList(),
      ),
    );
  }
}

// ── Chip Widget ───────────────────────────────────────────────────────────────

class _IngredientChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _IngredientChip({
    required this.label,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accentColor : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

// ── Bottom Bar ────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final int count;
  final bool isLoading;
  final bool canGenerate;
  final VoidCallback onGenerate;

  const _BottomBar({
    required this.count,
    required this.isLoading,
    required this.canGenerate,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: count > 0
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count > 0 ? '$count selected' : 'None selected',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: count > 0
                    ? const Color(0xFF388E3C)
                    : Colors.grey.shade500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Generate button
          Expanded(
            child: AnimatedOpacity(
              opacity: canGenerate ? 1.0 : 0.5,
              duration: const Duration(milliseconds: 200),
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: canGenerate && !isLoading ? onGenerate : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF388E3C),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Generate Recipe',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
