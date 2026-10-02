# onayliyorum_flutter_app_widget

Onaylıyorum anket widget'larını Flutter uygulamanızda gösteren SDK. Panelden oluşturduğunuz anket widget'ının anahtarını (`wgt_...`) verirsiniz; SDK anketi uygulamanın içinde açar ve tamamlandığında size haber verir.

Anket içeriği panelden yönetilir: soruları, başlangıç ve tamamlanma ekranını değiştirdiğinizde uygulamayı güncellemeniz gerekmez.

## Kurulum

`pubspec.yaml` dosyanıza ekleyin:

```yaml
dependencies:
  onayliyorum_flutter_app_widget:
    git:
      url: https://github.com/iMestav/onayliyorum_flutter_widget.git
      ref: v0.1.2
```

`ref` ile belirli bir sürüme sabitlenirsiniz; yeni sürüme geçmek için etiketi değiştirip `flutter pub get` çalıştırın. Sürüm notları için [CHANGELOG.md](CHANGELOG.md) dosyasına bakın.

**Android:** `android/app/src/main/AndroidManifest.xml` dosyasında internet izni olmalı:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

**iOS:** Ek ayar gerekmez.

## Widget anahtarı

Onaylıyorum panelinde **Paylaş ve Tanıt → Mobil Widget'lar** sayfasından bir widget oluşturun ve anketinizi seçin. "Kurulum kodu" penceresinde `wgt_...` anahtarınız kodlara yerleştirilmiş olarak gelir. Aynı sayfada anketin müşterilerin önüne kaç kez geldiğini ve kaç kez cevaplandığını görürsünüz.

## Kullanım

```dart
import 'package:onayliyorum_flutter_app_widget/onayliyorum_flutter_app_widget.dart';
```

### Anketi pencerede açma

Anket alttan açılan bir pencerede gösterilir. Gönderildikten sonra tamamlanma ekranı kısa bir süre görünür ve pencere kendiliğinden kapanır.

```dart
final result = await Onayliyorum.showSurvey(
  context,
  widgetKey: 'wgt_abcDEF1234',
);

if (result == OnayliyorumSurveyResult.completed) {
  // Anket gönderildi.
}
```

| Parametre               | Varsayılan | Açıklama                                                                                                         |
| ----------------------- | ----------- | ------------------------------------------------------------------------------------------------------------------ |
| `widgetKey`           | zorunlu     | Anket widget'ının anahtarı.                                                                                     |
| `user`                | –          | Verilirse cevap müşteriye bağlanır. Aşağıda "Müşteri bilgisi" bölümüne bakın.                         |
| `heightFactor`        | `0.75`    | Pencerenin ekran yüksekliğine oranı (0.3 – 1.0).                                                               |
| `closeAfterCompleted` | 3 saniye    | Gönderimden sonra pencerenin açık kalacağı süre.`null` verilirse kullanıcı kapatana kadar açık kalır. |
| `trackImpression`     | `true`    | Paneldeki gösterim sayacını artırır.                                                                          |
| `onCompleted`         | –          | Anket gönderildiği anda çağrılır (pencere kapanmadan önce).                                                 |
| `onError`             | –          | Widget ya da anket yüklenemediğinde çağrılır.                                                                |

Dönen değer (`OnayliyorumSurveyResult`):

| Değer              | Anlamı                                                                                                                                                 |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `completed`       | Anket gönderildi.                                                                                                                                      |
| `dismissed`       | Kullanıcı anketi göndermeden kapattı.                                                                                                               |
| `alreadyAnswered` | Müşteri bu işlem için anketi daha önce cevaplamış; pencere açılmadı. Yalnızca`user` ile birlikte `transaction` verildiğinde dönebilir. |

### Anketi sayfanın içine gömme

```dart
Scaffold(
  appBar: AppBar(title: const Text('Anket')),
  body: OnayliyorumSurveyView(
    widgetKey: 'wgt_abcDEF1234',
    onCompleted: () {
      // Örn. sayfayı kapatın ya da teşekkür mesajı gösterin.
    },
  ),
)
```

Görünüm bulunduğu alanı doldurur ve anket kendi içinde kayar. Kaydırılabilir bir sayfanın (`ListView`, `SingleChildScrollView`) içine koyacaksanız `autoHeight: true` verin; görünüm anketin içerik yüksekliğini alır.

| Parametre             | Varsayılan | Açıklama                                                                                                                                                                |
| --------------------- | ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `widgetKey`         | zorunlu     | Anket widget'ının anahtarı.                                                                                                                                            |
| `user`              | –          | Verilirse cevap müşteriye bağlanır.                                                                                                                                   |
| `autoHeight`        | `false`   | Yüksekliği anketin içeriğine göre ayarlar.                                                                                                                           |
| `trackImpression`   | `true`    | Paneldeki gösterim sayacını artırır.                                                                                                                                 |
| `onCompleted`       | –          | Anket gönderildiğinde bir kez çağrılır.                                                                                                                             |
| `onAlreadyAnswered` | –          | Müşteri bu işlem için anketi daha önce cevapladıysa çağrılır; anket yerine kısa bir mesaj gösterilir. Yalnızca`transaction` verildiğinde çağrılabilir. |
| `onError`           | –          | Widget ya da anket yüklenemediğinde çağrılır.                                                                                                                       |

