import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// Opens the share sheet with the image, so it can be saved or sent.
Future<void> savePng(Uint8List bytes, String fileName, {String? text}) async {
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(bytes, mimeType: 'image/png')],
      fileNameOverrides: [fileName],
      text: text,
    ),
  );
}

/// The button label to use on this platform.
const savesByDownload = false;
