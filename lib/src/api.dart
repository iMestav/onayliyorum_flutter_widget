import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';
import 'errors.dart';
import 'models.dart';
import 'user.dart';

final RegExp _keyPattern = RegExp(r'^wgt_[A-Za-z0-9]{10}$');

/// Paneldeki widget istatistiklerine yansıyan olaylar.
enum OnayliyorumEvent { impression, click, dismiss }

class _CacheEntry<T> {
  _CacheEntry(this.data, this.expiresAt);
  final T data;
  final DateTime expiresAt;
}

/// Widget verisini key ile backend'den çeker.
class OnayliyorumApi {
  OnayliyorumApi({http.Client? client, String baseUrl = onayliyorumApiBase})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl;

  /// SDK'nın ortak istemcisi; önbellek tüm widget'lar arasında paylaşılır.
  static final OnayliyorumApi instance = OnayliyorumApi();

  final http.Client _client;
  final String _baseUrl;

  // Backend yapılandırmayı 1 dk önbellekte tutar; aynı süre burada da geçerlidir.
  static const Duration _cacheTtl = Duration(seconds: 60);
  static const Duration _timeout = Duration(seconds: 15);
  final Map<String, _CacheEntry<OnayliyorumWidgetData>> _cache = {};

  // showSurvey'in ön kontrolü ile görünümün isteği art arda gelir; ikincisi önbellekten döner.
  static const Duration _sessionTtl = Duration(seconds: 10);
  final Map<String, _CacheEntry<OnayliyorumSession>> _sessions = {};

  Future<OnayliyorumWidgetData> fetchWidget(String key) async {
    final trimmed = key.trim();
    if (!_keyPattern.hasMatch(trimmed)) {
      throw const OnayliyorumException(OnayliyorumErrorCode.invalidKey, 'Geçersiz widget anahtarı.');
    }
    final cached = _cache[trimmed];
    if (cached != null && cached.expiresAt.isAfter(DateTime.now())) return cached.data;

    final http.Response response;
    try {
      response = await _client
          .get(Uri.parse('$_baseUrl/api/public/widgets/$trimmed'), headers: const {'Accept': 'application/json'})
          .timeout(_timeout);
    } catch (_) {
      throw const OnayliyorumException(OnayliyorumErrorCode.network, 'Sunucuya ulaşılamadı. İnternet bağlantınızı kontrol edin.');
    }

    switch (response.statusCode) {
      case 200:
        break;
      case 400:
        throw const OnayliyorumException(OnayliyorumErrorCode.invalidKey, 'Geçersiz widget anahtarı.');
      case 403:
        throw const OnayliyorumException(OnayliyorumErrorCode.notAllowed, 'Bu widget bu uygulamada kullanılamaz.');
      case 404:
        throw const OnayliyorumException(OnayliyorumErrorCode.notFound, 'Widget bulunamadı veya kapatılmış.');
      default:
        throw OnayliyorumException(OnayliyorumErrorCode.server, 'Widget yüklenemedi (HTTP ${response.statusCode}).');
    }

    final OnayliyorumWidgetData data;
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      data = OnayliyorumWidgetData.fromJson(Map<String, dynamic>.from(body['data'] as Map));
    } catch (_) {
      throw const OnayliyorumException(OnayliyorumErrorCode.server, 'Sunucudan beklenmeyen bir yanıt alındı.');
    }
    _cache[trimmed] = _CacheEntry(data, DateTime.now().add(_cacheTtl));
    return data;
  }

  /// [fetchWidget] ile aynı; key bir anket widget'ı değilse hata verir.
  Future<OnayliyorumWidgetData> fetchSurveyWidget(String key) async {
    final data = await fetchWidget(key);
    if (!data.isSurvey) {
      throw const OnayliyorumException(OnayliyorumErrorCode.notSurvey, 'Bu anahtar bir anket widget\'ına ait değil.');
    }
    return data;
  }

  /// Kullanıcı ve işlem bilgisiyle anket oturumu açar; cevap dönen referansla müşteriye bağlanır.
  Future<OnayliyorumSession> createSession(String key, OnayliyorumUser user) async {
    final trimmed = key.trim();
    if (!_keyPattern.hasMatch(trimmed)) {
      throw const OnayliyorumException(OnayliyorumErrorCode.invalidKey, 'Geçersiz widget anahtarı.');
    }
    final body = jsonEncode({'user': user.toJson()});
    final cacheKey = '$trimmed|$body';
    final cached = _sessions[cacheKey];
    if (cached != null && cached.expiresAt.isAfter(DateTime.now())) return cached.data;

    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$_baseUrl/api/public/widgets/$trimmed/sessions'),
            headers: const {'Accept': 'application/json', 'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(_timeout);
    } catch (_) {
      throw const OnayliyorumException(OnayliyorumErrorCode.network, 'Sunucuya ulaşılamadı. İnternet bağlantınızı kontrol edin.');
    }

    switch (response.statusCode) {
      case 200:
        break;
      case 400:
        throw const OnayliyorumException(OnayliyorumErrorCode.invalidKey, 'Geçersiz widget anahtarı.');
      case 404:
        throw const OnayliyorumException(OnayliyorumErrorCode.notFound, 'Widget bulunamadı veya kapatılmış.');
      case 422:
        throw OnayliyorumException(OnayliyorumErrorCode.invalidUser, _serverMessage(response) ?? 'Kullanıcı bilgisi geçersiz.');
      case 429:
        throw const OnayliyorumException(OnayliyorumErrorCode.rateLimited, 'Çok fazla istek gönderildi. Lütfen daha sonra tekrar deneyin.');
      default:
        throw OnayliyorumException(OnayliyorumErrorCode.server, 'Anket açılamadı (HTTP ${response.statusCode}).');
    }

    final OnayliyorumSession session;
    try {
      final data = (jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>)['data'] as Map;
      session = OnayliyorumSession(
        referenceNumber: data['referanceNumber'] as String,
        alreadyAnswered: data['alreadyAnswered'] == true,
      );
    } catch (_) {
      throw const OnayliyorumException(OnayliyorumErrorCode.server, 'Sunucudan beklenmeyen bir yanıt alındı.');
    }
    _sessions[cacheKey] = _CacheEntry(session, DateTime.now().add(_sessionTtl));
    return session;
  }

  /// Anket gönderildikten sonra çağrılır; aynı kullanıcı için bir sonraki oturum sunucudan sorulur.
  void clearSessions() => _sessions.clear();

  String? _serverMessage(http.Response response) {
    try {
      final data = (jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>)['data'];
      return data is String && data.isNotEmpty ? data : null;
    } catch (_) {
      return null;
    }
  }

  /// Gösterim / tıklama sayacını artırır (web widget ile aynı endpoint). Hatalar yok sayılır.
  Future<void> sendEvent(String key, OnayliyorumEvent event) async {
    final trimmed = key.trim();
    if (!_keyPattern.hasMatch(trimmed)) return;
    try {
      await _client.post(Uri.parse('$_baseUrl/api/public/widgets/$trimmed/events/${event.name}')).timeout(_timeout);
    } catch (_) {
      // Sayaç gönderilemese de anket akışı etkilenmez.
    }
  }

  void close() => _client.close();
}
