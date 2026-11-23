import 'dart:io';

import 'package:share_plus/share_plus.dart';

class ShareHelper {
  /// Share plain text (ICS, day details, captions).
  static Future<void> share(String text, {String? subject}) async {
    await SharePlus.instance.share(
      ShareParams(text: text, subject: subject),
    );
  }

  /// Share a generated greeting card image with an optional caption.
  static Future<void> shareImageFile(
    File file, {
    String? text,
    String? subject,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        text: text,
        subject: subject,
      ),
    );
  }
}
