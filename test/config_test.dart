import 'package:flutter_test/flutter_test.dart';
import 'package:onayliyorum_flutter_app_widget/onayliyorum_flutter_app_widget.dart';

void main() {
  test('API adresi https ile başlar', () {
    expect(Uri.parse(onayliyorumApiBase).scheme, 'https');
  });
}
