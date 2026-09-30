import 'package:web/web.dart' as web;

/// The web app's base URL from the page's base element, e.g. https://example.github.io/wearmony/.
Uri? webBaseUri() => Uri.parse(web.document.baseURI);
