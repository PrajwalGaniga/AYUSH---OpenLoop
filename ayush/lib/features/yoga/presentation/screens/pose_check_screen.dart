import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:permission_handler/permission_handler.dart';

class PoseCheckScreen extends StatefulWidget {
  final String asanaId;
  const PoseCheckScreen({required this.asanaId, super.key});

  @override
  State<PoseCheckScreen> createState() => _PoseCheckScreenState();
}

class _PoseCheckScreenState extends State<PoseCheckScreen> {
  WebViewController? _controller;

  @override
  void initState() {
    super.initState();
    _initWebViewWithPermissions();
  }

  Future<void> _initWebViewWithPermissions() async {
    // 1. Request OS level permissions
    await [Permission.camera, Permission.microphone].request();

    // 2. Initialize WebView
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..loadRequest(Uri.parse("http://10.0.2.2:8000/yoga/live/${widget.asanaId}"));

    // 3. Grant WebView specific permissions
    if (controller.platform is AndroidWebViewController) {
      (controller.platform as AndroidWebViewController)
          .setOnPlatformPermissionRequest((request) {
        request.grant();
      });
    }

    setState(() {
      _controller = controller;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _controller != null 
          ? WebViewWidget(controller: _controller!) 
          : const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}
