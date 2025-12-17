import 'package:cocoshibaweb/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_auth_service.dart';

void main() {
  testWidgets('Shows header auth actions', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = FakeAuthService();
    addTearDown(auth.dispose);

    await tester.pumpWidget(CocoshibaWebApp(auth: auth));
    await tester.pumpAndSettle();

    final appBar = find.byType(AppBar);
    expect(
      find.descendant(of: appBar, matching: find.text('ログイン')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: appBar, matching: find.text('アカウント作成')),
      findsOneWidget,
    );

    await auth.signInWithEmailAndPassword(email: 'a@b.com', password: 'pw');
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: appBar, matching: find.text('ログアウト')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: appBar, matching: find.text('アカウント管理')),
      findsOneWidget,
    );
  });
}
