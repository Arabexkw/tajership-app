import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../config.dart';
import '../services/push_service.dart';

/// الشاشة الرئيسية: تاجرشِب داخل WebView + الميزات الأصلية
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final WebViewController _web;
  bool _loading = true;
  bool _offline = false;
  String _currentUrl = AppConfig.homeUrl;
  StreamSubscription<String>? _pushSub;
  StreamSubscription<List<ConnectivityResult>>? _netSub;

  @override
  void initState() {
    super.initState();
    _initWeb();
    _watchNetwork();
    // إشعار ضُغط → افتح رابطه داخل التطبيق
    _pushSub = PushService.instance.onOpenUrl.listen((url) {
      _web.loadRequest(Uri.parse(url));
    });
  }

  void _initWeb() {
    // iOS: السماح بتشغيل الفيديو مضمّناً (inline) وتلقائياً بدون مشغّل ملء الشاشة
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }
    _web = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(AppConfig.inkBlack))
      // User-Agent موبايل قياسي + وسم التطبيق (يعرف السيرفر أنه التطبيق الأصلي)
      ..setUserAgent(
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 '
        '(KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1 ${AppConfig.userAgentSuffix}',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (url) {
            setState(() {
              _loading = false;
              _currentUrl = url;
            });
            // إخفاء بانر "أضف للشاشة الرئيسية" داخل التطبيق (إن وُجد)
            _web.runJavaScript(
              "try{var b=document.getElementById('tsIosBanner');if(b)b.remove();"
              "localStorage.setItem('ts_ios_banner_dismissed',String(Date.now()));"
              "var m=document.querySelector('meta[name=viewport]');"
              "if(m&&m.content.indexOf('viewport-fit')<0){m.content=m.content+',viewport-fit=cover';}"
              "}catch(e){}",
            );
          },
          onWebResourceError: (err) {
            // فشل تحميل الصفحة الرئيسية نفسها (لا الموارد الفرعية)
            if (err.isForMainFrame ?? true) {
              setState(() {
                _loading = false;
                _offline = true;
              });
            }
          },
          onNavigationRequest: _decideNavigation,
        ),
      )
      ..loadRequest(Uri.parse(AppConfig.homeUrl));
  }

  /// قرار التنقل: داخل التطبيق أم فتح خارجي؟
  NavigationDecision _decideNavigation(NavigationRequest req) {
    final uri = Uri.tryParse(req.url);
    if (uri == null) return NavigationDecision.navigate;
    final scheme = uri.scheme;
    final host = uri.host.toLowerCase();

    // روابط الأنظمة: هاتف / واتساب / بريد / خرائط → التطبيق المناسب
    if (scheme == 'tel' ||
        scheme == 'mailto' ||
        scheme == 'sms' ||
        scheme == 'whatsapp' ||
        scheme == 'maps' ||
        scheme == 'geo') {
      _openExternal(uri);
      return NavigationDecision.prevent;
    }

    if (scheme != 'http' && scheme != 'https') {
      return NavigationDecision.prevent;
    }

    // نطاقات تاجرشِب وبوابات الدفع → داخل التطبيق
    final internal = AppConfig.internalHosts.any((h) => host == h || host.endsWith('.$h'));
    final payment = AppConfig.paymentHosts.any((h) => host == h || host.endsWith('.$h'));
    if (internal || payment) return NavigationDecision.navigate;

    // واتساب عبر الويب (wa.me / api.whatsapp.com) → تطبيق واتساب
    if (host == 'wa.me' || host.endsWith('whatsapp.com')) {
      _openExternal(uri);
      return NavigationDecision.prevent;
    }

    // أي رابط خارجي آخر (إنستغرام، يوتيوب، مواقع أخرى) → المتصفح/التطبيق الخارجي
    _openExternal(uri);
    return NavigationDecision.prevent;
  }

  Future<void> _openExternal(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // تجاهل: الجهاز لا يملك تطبيقاً للرابط
    }
  }

  void _watchNetwork() {
    _netSub = Connectivity().onConnectivityChanged.listen((results) {
      final hasNet = results.any((r) => r != ConnectivityResult.none);
      if (hasNet && _offline) {
        setState(() => _offline = false);
        _web.reload();
      }
    });
  }

  /// المشاركة الأصلية للصفحة الحالية (منتج/متجر)
  Future<void> _share() async {
    String title = 'تاجرشِب';
    try {
      final t = await _web.getTitle();
      if (t != null && t.trim().isNotEmpty) title = t.trim();
    } catch (_) {}
    // iOS يتطلب موضع الانبثاق (sharePositionOrigin) وإلا يفشل بصمت على iPad/iOS 17+
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null
        ? Rect.fromLTWH(box.size.width - 60, 0, 60, 60)
        : const Rect.fromLTWH(0, 0, 1, 1);
    await Share.share('$title\n$_currentUrl', subject: title, sharePositionOrigin: origin);
  }

  /// زر الرجوع: يرجع داخل WebView قبل الخروج من التطبيق
  Future<bool> _onWillPop() async {
    if (await _web.canGoBack()) {
      _web.goBack();
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _pushSub?.cancel();
    _netSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(AppConfig.inkBlack);
    const amber = Color(AppConfig.amber);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _onWillPop() && context.mounted) Navigator.of(context).maybePop();
      },
      child: Scaffold(
        backgroundColor: ink,
        // شريط علوي رفيع بأزرار أصلية (مشاركة/تحديث/الرئيسية) — يعطي إحساس التطبيق الأصلي
        appBar: AppBar(
          backgroundColor: ink,
          toolbarHeight: 44,
          elevation: 0,
          title: const Text('تاجرشِب',
              style: TextStyle(color: amber, fontWeight: FontWeight.w900, fontSize: 18)),
          leading: IconButton(
            tooltip: 'الرئيسية',
            icon: const Icon(Icons.home_rounded, color: Colors.white70),
            onPressed: () => _web.loadRequest(Uri.parse(AppConfig.homeUrl)),
          ),
          actions: [
            IconButton(
              tooltip: 'مشاركة',
              icon: const Icon(Icons.ios_share_rounded, color: Colors.white70),
              onPressed: _share,
            ),
            IconButton(
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
              onPressed: () => _web.reload(),
            ),
          ],
          bottom: _loading
              ? const PreferredSize(
                  preferredSize: Size.fromHeight(2),
                  child: LinearProgressIndicator(
                    minHeight: 2,
                    color: amber,
                    backgroundColor: Colors.transparent,
                  ),
                )
              : null,
        ),
        body: _offline ? _offlineView(amber) : WebViewWidget(controller: _web),
      ),
    );
  }

  Widget _offlineView(Color amber) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.white38),
            const SizedBox(height: 18),
            const Text('لا يوجد اتصال بالإنترنت',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('تحقق من الشبكة ثم أعد المحاولة',
                style: TextStyle(color: Colors.white54), textAlign: TextAlign.center),
            const SizedBox(height: 22),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: amber,
                foregroundColor: const Color(AppConfig.inkBlack),
              ),
              onPressed: () {
                setState(() => _offline = false);
                _web.reload();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
