import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:onayliyorum_flutter_app_widget/onayliyorum_flutter_app_widget.dart';
import 'package:onayliyorum_flutter_app_widget/src/survey_view.dart' show isSurveyPage;

void main() {
  test('yalnızca anket sayfasının kendisi WebView içinde kalır', () {
    final embed = Uri.parse('https://onayliyorum.app/survey-question-answer?surveyId=32&widget=wgt_abcDEF1234&embed=1');
    expect(isSurveyPage(embed, embed), isTrue);
    expect(isSurveyPage(Uri.parse('https://onayliyorum.app/survey-question-answer?surveyId=32#x'), embed), isTrue);
    expect(isSurveyPage(Uri.parse('about:blank'), embed), isTrue);
    expect(isSurveyPage(Uri.parse('https://onayliyorum.app/contracts/kvkk'), embed), isFalse);
    expect(isSurveyPage(Uri.parse('https://marka.com/kampanya'), embed), isFalse);
    expect(isSurveyPage(Uri.parse('mailto:a@b.com'), embed), isFalse);
  });

  testWidgets('widget bulunamazsa hata ve tekrar dene gösterilir', (tester) async {
    var calls = 0;
    final errors = <OnayliyorumErrorCode>[];
    final api = OnayliyorumApi(client: MockClient((request) async {
      calls += 1;
      return http.Response('{"message":"Error","status":404,"data":"x"}', 404);
    }));

    await tester.pumpWidget(MaterialApp(
      home: OnayliyorumSurveyView(widgetKey: 'wgt_abcDEF1234', api: api, onError: (error) => errors.add(error.code)),
    ));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('Widget bulunamadı veya kapatılmış.'), findsOneWidget);
    expect(errors, [OnayliyorumErrorCode.notFound]);

    await tester.tap(find.text('Tekrar dene'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(errors.length, 2);
    // Yüklenemeyen widget için gösterim gönderilmez: yalnızca iki GET atılmıştır.
  });
}
