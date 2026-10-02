import 'dart:async';

import 'package:flutter/material.dart';

import 'api.dart';
import 'errors.dart';
import 'survey_view.dart';
import 'user.dart';

/// [Onayliyorum.showSurvey] sonucu.
enum OnayliyorumSurveyResult {
  /// Anket gönderildi.
  completed,

  /// Kullanıcı anketi göndermeden kapattı.
  dismissed,

  /// Müşteri bu işlem için anketi daha önce cevaplamış; pencere açılmadı.
  alreadyAnswered,
}

/// SDK'nın giriş noktası.
class Onayliyorum {
  const Onayliyorum._();

  /// Widget verisini önceden çeker; anket açılırken beklemeyi kısaltır. Hatalar yok sayılır.
  static Future<void> preload(String widgetKey) async {
    try {
      await OnayliyorumApi.instance.fetchSurveyWidget(widgetKey);
    } on OnayliyorumException {
      // Anket açılırken yeniden denenir ve hata orada gösterilir.
    }
  }

  /// Anketi alttan açılan bir pencerede gösterir.
  ///
  /// [user] verilirse cevap o müşteriye ve işleme bağlanır; verilmezse anonim kaydedilir.
  /// Müşteri aynı işlem için anketi daha önce cevapladıysa pencere açılmaz.
  /// Gönderimden sonra tamamlanma ekranı [closeAfterCompleted] kadar gösterilir ve pencere
  /// kendiliğinden kapanır; `null` verilirse kullanıcı kapatana kadar açık kalır.
  /// [heightFactor] pencerenin ekran yüksekliğine oranıdır (0.3 – 1.0).
  static Future<OnayliyorumSurveyResult> showSurvey(
    BuildContext context, {
    required String widgetKey,
    OnayliyorumUser? user,
    Duration? closeAfterCompleted = const Duration(seconds: 3),
    double heightFactor = 0.75,
    bool trackImpression = true,
    VoidCallback? onCompleted,
    ValueChanged<OnayliyorumException>? onError,
    OnayliyorumApi? api,
  }) async {
    if (user != null) {
      try {
        final session = await (api ?? OnayliyorumApi.instance).createSession(widgetKey, user);
        if (session.alreadyAnswered) return OnayliyorumSurveyResult.alreadyAnswered;
      } on OnayliyorumException {
        // Hata pencerenin içinde, "Tekrar dene" ile birlikte gösterilir.
      }
      if (!context.mounted) return OnayliyorumSurveyResult.dismissed;
    }
    final completed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      // Sürükleme hareketi anketin kendi kaydırmasıyla çakışmasın.
      enableDrag: false,
      useSafeArea: true,
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _SurveySheet(
        widgetKey: widgetKey,
        user: user,
        closeAfterCompleted: closeAfterCompleted,
        heightFactor: heightFactor.clamp(0.3, 1.0).toDouble(),
        trackImpression: trackImpression,
        onCompleted: onCompleted,
        onError: onError,
        api: api,
      ),
    );
    return completed == true ? OnayliyorumSurveyResult.completed : OnayliyorumSurveyResult.dismissed;
  }
}

class _SurveySheet extends StatefulWidget {
  const _SurveySheet({
    required this.widgetKey,
    required this.closeAfterCompleted,
    this.user,
    required this.heightFactor,
    required this.trackImpression,
    this.onCompleted,
    this.onError,
    this.api,
  });

  final String widgetKey;
  final OnayliyorumUser? user;
  final Duration? closeAfterCompleted;
  final double heightFactor;
  final bool trackImpression;
  final VoidCallback? onCompleted;
  final ValueChanged<OnayliyorumException>? onError;
  final OnayliyorumApi? api;

  @override
  State<_SurveySheet> createState() => _SurveySheetState();
}

class _SurveySheetState extends State<_SurveySheet> {
  bool _completed = false;
  Timer? _closeTimer;

  @override
  void dispose() {
    _closeTimer?.cancel();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop(_completed);

  void _onCompleted() {
    _completed = true;
    widget.onCompleted?.call();
    final delay = widget.closeAfterCompleted;
    if (delay == null) return;
    _closeTimer = Timer(delay, () {
      if (mounted) _close();
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Padding(
      // Klavye açıldığında anket klavyenin üstünde kalır.
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SizedBox(
        height: media.size.height * widget.heightFactor,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: _close,
                tooltip: 'Kapat',
                icon: const Icon(Icons.close),
              ),
            ),
            Expanded(
              child: OnayliyorumSurveyView(
                widgetKey: widget.widgetKey,
                user: widget.user,
                api: widget.api,
                trackImpression: widget.trackImpression,
                onCompleted: _onCompleted,
                onError: widget.onError,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
