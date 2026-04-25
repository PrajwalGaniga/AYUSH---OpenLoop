import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../data/community_repository.dart';

class MyRequestsScreen extends ConsumerStatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  ConsumerState<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends ConsumerState<MyRequestsScreen> {
  final String _currentUserId = 'current_user';
  final _repo = CommunityRepository();
  late Future<List<Map<String, dynamic>>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _requestsFuture = _repo.fetchMyRequests(_currentUserId);
  }

  void _refresh() {
    setState(() {
      _requestsFuture = _repo.fetchMyRequests(_currentUserId);
    });
  }

  String _timeAgo(String? isoString) {
    if (isoString == null) return '';
    final dt = DateTime.tryParse(isoString);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1F3C),
        title: const Text('Plant Requests',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _requestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white60)),
            );
          }
          final requests = snapshot.data ?? [];
          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.inbox_outlined, size: 72, color: Colors.white24),
                  SizedBox(height: 16),
                  Text('No requests yet',
                      style: TextStyle(
                          color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(
                    'When someone wants your plant,\ntheir message appears here',
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            color: const Color(0xFF4CAF50),
            onRefresh: () async => _refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _RequestCard(
                request: requests[i],
                timeAgo: _timeAgo,
                onRespond: (requestId, accept) async {
                  try {
                    final uri = Uri.parse(
                      'http://10.0.2.2:8000/api/v1/community/contact-requests/$requestId'
                      '?user_id=$_currentUserId&accept=$accept',
                    );
                    await http.patch(uri);
                    _refresh();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(accept
                            ? 'Request accepted! ✅'
                            : 'Request declined'),
                        backgroundColor:
                            accept ? const Color(0xFF4CAF50) : Colors.red,
                      ));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final String Function(String?) timeAgo;
  final Future<void> Function(String requestId, bool accept) onRespond;

  const _RequestCard({
    required this.request,
    required this.timeAgo,
    required this.onRespond,
  });

  @override
  Widget build(BuildContext context) {
    final status = request['status'] ?? 'pending';
    final isPending = status == 'pending';

    return Card(
      color: const Color(0xFF0D1F3C),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF2d6a4f),
              child: Text(
                (request['from_display_name'] as String? ?? '?')[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request['from_display_name'] ?? 'Unknown',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'wants your ${request['plant_name'] ?? 'plant'}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A5F),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      request['message'] ?? '',
                      style: const TextStyle(color: Colors.white60, fontSize: 13),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    timeAgo(request['created_at']?.toString()),
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isPending)
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 28),
                    onPressed: () => onRespond(request['request_id'], true),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(height: 8),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.redAccent, size: 28),
                    onPressed: () => onRespond(request['request_id'], false),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'accepted'
                      ? const Color(0xFF4CAF50).withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: status == 'accepted' ? const Color(0xFF4CAF50) : Colors.red,
                  ),
                ),
                child: Text(
                  status[0].toUpperCase() + status.substring(1),
                  style: TextStyle(
                    color: status == 'accepted' ? const Color(0xFF4CAF50) : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
