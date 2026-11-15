import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_eva_bits/widgets/eve_animated_avatar.dart';

void main() {
  setUpAll(() async {
    final fontFile = File(
      '/opt/homebrew/share/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    if (fontFile.existsSync()) {
      final fontData = fontFile.readAsBytesSync();
      final fontLoader = FontLoader('MaterialIcons');
      fontLoader.addFont(Future.value(ByteData.view(fontData.buffer)));
      await fontLoader.load();
    }
  });

  const emoteConfigs = [
    (EveEmote.calm, 'eve_calm.png', 100),
    (EveEmote.greeting, 'eve_greeting.png', 400),
    (EveEmote.alert, 'eve_alert.png', 200),
    (EveEmote.sad, 'eve_sad.png', 800),
    (EveEmote.surprised, 'eve_surprised.png', 400),
    (EveEmote.happy, 'eve_happy.png', 400),
    (EveEmote.thumbsUp, 'eve_thumbs_up.png', 400),
    (EveEmote.thumbsDown, 'eve_thumbs_down.png', 400),
    (EveEmote.pointing, 'eve_pointing.png', 400),
    (EveEmote.jumping, 'eve_jumping.png', 400),
  ];

  final outDir = Directory('assets/emotes');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  for (final config in emoteConfigs) {
    final emote = config.$1;
    final filename = config.$2;
    final animMs = config.$3;

    testWidgets('Generate emote: $filename', (tester) async {
      final key = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'MaterialIcons'),
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: RepaintBoundary(
                key: key,
                child: Container(
                  width: 512,
                  height: 512,
                  color: Colors.white,
                  alignment: Alignment.center,
                  child: EveAnimatedAvatar(
                    emote: emote,
                    size: 340,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Advance animation to peak frame
      await tester.pump(Duration(milliseconds: animMs));

      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1.0);
        final byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);
        final pngBytes = byteData!.buffer.asUint8List();

        final file = File('${outDir.path}/$filename');
        await file.writeAsBytes(pngBytes);
        print('Saved: ${file.path} (${pngBytes.length} bytes)');
      });
    });
  }
}