Bu görünüm anket bitince kendiliğinden kapanmaz; ne yapılacağına `onCompleted` içinde siz karar verirsiniz.

### Müşteri bilgisi

`user` vermezseniz cevap anonim kaydedilir. Verirseniz müşteri Onaylıyorum'da bulunur (yoksa oluşturulur), anketin bağlı olduğu gruba eklenir ve cevap o müşteriye bağlanır.

`transaction` isteğe bağlıdır:

- **Verilirse** (satış sonrası): cevap o işleme de bağlanır ve aynı müşteri aynı işlem için anketi yalnızca bir kez cevaplayabilir.
- **Verilmezse** (satış dışı gösterimler): cevap yalnızca müşteriye bağlanır ve anket her açılışta cevaplanabilir; ne sıklıkla gösterileceğine uygulamanız karar verir.

Satış sonrası, işlemle:

```dart
Onayliyorum.showSurvey(
  context,
  widgetKey: 'wgt_abcDEF1234',
  user: OnayliyorumUser(
    externalId: '6cfb7fdc-8da2-ef11-9426-005056809fb2',
    name: 'Örnek Müşteri',
    phoneNumber: '905xxxxxxxxx',
    email: 'musteri@example.com',
    transaction: OnayliyorumTransaction(
      invoiceNo: '97175531',
      invoiceCrmNo: '0fba8709-d0a3-f111-8f53-00505601c9f9',
      transactionDate: DateTime(2026, 8, 29, 18, 12, 10),
      orderChannel: '1',
      subchannel: '2',
    ),
  ),
);
```

Satış dışı, işlemsiz:

```dart
Onayliyorum.showSurvey(
  context,
  widgetKey: 'wgt_abcDEF1234',
  user: const OnayliyorumUser(
    externalId: '6cfb7fdc-8da2-ef11-9426-005056809fb2',
    name: 'Örnek Müşteri',
  ),
);
```

Müşteri eşleştirmesi: önce `externalId`, bulunamazsa telefon numarası ile aranır; yoksa yeni müşteri oluşturulur. Mevcut müşterinin adı değiştirilmez, yalnızca boş olan telefon ve e-posta alanları doldurulur.

`externalId` ve `name` zorunludur. `transaction` verilirse içinde `invoiceCrmNo` ya da `invoiceNo` ile `transactionDate` birlikte olmalıdır. Alanlar Partner API'deki karşılıklarıyla gönderilir:

| SDK                    | Partner API            |
| ---------------------- | ---------------------- |
| `externalId`         | `external_id`        |
| `phoneNumber`        | `phone_number`       |
| `invoiceNo`          | `fatura_no`          |
| `invoiceCrmNo`       | `fatura_crm_no`      |
| `transactionDate`    | `transaction_date`   |
| `channel`            | `channel`            |
| `branchName`         | `branch_name`        |
| `branchFullName`     | `branch_fullName`    |
| `orderLocation`      | `orderlocation`      |
| `orderLocationId`    | `orderlocationid`    |
| `orderChannel`       | `orderchannel`       |
| `subchannel`         | `subchannel`         |
| `billingType`        | `faturalama_turu`    |
| `homeDelivery`       | `eve_teslim`         |
| `transactionChannel` | `transactionchannel` |

### Ön yükleme

Anketin daha hızlı açılması için widget verisini önceden çekebilirsiniz (örneğin uygulama açılışında):

```dart
Onayliyorum.preload('wgt_abcDEF1234');
```

## Hatalar

Yükleme başarısız olursa görünümde bir mesaj ve "Tekrar dene" butonu gösterilir; ayrıca `onError` bir `OnayliyorumException` ile çağrılır.

| `code`        | Anlamı                                             |
| --------------- | --------------------------------------------------- |
| `invalidKey`  | Anahtar`wgt_` + 10 karakter biçiminde değil.    |
| `notFound`    | Widget yok ya da panelden kapatılmış.            |
| `notAllowed`  | Widget'ta alan adı kısıtı var.                  |
| `notSurvey`   | Anahtar bir anket widget'ına ait değil.           |
| `invalidUser` | Kullanıcı ya da işlem bilgisi eksik / geçersiz. |
| `rateLimited` | Kısa sürede çok fazla istek gönderildi.         |
| `network`     | İnternet yok ya da sunucuya ulaşılamadı.        |
| `server`      | Sunucu beklenmeyen bir yanıt döndü.              |

## Bilinmesi gerekenler

- `user` verilmeyen cevaplar anonim kaydedilir. Cevaplar panelde "Mobil widget" kaynağıyla görünür ve bu kaynağa göre filtrelenebilir.
- `user` ile açılan her anket panelde bir gönderim olarak sayılır. `transaction` ile açılan işlemler için ayrıca SMS ya da e-posta gönderilmez; aynı işlem için SMS ya da e-posta üzerinden verilmiş cevap da "daha önce cevaplanmış" sayılır.
- Anonim cevaplarda aynı IP adresinden saatte en fazla 10 cevap kabul edilir. `user` ile gönderilen cevaplar bu sınıra tabi değildir.
- Anketteki dış bağlantılar (KVKK, kampanya görseli vb.) cihazın tarayıcısında açılır.
- Panelde widget'ı kapatır ya da anketi değiştirirseniz, uygulamaya en geç 1 dakika içinde yansır.
