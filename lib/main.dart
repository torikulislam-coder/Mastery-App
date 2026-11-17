import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

const kHomeUrl = 'https://mastery.com.bd/';
const kInternalHost = 'mastery.com.bd';
const kOrange = Color(0xFFFF6124);
const kExternalHosts = <String>[
  'facebook.com', 'fb.com', 'fb.me', 'instagram.com', 'youtube.com',
  'youtu.be', 'linkedin.com', 'wa.me', 'whatsapp.com', 't.me',
  'twitter.com', 'x.com', 'tiktok.com', 'play.google.com', 'zoom.us',
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
  Widget build(BuildContext context) => MaterialApp(
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

class WebShell extends StatefulWidget {
  const WebShell({super.key});
  @override
  State<WebShell> createState() => _WebShellState();
}

class _WebShellState extends State<WebShell> {
  InAppWebViewController? controller;
  late final PullToRefreshController refresh;
  double progress = 0;
  bool showSplash = true;
  bool splashTimeDone = false;
  bool firstLoadDone = false;
  bool offline = false;
  DateTime? lastBackPress;

  @override
  void initState() {
    super.initState();
    refresh = PullToRefreshController(
      settings: PullToRefreshSettings(color: kOrange),
      onRefresh: () async => controller?.reload(),
    );
    Timer(const Duration(milliseconds: 1500), () {
      splashTimeDone = true;
      maybeHideSplash();
    });
    Timer(const Duration(seconds: 8), () {
      splashTimeDone = true;
      firstLoadDone = true;
      maybeHideSplash();
    });
  }

  void maybeHideSplash() {
    if (!mounted) return;
    if (splashTimeDone && (firstLoadDone || offline) && showSplash) {
      setState(() => showSplash = false);
    }
  }

  bool isExternalHost(String host) {
    final h = host.toLowerCase();
    return kExternalHosts.any((d) => h == d || h.endsWith('.$d'));
  }

  Future<void> openExternal(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> handleBack() async {
    final c = controller;
    if (c != null && await c.canGoBack()) {
      await c.goBack();
      return;
    }
    final now = DateTime.now();
    if (lastBackPress == null ||
        now.difference(lastBackPress!) > const Duration(seconds: 2)) {
      lastBackPress = now;
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

  void retry() {
    setState(() {
      offline = false;
      progress = 0;
    });
    controller?.reload();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) handleBack();
    },
    child: Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(kHomeUrl)),
              pullToRefreshController: refresh,
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
              onWebViewCreated: (c) => controller = c,
              onLoadStart: (c, url) {
                if (mounted) setState(() => progress = 0.05);
              },
              onProgressChanged: (c, p) {
                if (!mounted) return;
                setState(() => progress = p / 100);
                if (p == 100) refresh.endRefreshing();
              },
              onLoadStop: (c, url) {
                refresh.endRefreshing();
                if (!offline) {
                  firstLoadDone = true;
                  maybeHideSplash();
                }
              },
              onReceivedError: (c, request, error) {
                refresh.endRefreshing();
                if (request.isForMainFrame ?? false) {
                  if (!mounted) return;
                  setState(() => offline = true);
                  maybeHideSplash();
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
                  if (isExternalHost(uri.host)) {
                    await openExternal(uri.toString());
                    return NavigationActionPolicy.CANCEL;
                  }
                  return NavigationActionPolicy.ALLOW;
                }
                if (['about', 'blob', 'data', 'javascript', 'file'].contains(scheme)) {
                  return NavigationActionPolicy.ALLOW;
                }
                await openExternal(uri.toString());
                return NavigationActionPolicy.CANCEL;
              },
              onDownloadStartRequest: (c, req) async {
                await openExternal(req.url.toString());
              },
              onPermissionRequest: (c, request) async => PermissionResponse(
                resources: request.resources,
                action: PermissionResponseAction.GRANT,
              ),
            ),
            if (progress > 0 && progress < 1)
              Positioned(
                top: 0, left: 0, right: 0,
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 3,
                  color: kOrange,
                  backgroundColor: Colors.transparent,
                ),
              ),
            if (offline) OfflineView(onRetry: retry),
            if (showSplash) const SplashView(),
          ],
        ),
      ),
    ),
  );
}

class SplashView extends StatelessWidget {
  const SplashView({super.key});
  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: Container(
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/logo.png', width: 230),
          const SizedBox(height: 32),
          const SizedBox(
            width: 26, height: 26,
            child: CircularProgressIndicator(strokeWidth: 3, color: kOrange),
          ),
        ],
      ),
    ),
  );
}

class OfflineView extends StatelessWidget {
  const OfflineView({super.key, required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Positioned.fill(
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
          const Text('ইন্টারনেট সংযোগ নেই',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
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
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('আবার চেষ্টা করুন'),
          ),
        ],
      ),
    ),
  );
}
