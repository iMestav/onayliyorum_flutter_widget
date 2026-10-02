import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:onayliyorum_flutter_app_widget/onayliyorum_flutter_app_widget.dart';

void main() {
  testWidgets('pencere açılır, hata gösterir ve kapatılınca dismissed döner', (tester) async {
    final api = OnayliyorumApi(client: MockClient((request) async => http.Response('{}', 404)));
    OnayliyorumSurveyResult? result;

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => result = await Onayliyorum.showSurvey(context, widgetKey: 'wgt_abcDEF1234', api: api),
          child: const Text('aç'),
        ),
      ),
    ));
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    expect(find.text('Widget bulunamadı veya kapatılmış.'), findsOneWidget);

    await tester.tap(find.byTooltip('Kapat'));
    await tester.pumpAndSettle();
    expect(result, OnayliyorumSurveyResult.dismissed);
    expect(find.text('Widget bulunamadı veya kapatılmış.'), findsNothing);
  });
}
