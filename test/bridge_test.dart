import 'package:flutter_test/flutter_test.dart';
import 'package:onayliyorum_flutter_app_widget/src/bridge.dart';

void main() {
  test('completed mesajı çözülür', () {
    final message = parseSurveyMessage('{"source":"onayliyorum-survey","type":"completed","widget":"wgt_abcDEF1234"}');
    expect(message?.type, 'completed');
  });

  test('resize mesajı yüksekliği taşır', () {
    final message = parseSurveyMessage('{"source":"onayliyorum-survey","type":"resize","height":812}');
    expect(message?.type, 'resize');
    expect(message?.height, 812);
  });

  test('tanınmayan ya da bozuk mesajlar yok sayılır', () {
    expect(parseSurveyMessage('not json'), isNull);
    expect(parseSurveyMessage('"completed"'), isNull);
    expect(parseSurveyMessage('{"source":"other","type":"completed"}'), isNull);
    expect(parseSurveyMessage('{"source":"onayliyorum-survey","type":"resize","height":"x"}'), isNull);
    expect(parseSurveyMessage('{"source":"onayliyorum-survey","type":"unknown"}'), isNull);
  });
}
