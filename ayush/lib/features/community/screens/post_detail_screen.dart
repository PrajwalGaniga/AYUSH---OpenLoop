import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/plant_post.dart';
import '../data/community_repository.dart';

class PostDetailScreen extends StatefulWidget {
  final PlantPost post;
  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late PlantPost _post;
  int _photoIndex = 0;
  // For MVP: using a placeholder current user id
  final String _currentUserId = 'current_user';
  final _repo = CommunityRepository();

  @override
  void initState() {
    super.initState();
    _post = widget.post;
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = _post.userId == _currentUserId;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Photo sliver app bar
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: const Color(0xFF0D1F3C),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  if (isOwner)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: _confirmDelete,
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.flag_outlined, color: Colors.white70),
                      onPressed: _showFlagDialog,
                    ),
                  IconButton(
                    icon: Icon(
                      _post.isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: _post.isSaved ? const Color(0xFF4CAF50) : Colors.white,
                    ),
                    onPressed: _toggleSave,
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: _post.photoUrls.isNotEmpty
                      ? Stack(
                          children: [
                            PageView.builder(
                              itemCount: _post.photoUrls.length,
                              onPageChanged: (i) => setState(() => _photoIndex = i),
                              itemBuilder: (_, i) => CachedNetworkImage(
                                imageUrl: _post.photoUrls[i],
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => _plantPlaceholder(),
                              ),
                            ),
                            if (_post.photoUrls.length > 1)
                              Positioned(
                                bottom: 12,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    _post.photoUrls.length,
                                    (i) => Container(
                                      width: 7, height: 7,
                                      margin: const EdgeInsets.symmetric(horizontal: 3),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _photoIndex == i ? Colors.white : Colors.white38,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        )
                      : _plantPlaceholder(),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title & availability
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              _post.plantName,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _post.availability.color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _post.availability.color),
                            ),
                            child: Text(_post.availability.label,
                                style: TextStyle(color: _post.availability.color, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(_post.location.neighborhood,
                          style: const TextStyle(color: Colors.white54, fontSize: 14)),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Color(0xFF4CAF50)),
                          Text(_post.distanceLabel,
                              style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 14)),
                          const Spacer(),
                          const Icon(Icons.schedule, size: 13, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text('${_post.daysLeft} days left',
                              style: const TextStyle(color: Colors.amber, fontSize: 12)),
                        ],
                      ),

                      const Divider(color: Colors.white12, height: 32),

                      // Description
                      const Text('ABOUT THIS PLANT',
                          style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1.5)),
                      const SizedBox(height: 8),
                      Text(_post.description,
                          style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5)),

                      const Divider(color: Colors.white12, height: 32),

                      // Location
                      const Text('WHERE TO FIND IT',
                          style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1.5)),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () async {
                          final url = Uri.parse(
                              'https://maps.google.com?q=${_post.location.lat},${_post.location.lng}');
                          if (await canLaunchUrl(url)) launchUrl(url);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A5F),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.map, color: Color(0xFF4CAF50), size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_post.location.neighborhood,
                                        style: const TextStyle(
                                            color: Colors.white, fontWeight: FontWeight.bold)),
                                    const Text('Tap to open in Google Maps',
                                        style: TextStyle(color: Colors.white38, fontSize: 12)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.white38),
                            ],
                          ),
                        ),
                      ),

                      const Divider(color: Colors.white12, height: 32),

                      // Posted by
                      const Text('POSTED BY',
                          style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1.5)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFF2d6a4f),
                            child: Text(
                              _post.userDisplayName.isNotEmpty
                                  ? _post.userDisplayName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(_post.userDisplayName,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Text(_timeAgo(_post.createdAt),
                              style: const TextStyle(color: Colors.white38, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom action bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF0D1F3C),
                  border: Border(top: BorderSide(color: Color(0xFF1E3A5F))),
                ),
                child: _buildActionBar(isOwner, context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(bool isOwner, BuildContext context) {
    if (isOwner) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24),
                foregroundColor: Colors.white70,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _confirmDelete,
              child: const Text('Delete Post'),
            ),
          ),
        ],
      );
    }

    if (_post.contactPreference == ContactPreference.inApp) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => _showContactSheet(context),
          child: const Text('📨 Send Contact Request →', style: TextStyle(fontSize: 16)),
        ),
      );
    }

    if (_post.contactPreference == ContactPreference.whatsapp &&
        _post.whatsappNumber != null) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () async {
            final url = Uri.parse('https://wa.me/${_post.whatsappNumber}');
            if (await canLaunchUrl(url)) launchUrl(url);
          },
          child: const Text('💬 Contact on WhatsApp →', style: TextStyle(fontSize: 16)),
        ),
      );
    }

    return const Center(
      child: Text('This poster prefers not to be contacted',
          style: TextStyle(color: Colors.white38, fontSize: 13)),
    );
  }

  void _showContactSheet(BuildContext context) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D1F3C),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Request this plant',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('${_post.plantName} from ${_post.userDisplayName}',
                style: const TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              maxLines: 4,
              maxLength: 500,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Your message',
                labelStyle: const TextStyle(color: Colors.white38),
                hintText: 'Hello, I\'m interested in getting some ${_post.plantName}...',
                hintStyle: const TextStyle(color: Colors.white24),
                counterStyle: const TextStyle(color: Colors.white38),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF4CAF50)),
                ),
                filled: true,
                fillColor: const Color(0xFF1E3A5F),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  if (controller.text.trim().length < 10) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please write a message (min 10 characters)')),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  try {
                    await _repo.sendContactRequest(
                      fromUserId: _currentUserId,
                      fromDisplayName: 'Me',
                      toUserId: _post.userId,
                      postId: _post.postId,
                      plantName: _post.plantName,
                      message: controller.text.trim(),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Request sent! ✅'),
                          backgroundColor: Color(0xFF4CAF50),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed: $e')),
                      );
                    }
                  }
                },
                child: const Text('Send Request →', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleSave() async {
    try {
      final newSaved = await _repo.toggleSave(_post.postId, _currentUserId);
      setState(() {
        _post = _post.copyWith(
          isSaved: newSaved,
          savedByCount: newSaved ? _post.savedByCount + 1 : _post.savedByCount - 1,
        );
      });
    } catch (_) {}
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0D1F3C),
        title: const Text('Delete post?', style: TextStyle(color: Colors.white)),
        content: const Text('This cannot be undone.',
            style: TextStyle(color: Colors.white60)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _repo.deletePost(_post.postId, _currentUserId);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Post deleted')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showFlagDialog() {
    String? selected;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: const Color(0xFF0D1F3C),
          title: const Text('Report this post', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              'Wrong plant information',
              'Spam or fake',
              'Inappropriate content',
            ].map((reason) => RadioListTile<String>(
                  value: reason,
                  groupValue: selected,
                  activeColor: const Color(0xFF4CAF50),
                  title: Text(reason, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  onChanged: (v) => setState(() => selected = v),
                )).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () async {
                if (selected == null) return;
                Navigator.pop(ctx);
                await _repo.flagPost(_post.postId, _currentUserId, selected!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Post reported. We\'ll review it.')),
                  );
                }
              },
              child: const Text('Report', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _plantPlaceholder() {
    return Container(
      color: const Color(0xFF1E3A5F),
      child: const Center(
        child: Text('🌿', style: TextStyle(fontSize: 80)),
      ),
    );
  }
}
