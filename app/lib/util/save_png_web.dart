import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Downloads the image through a temporary link.
Future<void> savePng(Uint8List bytes, String fileName, {String? text}) async {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'image/png'),
  );
  final url = web.URL.createObjectURL(blob);
  final link = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  web.document.body?.append(link);
  link.click();
  link.remove();
  // Revoking at once can cancel the download in some browsers.
  Timer(const Duration(seconds: 2), () => web.URL.revokeObjectURL(url));
}

/// The button label to use on this platform.
const savesByDownload = true;
