import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:onayliyorum_flutter_app_widget/onayliyorum_flutter_app_widget.dart';

const _key = 'wgt_abcDEF1234';

Map<String, dynamic> _payload({String kind = 'SURVEY', bool withSurvey = true}) => {
      'message': 'Success',
      'status': 200,
      'data': {
        'key': _key,
        'kind': kind,
        'design': 'sideTab',
        'theme': 'light',
        'options': {'position': 'right', 'delaySeconds': 5},
        'firm': {'name': 'Örnek Firma', 'logoUrl': null, 'profileUrl': 'https://onayliyorum.app/business/1'},
        'rating': {'average': 0, 'count': 0},
        'survey': withSurvey
            ? {
                'id': 32,
                'title': 'Müşteri anketi',
                'embedUrl': 'https://onayliyorum.app/survey-question-answer?surveyId=32&widget=$_key&embed=1',
              }
            : null,
      },
    };

http.Response _json(Object body, int status) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

Matcher _throwsCode(OnayliyorumErrorCode code) =>
    throwsA(isA<OnayliyorumException>().having((error) => error.code, 'code', code));

void main() {
  test('anket widget verisini çözer', () async {
    late Uri requested;
    final api = OnayliyorumApi(client: MockClient((request) async {
      requested = request.url;
      return _json(_payload(), 200);
    }));

    final data = await api.fetchSurveyWidget(_key);

    expect(requested.toString(), 'https://api.onayliyorum.app/api/public/widgets/$_key');
    expect(data.key, _key);
    expect(data.isSurvey, isTrue);
    expect(data.firm.name, 'Örnek Firma');
    expect(data.firm.logoUrl, isNull);
    expect(data.survey!.id, 32);
    expect(data.survey!.title, 'Müşteri anketi');
    expect(data.survey!.embedUrl.queryParameters['widget'], _key);
    expect(data.options['position'], 'right');
  });

  test('aynı key için ikinci istek önbellekten döner', () async {
    var calls = 0;
    final api = OnayliyorumApi(client: MockClient((request) async {
      calls += 1;
      return _json(_payload(), 200);
    }));

    await api.fetchWidget(_key);
    await api.fetchWidget(' $_key ');

    expect(calls, 1);
  });

  test('geçersiz biçimli key için istek atılmaz', () async {
    var calls = 0;
    final api = OnayliyorumApi(client: MockClient((request) async {
      calls += 1;
      return _json(_payload(), 200);
    }));

    await expectLater(api.fetchWidget('abc'), _throwsCode(OnayliyorumErrorCode.invalidKey));
    expect(calls, 0);
  });

  test('HTTP durum kodları hata türlerine çevrilir', () async {
    for (final entry in {
      400: OnayliyorumErrorCode.invalidKey,
      403: OnayliyorumErrorCode.notAllowed,
      404: OnayliyorumErrorCode.notFound,
      500: OnayliyorumErrorCode.server,
    }.entries) {
      final api = OnayliyorumApi(
        client: MockClient((request) async => _json({'message': 'Error', 'status': entry.key, 'data': 'x'}, entry.key)),
      );
      await expectLater(api.fetchWidget(_key), _throwsCode(entry.value), reason: 'HTTP ${entry.key}');
    }
  });

  test('bağlantı hatası network olarak döner', () async {
    final api = OnayliyorumApi(client: MockClient((request) async => throw http.ClientException('offline')));
    await expectLater(api.fetchWidget(_key), _throwsCode(OnayliyorumErrorCode.network));
  });

  test('bozuk yanıt server hatası olarak döner', () async {
    final api = OnayliyorumApi(client: MockClient((request) async => http.Response('<html>', 200)));
    await expectLater(api.fetchWidget(_key), _throwsCode(OnayliyorumErrorCode.server));
  });

  test('olaylar web widget ile aynı adrese POST edilir, hatalar yutulur', () async {
    final requests = <String>[];
    final api = OnayliyorumApi(client: MockClient((request) async {
      requests.add('${request.method} ${request.url}');
      if (request.url.path.endsWith('/click')) throw http.ClientException('offline');
      return http.Response('', 204);
    }));

    await api.sendEvent(_key, OnayliyorumEvent.impression);
    await api.sendEvent(_key, OnayliyorumEvent.click);
    await api.sendEvent('bozuk', OnayliyorumEvent.impression);

    expect(requests, [
      'POST https://api.onayliyorum.app/api/public/widgets/$_key/events/impression',
      'POST https://api.onayliyorum.app/api/public/widgets/$_key/events/click',
    ]);
  });

  test('puan widget\'ı anket olarak kabul edilmez', () async {
    final api = OnayliyorumApi(
      client: MockClient((request) async => _json(_payload(kind: 'RATING', withSurvey: false), 200)),
    );
    await expectLater(api.fetchSurveyWidget(_key), _throwsCode(OnayliyorumErrorCode.notSurvey));
  });
}
