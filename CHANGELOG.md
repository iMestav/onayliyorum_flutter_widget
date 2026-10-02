## 0.1.0

* Proje iskeleti.
* Widget verisini key ile çeken veri katmanı.
* `OnayliyorumSurveyView`: anketi WebView içinde gösterir.
* Anket sayfasıyla köprü: `onCompleted` ve `autoHeight`.
* `Onayliyorum.showSurvey`: anketi pencerede açar, tamamlanınca kendiliğinden kapanır. `Onayliyorum.preload`.
* Anket dışındaki bağlantılar cihazın tarayıcısında açılır.
* Gösterim sayacı panele gönderilir (`trackImpression`).
* `user`: cevabı müşteriye ve işleme bağlar; aynı işlem için ikinci kez anket açılmaz. `transaction` isteğe bağlıdır.
