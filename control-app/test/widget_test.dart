import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silicon_control/main.dart';

void main() {
  testWidgets('Holding a cup button moves it; release stops it', (
    tester,
  ) async {
    await tester.pumpWidget(const ControlApp());
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('A-cw'))),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await gesture.up();
    await tester.pump();
    final screen = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .toList();
    expect(screen.where((text) => text == '0° / 90°').length, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(
      tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList(),
      screen,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Tablet and narrow windows render without overflow', (
    tester,
  ) async {
    for (final size in [
      const Size(1280, 800),
      const Size(800, 1280),
      const Size(360, 800),
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(const ControlApp());
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
