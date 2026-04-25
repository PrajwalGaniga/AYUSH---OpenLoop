import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fall_detection_manager.dart';
import '../../../core/env/env.dart';

class SosSettingsScreen extends StatefulWidget {
  const SosSettingsScreen({super.key});

  @override
  State<SosSettingsScreen> createState() => _SosSettingsScreenState();
}

class _SosSettingsScreenState extends State<SosSettingsScreen> {
  bool _fallDetectionEnabled = false;
  bool _loading = true;
  String _guardianNumber = '';
  final TextEditingController _phoneController = TextEditingController();

  static const _teal = Color(0xFF00897B);
  static const _danger = Color(0xFFD32F2F);
  static const _bg = Color(0xFFF5F5F0);

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fallDetectionEnabled = prefs.getBool('fall_detection_enabled') ?? false;
      _guardianNumber = prefs.getString('guardian_phone') ?? '';
      _phoneController.text = _guardianNumber;
      _loading = false;
    });
  }

  Future<void> _onToggle(bool value) async {
    if (value) {
      await _enableFallDetection();
    } else {
      await _disableFallDetection();
    }
  }

  Future<void> _enableFallDetection() async {
    // Step 1: Ensure guardian number is set
    if (_guardianNumber.isEmpty) {
      final number = await _showGuardianNumberDialog();
      if (number == null || number.isEmpty) return;
      _guardianNumber = number;
    }

    // Step 2: Request permissions
    final granted = await _requestPermissions();
    if (!granted) return;

    // Step 3: Save state and start service
    final prefs = await SharedPreferences.getInstance();
    final cleanNumber = _guardianNumber.replaceAll(RegExp(r'\D'), '');
    await prefs.setBool('fall_detection_enabled', true);
    await prefs.setString('guardian_phone', cleanNumber);
    await prefs.setString('api_base_url', Env.apiBaseUrl);

    await FallDetectionManager.instance.startService();

    setState(() => _fallDetectionEnabled = true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🛡️ Fall Detection ON — guardian: +91$cleanNumber'),
          backgroundColor: _teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _disableFallDetection() async {
    await FallDetectionManager.instance.stopService();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('fall_detection_enabled', false);

    setState(() => _fallDetectionEnabled = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fall Detection OFF'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<String?> _showGuardianNumberDialog() async {
    _phoneController.text = _guardianNumber;
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Guardian Phone Number', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the 10-digit number of the person who should receive emergency calls if you fall.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Text('+91', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.number,
                    maxLength: 10,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '9876543210',
                      border: OutlineInputBorder(
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '⚠️ For demo: use a Twilio-verified number.',
              style: TextStyle(color: Colors.orange, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _teal, foregroundColor: Colors.white),
            onPressed: () {
              final num = _phoneController.text.trim();
              if (num.length == 10) {
                Navigator.pop(ctx, num);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Enter a valid 10-digit number')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<bool> _requestPermissions() async {
    final statuses = await [
      Permission.notification,
      Permission.sensors,
      Permission.ignoreBatteryOptimizations,
    ].request();

    final allGranted = statuses.values.every(
      (s) => s.isGranted || s.isLimited,
    );

    if (!allGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('⚠️ Some permissions denied. Fall detection may not work reliably.'),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: openAppSettings,
          ),
        ),
      );
    }
    return true; // Allow even with partial permissions
  }

  Future<void> _testSOS() async {
    if (_guardianNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Set a guardian number first'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final clean = _guardianNumber.replaceAll(RegExp(r'\D'), '');
    final fullPhone = '+91$clean';
    final apiUrl = Env.apiBaseUrl;

    print('[SOS Test] Firing test SOS...');
    print('[SOS Test] Guardian: $fullPhone');
    print('[SOS Test] API URL: $apiUrl');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📡 Sending test SOS to $fullPhone...'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );

    try {
      final resp = await http.post(
        Uri.parse('$apiUrl/sos/trigger'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'guardian_phone': fullPhone,
          'user_name': 'Test User (Manual)',
        }),
      ).timeout(const Duration(seconds: 20));

      print('[SOS Test] Response status: ${resp.statusCode}');
      print('[SOS Test] Response body: ${resp.body}');

      if (!mounted) return;
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ SOS sent! Call SID: ${data['call_sid'] ?? 'N/A'}'),
            backgroundColor: _teal,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed (${resp.statusCode}): ${resp.body}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      print('[SOS Test] ERROR: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Network error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Settings', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── SOS / Fall Detection Card ──────────────────────────────
                _SectionCard(
                  icon: Icons.emergency_share,
                  iconColor: _danger,
                  title: 'Emergency SOS',
                  subtitle: 'Automatic fall detection and emergency alerts',
                  children: [
                    _ToggleRow(
                      title: 'Fall Detection',
                      subtitle: _fallDetectionEnabled
                          ? '🟢 Active — accelerometer monitoring ON'
                          : 'Detects falls and calls your guardian',
                      value: _fallDetectionEnabled,
                      onChanged: _onToggle,
                      activeColor: _teal,
                    ),
                    if (_guardianNumber.isNotEmpty) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.person_pin_circle, color: Colors.teal),
                        title: const Text('Guardian Number', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('+91 ${_guardianNumber.substring(0, 5)} ${_guardianNumber.substring(5)}'),
                        trailing: TextButton(
                          onPressed: () async {
                            setState(() => _guardianNumber = '');
                            final number = await _showGuardianNumberDialog();
                            if (number != null) {
                              setState(() => _guardianNumber = number);
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setString('guardian_phone', number);
                            }
                          },
                          child: const Text('Change'),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 16),

                // ── How it works Card ──────────────────────────────────────
                _SectionCard(
                  icon: Icons.info_outline,
                  iconColor: Colors.blue,
                  title: 'How Fall Detection Works',
                  subtitle: '',
                  children: [
                    _InfoStep(step: '1', text: 'Accelerometer monitors motion continuously in background'),
                    _InfoStep(step: '2', text: 'Free-fall detected when G-force drops below 0.5G'),
                    _InfoStep(step: '3', text: 'Impact confirmed when G-force exceeds 2.5G within 300ms'),
                    _InfoStep(step: '4', text: 'Emergency call + SMS sent via Twilio to your guardian'),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Test SOS Button ────────────────────────────────────────
                if (_guardianNumber.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.send_outlined),
                      label: const Text('Test SOS Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 3,
                      ),
                      onPressed: _testSOS,
                    ),
                  ),

                const SizedBox(height: 16),

                // ── Emergency Number Info ──────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red.shade600),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Emergency calls are placed from +1 (814) 637-3200 via AYUSH SOS. '
                          'Your guardian will receive a voice call + SMS.',
                          style: TextStyle(color: Colors.red.shade800, fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Helper Widgets ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    if (subtitle.isNotEmpty)
                      Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      onChanged: onChanged,
      activeColor: activeColor,
    );
  }
}

class _InfoStep extends StatelessWidget {
  final String step;
  final String text;

  const _InfoStep({required this.step, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24, height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
            child: Text(step, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87))),
        ],
      ),
    );
  }
}
