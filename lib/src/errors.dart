/// Widget yüklenirken oluşabilecek hata türleri.
enum OnayliyorumErrorCode {
  /// Key `wgt_` + 10 karakter biçiminde değil.
  invalidKey,

  /// Widget yok ya da panelden kapatılmış.
  notFound,

  /// Widget bu uygulamada kullanılamıyor (alan adı kısıtı).
  notAllowed,

  /// Key bir anket widget'ına ait değil.
  notSurvey,

  /// Kullanıcı ya da işlem bilgisi eksik / geçersiz.
  invalidUser,

  /// Kısa sürede çok fazla istek gönderildi.
  rateLimited,

  /// İnternet yok ya da sunucuya ulaşılamadı.
  network,

  /// Sunucu beklenmeyen bir yanıt döndü.
  server,
}

class OnayliyorumException implements Exception {
  const OnayliyorumException(this.code, this.message);

  final OnayliyorumErrorCode code;
  final String message;

  @override
  String toString() => 'OnayliyorumException(${code.name}): $message';
}
