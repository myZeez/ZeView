import 'package:flutter_test/flutter_test.dart';

import 'package:noti_view/app.dart';

void main() {
  testWidgets('App boots without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(const NotiViewApp());
    await tester.pump();
  });
}
