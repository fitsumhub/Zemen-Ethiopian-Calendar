import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

/// Captures a [RepaintBoundary] to a high-resolution PNG for social sharing.
class CardImageExporter {
  CardImageExporter._();

  static Future<File?> capture(
    GlobalKey boundaryKey, {
    double pixelRatio = 4.0,
    String filePrefix = 'zemen_greeting',
  }) async {
    final context = boundaryKey.currentContext;
    if (context == null) return null;
    final boundary = context.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;

    // Wait two frames so gradients/fonts settle before capture.
    await Future<void>.delayed(const Duration(milliseconds: 32));
    await WidgetsBinding.instance.endOfFrame;

    final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;

    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/${filePrefix}_$stamp.png');
    await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
    return file;
  }
}
