import 'dart:convert';

/// Anket sayfasının SDK'ya mesaj gönderdiği JavaScript kanalının adı.
const String surveyChannelName = 'OnayliyorumFlutter';

const String _messageSource = 'onayliyorum-survey';

/// Anket sayfasından gelen mesaj: `completed` ya da `resize` (yükseklik ile).
class SurveyMessage {
  const SurveyMessage(this.type, {this.height});

  final String type;
  final double? height;
}

/// Kanaldan gelen ham metni çözer; tanınmayan ya da bozuk mesajlarda null döner.
SurveyMessage? parseSurveyMessage(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map || decoded['source'] != _messageSource) return null;
    final type = decoded['type'];
    if (type == 'completed') return const SurveyMessage('completed');
    final height = decoded['height'];
    if (type == 'resize' && height is num && height > 0) {
      return SurveyMessage('resize', height: height.toDouble());
    }
  } catch (_) {
    // ignore
  }
  return null;
}
