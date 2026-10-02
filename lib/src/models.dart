/// GET /api/public/widgets/:key yanıtı (web widget ile aynı veri).
class OnayliyorumWidgetData {
  const OnayliyorumWidgetData({
    required this.key,
    required this.kind,
    required this.design,
    required this.theme,
    required this.options,
    required this.firm,
    required this.survey,
  });

  factory OnayliyorumWidgetData.fromJson(Map<String, dynamic> json) {
    final survey = json['survey'];
    return OnayliyorumWidgetData(
      key: json['key'] as String,
      kind: json['kind'] as String,
      design: json['design'] as String? ?? '',
      theme: json['theme'] as String? ?? 'light',
      options: Map<String, dynamic>.from(json['options'] as Map? ?? const {}),
      firm: OnayliyorumFirm.fromJson(Map<String, dynamic>.from(json['firm'] as Map? ?? const {})),
      survey: survey is Map ? OnayliyorumSurvey.fromJson(Map<String, dynamic>.from(survey)) : null,
    );
  }

  final String key;

  /// `SURVEY` ya da `RATING`.
  final String kind;
  final String design;

  /// `light` ya da `dark`.
  final String theme;
  final Map<String, dynamic> options;
  final OnayliyorumFirm firm;

  /// Yalnızca anket widget'larında doludur.
  final OnayliyorumSurvey? survey;

  bool get isSurvey => kind == 'SURVEY' && survey != null;
}

class OnayliyorumFirm {
  const OnayliyorumFirm({required this.name, this.logoUrl});

  factory OnayliyorumFirm.fromJson(Map<String, dynamic> json) => OnayliyorumFirm(
        name: json['name'] as String? ?? '',
        logoUrl: json['logoUrl'] as String?,
      );

  final String name;
  final String? logoUrl;
}

class OnayliyorumSurvey {
  const OnayliyorumSurvey({required this.id, required this.title, required this.embedUrl});

  factory OnayliyorumSurvey.fromJson(Map<String, dynamic> json) => OnayliyorumSurvey(
        id: (json['id'] as num).toInt(),
        title: json['title'] as String? ?? '',
        embedUrl: Uri.parse(json['embedUrl'] as String),
      );

  final int id;
  final String title;

  /// Anket sayfasının widget modundaki adresi; WebView'da açılır.
  final Uri embedUrl;
}
