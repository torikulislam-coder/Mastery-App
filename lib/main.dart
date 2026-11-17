import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

/// ====== শুধু এই জায়গাগুলো বদলালেই চলবে ======
const String kHomeUrl = 'https://mastery.com.bd/';
const String kInternalHost = 'mastery.com.bd';
const Color kOrange = Color(0xFFFF6124);

/// এই সাইটগুলোর লিংকে চাপ দিলে অ্যাপের বাইরে (ঐ অ্যাপে/ব্রাউজারে) খুলবে।
/// বাকি সব লিংক (পেমেন্ট গেটওয়েসহ) অ্যাপের ভেতরেই লোড হবে।
const List<String> kExternalHosts = [
  'facebook.com',
  'fb.com',
  'fb.me',
  'instagram.com',
  'youtube.com',
  'youtu.be',
  'linkedin.com',
  'wa.me',
  'whatsapp.com',
  't.me',
  'twitter.com',
  'x.com',
  'tiktok.com',
  'play.google.com',
  'zoom.us',
  'meet.google.com',
];

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.white,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  runApp(const MasteryApp());
}

class MasteryApp extends StatelessWidget {
  const MasteryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mastery',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: kOrange),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const WebShell(),
    );
  }
}

class WebShell extends StatefulWidget {
  const WebShell({super.key});

  @override
  State<WebShell> createState() => _WebShellState();
}

class _WebShellState extends State<WebShell> {
  InAppWebViewController? _controller;
  late final PullToRefreshController _pullToRefresh;

  double _progress = 0;
  bool _showSplash = true;
  bool _splashTimeDone = false;
  bool _firstLoadDone = false;
  bool _offline = false;
  DateTime? _lastBackPress;

  @override
  void initState() {
    super.initState();
    _pullToRefresh = PullToRefreshController(
      settings: PullToRefreshSettings(color: kOrange),
      onRefresh: () async {
        await _controller?.reload();
      },
    );
    // Splash কমপক্ষে ১.৫ সেকেন্ড দেখাবে
    Timer(const Duration(milliseconds: 1500), () {
      _splashTimeDone = true;
      _maybeHideSplash();
    });
    // নেট খুব স্লো হলেও ৮ সেকেন্ড পরে splash সরে যাবে
    Timer(const Duration(seconds: 8), () {
      _splashTimeDone = true;
      _firstLoadDone = true;
      _maybeHideSplash();
    });
  }

  void _maybeHideSplash() {
    if (!mounted) return;
    if (_splashTimeDone && (_firstLoadDone || _offline) && _showSplash) {
      setState(() => _showSplash = false);
    }
  }

  bool _isExternalHost(String host) {
    final h = host.toLowerCase();
    return kExternalHosts.any((d) => h == d || h.endsWith('.$d'));
  }

  Future<void> _launchExternal(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      // কোনো অ্যাপ না পেলে কিছু করবে না
    }
  }

  Future<void> _handleBack() async {
    final c = _controller;
    if (c != null && await c.canGoBack()) {
      await c.goBack();
      return;
    }
    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('বের হতে আবার Back চাপুন'),
          duration: Duration(seconds: 2),
        ));
      return;
    }
    SystemNavigator.pop();
  }

  void _retry() {
    setState(() {
      _offline = false;
      _progress = 0;
    });
    _controller?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri(kHomeUrl)),
                pullToRefreshController: _pullToRefresh,
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  domStorageEnabled: true,
                  databaseEnabled: true,
                  cacheEnabled: true,
                  thirdPartyCookiesEnabled: true,
                  useShouldOverrideUrlLoading: true,
                  useOnDownloadStart: true,
                  mediaPlaybackRequiresUserGesture: false,
                  allowsInlineMediaPlayback: true,
                  javaScriptCanOpenWindowsAutomatically: true,
                  supportMultipleWindows: false,
                  supportZoom: false,
                  allowFileAccess: true,
                  allowContentAccess: true,
                  transparentBackground: false,
                ),
                onWebViewCreated: (c) => _controller = c,
                onLoadStart: (c, url) {
                  if (mounted) setState(() => _progress = 0.05);
                },
                onProgressChanged: (c, p) {
                  if (!mounted) return;
                  setState(() => _progress = p / 100);
                  if (p == 100) _pullToRefresh.endRefreshing();
                },
                onLoadStop: (c, url) {
                  _pullToRefresh.endRefreshing();
                  if (!_offline) {
                    _firstLoadDone = true;
                    _maybeHideSplash();
                  }
                },
                onReceivedError: (c, request, error) {
                  _pullToRefresh.endRefreshing();
                  if (request.isForMainFrame ?? false) {
                    if (!mounted) return;
                    setState(() => _offline = true);
                    _maybeHideSplash();
                  }
                },
                shouldOverrideUrlLoading: (c, action) async {
                  if (action.isForMainFrame == false) {
                    return NavigationActionPolicy.ALLOW;
                  }
                  final uri = action.request.url;
                  if (uri == null) return NavigationActionPolicy.ALLOW;
                  final scheme = uri.scheme.toLowerCase();

                  if (scheme == 'http' || scheme == 'https') {
                    if (uri.host == kInternalHost ||
                        uri.host.endsWith('.$kInternalHost')) {
                      return NavigationActionPolicy.ALLOW;
                    }
                    if (_isExternalHost(uri.host)) {
                      await _launchExternal(uri.toString());
                      return NavigationActionPolicy.CANCEL;
                    }
                    // পেমেন্ট গেটওয়ে ইত্যাদি অন্য ডোমেইন: অ্যাপের ভেতরেই লোড হবে
                    return NavigationActionPolicy.ALLOW;
                  }

                  if (scheme == 'about' ||
                      scheme == 'blob' ||
                      scheme == 'data' ||
                      scheme == 'javascript' ||
                      scheme == 'file') {
                    return NavigationActionPolicy.ALLOW;
                  }

                  // tel:, mailto:, sms:, whatsapp:, intent: ইত্যাদি
                  await _launchExternal(uri.toString());
                  return NavigationActionPolicy.CANCEL;
                },
                onDownloadStartRequest: (c, req) async {
                  await _launchExternal(req.url.toString());
                },
                onPermissionRequest: (c, request) async {
                  return PermissionResponse(
                    resources: request.resources,
                    action: PermissionResponseAction.GRANT,
                  );
                },
              ),

              // Progress bar
              if (_progress > 0 && _progress < 1)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 3,
                    color: kOrange,
                    backgroundColor: Colors.transparent,
                  ),
                ),

              // Offline / error screen
              if (_offline) _OfflineView(onRetry: _retry),

              // Splash
              if (_showSplash) const _SplashView(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png', width: 230),
            const SizedBox(height: 32),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 3, color: kOrange),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineView extends StatelessWidget {
  const _OfflineView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png', width: 150),
            const SizedBox(height: 36),
            const Icon(Icons.wifi_off_rounded, size: 56, color: kOrange),
            const SizedBox(height: 16),
            const Text(
              'ইন্টারনেট সংযোগ নেই',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'আপনার নেট চালু আছে কিনা দেখে আবার চেষ্টা করুন।',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: kOrange,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('আবার চেষ্টা করুন'),
            ),
          ],
        ),
      ),
    );
  }
}
