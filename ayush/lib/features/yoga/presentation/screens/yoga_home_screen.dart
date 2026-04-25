import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/asana.dart';
import '../../providers/yoga_provider.dart';

class YogaHomeScreen extends ConsumerStatefulWidget {
  const YogaHomeScreen({super.key});

  @override
  ConsumerState<YogaHomeScreen> createState() => _YogaHomeScreenState();
}

class _YogaHomeScreenState extends ConsumerState<YogaHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _bgColor = Color(0xFFF5F5F0);
  static const _teal = Color(0xFF00BFA5);
  static const _tealLight = Color(0xFFE0F7F4);

  final _tabs = const [
    {'label': 'Vata', 'icon': '🌬️'},
    {'label': 'Pitta', 'icon': '🔥'},
    {'label': 'Kapha', 'icon': '🌿'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asanasAsync = ref.watch(asanasProvider);

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Yoga For You',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: _teal,
              indicatorWeight: 2.5,
              labelColor: _teal,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              tabs: _tabs.map((t) => Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(t['icon']!, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(t['label']!),
                  ],
                ),
              )).toList(),
            ),
          ),
        ),
      ),
      body: asanasAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF00BFA5)),
        ),
        error: (err, _) => Center(
          child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
        ),
        data: (asanas) {
          final vata = asanas.where((a) => a.dosha == 'vata').toList();
          final pitta = asanas.where((a) => a.dosha == 'pitta').toList();
          final kapha = asanas.where((a) => a.dosha == 'kapha').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(vata),
              _buildList(pitta),
              _buildList(kapha),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(List<Asana> asanas) {
    if (asanas.isEmpty) {
      return const Center(
        child: Text('No asanas available for this dosha.',
            style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      itemCount: asanas.length,
      itemBuilder: (context, index) {
        final asana = asanas[index];
        // Alternate image left vs right
        final imageOnLeft = index % 2 == 0;
        return _AsanaCard(
          asana: asana,
          imageOnLeft: imageOnLeft,
          onTap: () => context.push('/yoga/detail', extra: asana),
        );
      },
    );
  }
}

class _AsanaCard extends StatelessWidget {
  final Asana asana;
  final bool imageOnLeft;
  final VoidCallback onTap;

  static const _teal = Color(0xFF00BFA5);
  static const _tealLight = Color(0xFFE0F7F4);

  const _AsanaCard({
    required this.asana,
    required this.imageOnLeft,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageWidget = SizedBox(
      width: 110,
      child: Image.asset(
        asana.localImagePath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.self_improvement, size: 64, color: Colors.grey),
        ),
      ),
    );

    final contentWidget = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sanskrit name
          Text(
            asana.nameSanskrit,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00BFA5),
            ),
          ),
          const SizedBox(height: 2),
          // English name
          Text(
            asana.nameEnglish,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          // Chips row
          Row(
            children: [
              _Chip(
                icon: Icons.sports_gymnastics,
                label: asana.difficulty.toUpperCase(),
              ),
              const SizedBox(width: 8),
              _Chip(
                icon: Icons.timer_outlined,
                label: '${asana.holdSeconds}S',
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Description
          Text(
            asana.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 10),
          // GO button
          SizedBox(
            height: 34,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 28),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'GO',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: imageOnLeft
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [imageWidget, const SizedBox(width: 12), contentWidget],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [contentWidget, const SizedBox(width: 12), imageWidget],
            ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
