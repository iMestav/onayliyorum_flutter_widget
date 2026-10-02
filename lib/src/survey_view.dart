import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'api.dart';
import 'bridge.dart';
import 'errors.dart';
import 'user.dart';

/// Anket widget'ını bulunduğu alanın içinde gösterir.
///
/// Key ile widget verisi çekilir, ardından anket sayfası WebView'da açılır.
class OnayliyorumSurveyView extends StatefulWidget {
  const OnayliyorumSurveyView({
    super.key,
    required this.widgetKey,
    this.user,
    this.autoHeight = false,
    this.trackImpression = true,
    this.api,
    this.onCompleted,
    this.onAlreadyAnswered,
    this.onError,
  });

  final String widgetKey;

  /// Verilirse cevap bu müşteriye ve işleme bağlanır; verilmezse anonim kaydedilir.
  final OnayliyorumUser? user;

  /// true ise görünüm anketin içerik yüksekliğini alır (kaydırılabilir bir sayfanın içine gömmek için).
  /// false ise bulunduğu alanı doldurur ve anket kendi içinde kayar.
  final bool autoHeight;

  /// Anket gösterildiğinde paneldeki gösterim sayacı artırılır.
  final bool trackImpression;

  /// Anket gönderildiğinde bir kez çağrılır.
  final VoidCallback? onCompleted;

  /// [user] bu işlem için anketi daha önce cevapladıysa çağrılır; anket açılmaz.
  final VoidCallback? onAlreadyAnswered;

  /// Verilmezse SDK'nın ortak istemcisi kullanılır.
  final OnayliyorumApi? api;

  /// Widget ya da anket sayfası yüklenemediğinde çağrılır.
  final ValueChanged<OnayliyorumException>? onError;

  @override
  State<OnayliyorumSurveyView> createState() => _OnayliyorumSurveyViewState();
}

class _OnayliyorumSurveyViewState extends State<OnayliyorumSurveyView> {
  WebViewController? _controller;
  OnayliyorumException? _error;
  bool _pageLoading = true;
  bool _completed = false;
  bool _alreadyAnswered = false;
  bool _impressionSent = false;
  double? _contentHeight;
  // Yeniden denemede eski isteğin sonucu yok sayılır.
  int _attempt = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(OnayliyorumSurveyView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.widgetKey != widget.widgetKey) {
      _impressionSent = false;
      _load();
    }
  }

  Future<void> _load() async {
    final attempt = ++_attempt;
    setState(() {
      _controller = null;
      _error = null;
      _pageLoading = true;
      _completed = false;
      _alreadyAnswered = false;
      _contentHeight = null;
    });
    try {
      final api = widget.api ?? OnayliyorumApi.instance;
      final data = await api.fetchSurveyWidget(widget.widgetKey);
      if (!mounted || attempt != _attempt) return;
      var embedUrl = data.survey!.embedUrl;
      final user = widget.user;
      if (user != null) {
        final session = await api.createSession(data.key, user);
        if (!mounted || attempt != _attempt) return;
        if (session.alreadyAnswered) {
          setState(() => _alreadyAnswered = true);
          widget.onAlreadyAnswered?.call();
          return;
        }
        embedUrl = embedUrl.replace(
          queryParameters: {...embedUrl.queryParameters, 'referanceNumber': session.referenceNumber},
        );
      }
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..addJavaScriptChannel(surveyChannelName, onMessageReceived: (message) => _onMessage(message.message, attempt))
        ..setNavigationDelegate(NavigationDelegate(
          onNavigationRequest: (request) {
            final target = Uri.tryParse(request.url);
            if (!request.isMainFrame || target == null || isSurveyPage(target, embedUrl)) {
              return NavigationDecision.navigate;
            }
            // Anket dışındaki bağlantılar (KVKK, kampanya görseli vb.) cihazın tarayıcısında açılır.
            launchUrl(target, mode: LaunchMode.externalApplication).catchError((_) => false);
            return NavigationDecision.prevent;
          },
          onPageFinished: (_) {
            if (mounted && attempt == _attempt) setState(() => _pageLoading = false);
          },
          onWebResourceError: (error) {
            // Alt kaynak (görsel, font vb.) hataları anketi engellemez.
            if (error.isForMainFrame == false) return;
            _fail(const OnayliyorumException(OnayliyorumErrorCode.network, 'Anket yüklenemedi. İnternet bağlantınızı kontrol edin.'), attempt);
          },
        ))
        ..loadRequest(embedUrl);
      setState(() => _controller = controller);
      if (widget.trackImpression && !_impressionSent) {
        _impressionSent = true;
        api.sendEvent(data.key, OnayliyorumEvent.impression);
      }
    } on OnayliyorumException catch (error) {
      _fail(error, attempt);
    }
  }

  void _onMessage(String raw, int attempt) {
    if (!mounted || attempt != _attempt) return;
    final message = parseSurveyMessage(raw);
    if (message == null) return;
    if (message.type == 'completed') {
      if (_completed) return;
      _completed = true;
      (widget.api ?? OnayliyorumApi.instance).clearSessions();
      widget.onCompleted?.call();
    } else if (widget.autoHeight && message.height != _contentHeight) {
      setState(() => _contentHeight = message.height);
    }
  }

  void _fail(OnayliyorumException error, int attempt) {
    if (!mounted || attempt != _attempt) return;
    setState(() {
      _controller = null;
      _error = error;
    });
    widget.onError?.call(error);
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    if (error != null) return _ErrorView(message: error.message, onRetry: _load);
    if (_alreadyAnswered) {
      return const ColoredBox(
        color: Colors.white,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Bu anketi daha önce yanıtladınız. Teşekkür ederiz.', textAlign: TextAlign.center),
          ),
        ),
      );
    }

    final controller = _controller;
    final view = _buildView(controller);
    if (!widget.autoHeight) return view;
    return SizedBox(height: (_contentHeight ?? 320).clamp(200, 4000).toDouble(), child: view);
  }

  Widget _buildView(WebViewController? controller) {
    return ColoredBox(
      color: Colors.white,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (controller != null) WebViewWidget(controller: controller),
          if (controller == null || _pageLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

/// [target], anket sayfasının kendisi mi (aynı site ve aynı sayfa)? Değilse dış bağlantıdır.
@visibleForTesting
bool isSurveyPage(Uri target, Uri embedUrl) {
  if (target.scheme == 'about') return true;
  return target.scheme == embedUrl.scheme && target.host == embedUrl.host && target.path == embedUrl.path;
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onRetry, child: const Text('Tekrar dene')),
            ],
          ),
        ),
      ),
    );
  }
}
