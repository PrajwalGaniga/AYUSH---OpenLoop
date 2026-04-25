import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/plant_post.dart';
import '../providers/community_provider.dart';
import 'post_detail_screen.dart';
import '../../auth/providers/auth_provider.dart';

class CommunityFeedScreen extends ConsumerStatefulWidget {
  final double userLat;
  final double userLng;
  final List<PlantPost> posts;

  const CommunityFeedScreen({
    super.key,
    required this.userLat,
    required this.userLng,
    required this.posts,
  });

  @override
  ConsumerState<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends ConsumerState<CommunityFeedScreen> {
  String? _activeFilter;
  List<PlantPost> get _filtered {
    if (_activeFilter == null || _activeFilter == 'all') return widget.posts;
    if (_activeFilter == 'nearest') {
      final sorted = [...widget.posts];
      sorted.sort((a, b) => (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999));
      return sorted;
    }
    return widget.posts.where((p) => p.availability.name == _activeFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter chips row
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              _buildFilterChip('🌿 All', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('📍 Nearest', 'nearest'),
              const SizedBox(width: 8),
              _buildFilterChip('🟡 Few', 'few'),
              const SizedBox(width: 8),
              _buildFilterChip('🔵 Moderate', 'moderate'),
              const SizedBox(width: 8),
              _buildFilterChip('🟢 Abundant', 'abundant'),
            ],
          ),
        ),
        // Post list
        Expanded(
          child: _filtered.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  color: const Color(0xFF4CAF50),
                  onRefresh: () async => ref.invalidate(nearbyPostsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _PostCard(post: _filtered[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final selected = _activeFilter == value || (_activeFilter == null && value == 'all');
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2d6a4f) : const Color(0xFF1E3A5F),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF4CAF50) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white60,
            fontSize: 13,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🌱', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text('No plants posted near you yet',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Be the first to share!',
              style: TextStyle(color: Colors.white54, fontSize: 14)),
        ],
      ),
    );
  }
}

class _PostCard extends ConsumerStatefulWidget {
  final PlantPost post;
  const _PostCard({required this.post});

  @override
  ConsumerState<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<_PostCard> {
  int _photoIndex = 0;

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final authUser = ref.watch(authProvider).value;
    final currentUserId = authUser?.userId ?? 'current_user';
    final isOwner = post.userId == currentUserId;
    
    final displayName = isOwner ? 'My Post' : post.userDisplayName;
    final avatarLetter = isOwner 
        ? (authUser?.profile?['name']?.isNotEmpty == true ? authUser!.profile!['name'][0].toUpperCase() : 'M')
        : (post.userDisplayName.isNotEmpty ? post.userDisplayName[0].toUpperCase() : '?');

    return Card(
      color: const Color(0xFF0D1F3C),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: isOwner ? const Color(0xFF1E3A5F) : const Color(0xFF2d6a4f),
                  child: Text(
                    avatarLetter,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName,
                          style: TextStyle(
                              color: isOwner ? const Color(0xFF4CAF50) : Colors.white, 
                              fontWeight: FontWeight.bold, 
                              fontSize: 13)),
                      Text(
                        '${post.location.neighborhood}${post.distanceLabel.isNotEmpty ? " · ${post.distanceLabel}" : ""}',
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: post.availability.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: post.availability.color),
                  ),
                  child: Text(post.availability.label,
                      style: TextStyle(color: post.availability.color, fontSize: 11)),
                ),
              ],
            ),
            // Photos
            if (post.photoUrls.isNotEmpty) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    SizedBox(
                      height: 200,
                      child: PageView.builder(
                        itemCount: post.photoUrls.length,
                        onPageChanged: (i) => setState(() => _photoIndex = i),
                        itemBuilder: (_, i) => CachedNetworkImage(
                          imageUrl: post.photoUrls[i],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (_, __) => Container(
                            color: const Color(0xFF1E3A5F),
                            child: const Center(
                                child: CircularProgressIndicator(color: Color(0xFF4CAF50))),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: const Color(0xFF1E3A5F),
                            child: const Icon(Icons.eco, color: Color(0xFF4CAF50), size: 48),
                          ),
                        ),
                      ),
                    ),
                    if (post.photoUrls.length > 1)
                      Positioned(
                        bottom: 8,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            post.photoUrls.length,
                            (i) => Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _photoIndex == i ? Colors.white : Colors.white38,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(post.plantName,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
            Text(post.description,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.schedule, size: 12, color: Colors.white38),
                const SizedBox(width: 4),
                Text('${post.daysLeft}d left',
                    style: const TextStyle(color: Colors.white38, fontSize: 11)),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    post.isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: post.isSaved ? const Color(0xFF4CAF50) : Colors.white38,
                  ),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  onPressed: () => ref
                      .read(nearbyPostsProvider.notifier)
                      .toggleSave(post.postId, currentUserId),
                ),
                const SizedBox(width: 8),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
                  ),
                  child: const Text('View →'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
