import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:onayliyorum_flutter_app_widget/onayliyorum_flutter_app_widget.dart';

const _key = 'wgt_abcDEF1234';

final _user = OnayliyorumUser(
  externalId: 'cust-1',
  name: 'Örnek Müşteri',
  phoneNumber: '905550000000',
  transaction: OnayliyorumTransaction(
    invoiceNo: '97175531',
    transactionDate: DateTime(2026, 8, 29, 18, 2, 5),
    orderChannel: '1',
  ),
);

http.Response _session({required bool answered}) => http.Response(
      jsonEncode({
        'message': 'Success',
        'status': 200,
        'data': {'referanceNumber': 'app_0123456789abcdef', 'alreadyAnswered': answered},
      }),
      200,
    );

void main() {
  test('kullanıcı Partner API alan adlarıyla gönderilir', () async {
    late http.Request sent;
    final api = OnayliyorumApi(client: MockClient((request) async {
      sent = request;
      return _session(answered: false);
    }));

    final session = await api.createSession(_key, _user);

    expect(sent.method, 'POST');
    expect(sent.url.toString(), 'https://api.onayliyorum.app/api/public/widgets/$_key/sessions');
    final user = (jsonDecode(sent.body) as Map)['user'] as Map;
    expect(user['external_id'], 'cust-1');
    expect(user['phone_number'], '905550000000');
    expect(user['transaction']['fatura_no'], '97175531');
    expect(user['transaction']['transaction_date'], '08/29/2026 18:02:05');
    expect(user['transaction']['orderchannel'], '1');
    expect(session.referenceNumber, 'app_0123456789abcdef');
    expect(session.alreadyAnswered, isFalse);
  });

  test('işlem verilmezse transaction alanı gönderilmez', () async {
    late http.Request sent;
    final api = OnayliyorumApi(client: MockClient((request) async {
      sent = request;
      return _session(answered: false);
    }));

    await api.createSession(_key, const OnayliyorumUser(externalId: 'cust-1', name: 'Örnek Müşteri'));

    final user = (jsonDecode(sent.body) as Map)['user'] as Map;
    expect(user['external_id'], 'cust-1');
    expect(user.containsKey('transaction'), isFalse);
  });

  test('geçersiz kullanıcı ve istek sınırı ayrı hata türleridir', () async {
    final invalid = OnayliyorumApi(
      client: MockClient((request) async => http.Response(
            jsonEncode({'message': 'Error', 'status': 422, 'data': 'fatura_no zorunludur.'}),
            422,
            headers: {'content-type': 'application/json; charset=utf-8'},
          )),
    );
    await expectLater(
      invalid.createSession(_key, _user),
      throwsA(isA<OnayliyorumException>()
          .having((error) => error.code, 'code', OnayliyorumErrorCode.invalidUser)
          .having((error) => error.message, 'message', 'fatura_no zorunludur.')),
    );

    final limited = OnayliyorumApi(client: MockClient((request) async => http.Response('{}', 429)));
    await expectLater(
      limited.createSession(_key, _user),
      throwsA(isA<OnayliyorumException>().having((error) => error.code, 'code', OnayliyorumErrorCode.rateLimited)),
    );
  });

  test('transaction verilirse işlem kimliği zorunludur', () {
    expect(() => OnayliyorumTransaction(invoiceNo: '1'), throwsAssertionError);
  });

  testWidgets('daha önce cevaplanmışsa pencere açılmaz', (tester) async {
    final requests = <String>[];
    final api = OnayliyorumApi(client: MockClient((request) async {
      requests.add('${request.method} ${request.url.path}');
      return _session(answered: true);
    }));
    OnayliyorumSurveyResult? result;

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => result = await Onayliyorum.showSurvey(context, widgetKey: _key, user: _user, api: api),
          child: const Text('aç'),
        ),
      ),
    ));
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();

    expect(result, OnayliyorumSurveyResult.alreadyAnswered);
    expect(find.byTooltip('Kapat'), findsNothing);
    expect(requests, ['POST /api/public/widgets/$_key/sessions']);
  });
}
