// Verificação visual opcional: flutter test tool/capture_previews.dart
// Informe FLUTTER_ROOT com o caminho do SDK. Saída: .validation/*.png.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/screens_test.dart' show openApp, go;

void main() {
  testWidgets('captura telas renderizadas para inspeção visual', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final sdk = Platform.environment['FLUTTER_ROOT'];
      if (sdk == null) {
        throw StateError('Informe FLUTTER_ROOT para carregar as fontes.');
      }
      for (final font in [
        ('Roboto', 'roboto-regular.ttf'),
        ('MaterialIcons', 'materialicons-regular.otf'),
      ]) {
        final bytes = await File(
          '$sdk/bin/cache/artifacts/material_fonts/${font.$2}',
        ).readAsBytes();
        final loader = FontLoader(font.$1)
          ..addFont(Future.value(ByteData.sublistView(bytes)));
        await loader.load();
      }
    });

    Future<void> capture(String name) async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byType(RepaintBoundary).first,
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('.validation').create(recursive: true);
        await File(
          '.validation/$name.png',
        ).writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    }

    var state = await openApp(tester);
    await capture('login-desktop');
    await state.auth.login('estudante@habit.local', 'Habito123!');
    await tester.pumpAndSettle();
    await state.habits.addDemoExamples(isDemo: true);
    await go(tester, '/home');
    await capture('home-desktop');
    await go(tester, '/history');
    await capture('history-desktop');
    await tester.pumpWidget(const SizedBox.shrink());
    state = await openApp(tester, loggedIn: true, size: const Size(360, 800));
    await state.habits.addDemoExamples(isDemo: true);
    await tester.pumpAndSettle();
    await capture('home-mobile');
    await go(tester, '/habits');
    await capture('habits-mobile');
    expect(tester.takeException(), isNull);
  });
}
