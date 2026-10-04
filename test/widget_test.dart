import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:photo_widget/app/app.dart';

void main() {
  testWidgets('홈 화면이 빈 상태로 뜬다', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PhotoWidgetApp()));

    expect(find.text('사진 위젯'), findsOneWidget);
    expect(find.text('아직 위젯에 걸어둔 사진이 없어요'), findsOneWidget);
  });
}
